require 'fileutils'

require_relative '../analyzers/quality_analyzer'
require_relative '../utils/git_walker'
require_relative 'code_quality_calculator'
require_relative 'importer'

class IssuesImporter < Importer
  self.resource_type = :issues

  def initialize(*)
    super

    @current_path = FileUtils.pwd
  end

  private

  attr_reader :current_path

  def truncate_resources
    super

    project.builds.update(quality_issues: nil, style_issues: nil, security_issues: nil, gpa: nil)
  end

  def import_resources
    shas   = builds_scope(truncate).order(:number).select_map(:commit_sha)
    walker = GitWalker.new(project.path)
    shas.select! { |sha| walker.exists?(sha) }

    walker.each_in_parallel(shas, processes: 3) do |path, sha, chunk_index|
      log "Analyzing Commit #{sha} (chunk ##{chunk_index + 1})"

      project.reset_db_connection!

      raw_issues = analyze_repository(path, sha)
      build      = project.builds.first(commit_sha: sha)

      truncate_build_issues(build)
      import_raw_issues(build, raw_issues)
      calculate_code_quality(build)
    end
  end

  def analyze_repository(path, sha)
    FileUtils.cp_r(File.join(current_path, 'codeclimate/.'), path)

    QualityAnalyzer.new(path).analyze
  rescue => error
    log_warning "Cannot analyze Commit #{sha}:\n#{error.message}"

    []
  end

  def calculate_code_quality(build)
    log 'Calculating code quality'

    code_quality = CodeQualityCalculator.new(project, build).calculate
    project.builds.where(id: build[:id]).update(code_quality)
  end

  def truncate_build_issues(build)
    project.issues.where(build_id: build[:id]).delete
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