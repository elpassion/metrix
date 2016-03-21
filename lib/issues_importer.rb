require 'fileutils'
require 'json'
require 'open3'
require 'parallel'
require 'rugged'
require 'tmpdir'

require_relative 'importer'
require_relative 'issues_analyzer'
require_relative 'code_quality_calculator'
require_relative 'utils/git_walker'

class IssuesImporter < Importer
  self.resource_type = :issues

  def initialize(*)
    super

    @current_path = FileUtils.pwd
    @git_walker   = GitWalker.new(project.path)
  end

  private

  attr_reader :current_path, :git_walker

  def import_resources
    builds       = builds_scope(truncate)
    builds_count = builds.count
    index        = 0

    builds.order(:number).each do |build|
      log "Analyzing Build ##{build[:number]} (#{index += 1} / #{builds_count})", level: 1

      analyze_build(build)
    end
  end

  def analyze_build(build)
    truncate_build_issues(build)

    unless git_walker.exists?(build[:commit_sha])
      log_warning "Commit does not exist: #{build[:commit_sha]}"

      skipped_resources << build[:id]

      return
    end

    git_walker.goto(build[:commit_sha]) do
      FileUtils.cp_r(File.join(current_path, 'codeclimate/.'), project.path)
    end

    raw_issues = begin
      analyze_issues
    rescue => error
      log_warning "Cannot analyze Build ##{build[:number]}: "
      log_warning error.message

      skipped_resources << build[:id]

      return
    end

    import_raw_issues(build, raw_issues)
    calculate_code_quality(build)

    imported_resources << build[:id]
  end

  def calculate_code_quality(build)
    log 'Calculating code quality'

    code_quality = CodeQualityCalculator.new(project, build).calculate
    project.builds.where(id: build[:id]).update(code_quality)
  end

  def truncate_build_issues(build)
    project.issues.where(build_id: build[:id]).delete
  end

  def analyze_issues
    log 'Running CodeClimate'

    IssuesAnalyzer.new(project.path).analyze
  end

  def import_raw_issues(build, raw_issues)
    imported_issues = []
    project.transaction do
      raw_issues.each do |issue|
        imported_issues << project.issues.insert(
            project_id:       project.id,
            build_id:         build[:id],
            timestamp:        build[:timestamp],
            category:         issue['categories'].join(', '),
            path:             issue['location']['path'],
            remediation_cost: issue['remediation_points'],
            engine_name:      issue['engine_name']
        )
      end
    end

    log_success "Imported #{imported_issues.size} issues"
  end

  def builds_scope(truncate)
    if truncate
      project.builds
    else
      already = project.issues.distinct.select(:build_id).to_a.map(&:values).flatten

      project.builds.exclude(id: already)
    end
  end

end