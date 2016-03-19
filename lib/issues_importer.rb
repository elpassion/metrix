require 'fileutils'
require 'json'
require 'open3'
require 'rugged'

require_relative 'importer'
require_relative 'code_quality_calculator'

class IssuesImporter < Importer
  self.resource_name = 'Issues'

  def initialize(*)
    super

    @current_path = FileUtils.pwd
    @repo         = Rugged::Repository.new(project.path)
  end

  private

  attr_reader :current_path, :repo

  def import_resources
    builds       = builds_scope(truncate)
    builds_count = builds.count
    index        = 0

    builds.order(:number).each do |build|
      log "Analyzing Build ##{build[:number]} (#{index += 1} / #{builds_count})", level: 1

      analyze_build(build)
    end

    reset_git_repository
  end

  def analyze_build(build)
    truncate_build_issues(build)

    unless repo.exists?(build[:commit_sha])
      log_warning "Commit does not exist: #{build[:commit_sha]}"

      skipped_resources << build[:id]

      return
    end

    goto_build(build)

    unless raw_issues = analyze_issues
      log_warning "Cannot analyze Build ##{build[:id]}"

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

  def goto_build(build)
    FileUtils.chdir(project.path)

    log "Rolling back to #{build[:commit_sha]}"
    repo.reset(build[:commit_sha], :hard)
    `git clean -f`

    FileUtils.cp_r(File.join(current_path, 'codeclimate/.'), project.path)
  end

  def truncate_resources
    project.issues.delete
  end

  def truncate_build_issues(build)
    project.issues.where(build_id: build[:id]).delete
  end

  def analyze_issues
    log 'Running CodeClimate'

    FileUtils.chdir(project.path)
    stdout, stderr, status = Open3.capture3('codeclimate analyze -f json')

    if (status && status.exitstatus != 0) || stderr =~ /\S/
      log_warning stderr

      return
    end

    JSON.parse(stdout)
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

  def reset_git_repository
    FileUtils.chdir(project.path)
    repo.reset('origin/HEAD', :hard)
    `git clean -f`
  end

end