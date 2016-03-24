require 'fileutils'

require_relative 'importer'
require_relative 'issues_analyzer'
require_relative 'code_quality_calculator'
require_relative 'utils/git_walker'

class IssuesImporter < Importer
  self.resource_type = :issues

  def initialize(*)
    super

    @current_path = FileUtils.pwd
  end

  private

  attr_reader :current_path

  def import_resources
    shas   = builds_scope(truncate).order(:number).limit(1).select_map(:commit_sha)
    walker = GitWalker.new(project.path)
    shas.select! { |sha| walker.exists?(sha) }

    issues = walker.map_in_parallel(shas) do |path, sha, chunk_index|
      log "Analyzing Commit #{sha} (chunk ##{chunk_index + 1})"

      [sha, analyze_repository(path, sha)]
    end

    issues.each do |sha, raw_issues|
      build = project.builds.first(commit_sha: sha)

      truncate_build_issues(build)
      import_raw_issues(build, raw_issues)
      calculate_code_quality(build)
    end
  end

  def analyze_repository(path, sha)
    FileUtils.cp_r(File.join(current_path, 'codeclimate/.'), path)

    IssuesAnalyzer.new(path).analyze
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