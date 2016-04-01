require 'fileutils'
require 'timeout'

require_relative '../analyzers/coverage_analyzer'
require_relative '../utils/git_walker'
require_relative 'importer'

class CoverageImporter < Importer
  self.resource_type = :builds

  TIMEOUT = 60 * 5 # Seconds

  private

  def truncate_resources
    resources_scope.update(coverage2: nil, lines_of_code: nil, lines_tested: nil)
  end

  def import_resources
    shas   = builds_scope(truncate).order(:number).select_map(:commit_sha)
    walker = GitWalker.new(project.path)
    shas.select! { |sha| walker.exists?(sha) }

    walker.each_in_parallel(shas, processes: 3) do |path, sha, chunk_index|
      log "Analyzing Commit #{sha} (chunk ##{chunk_index + 1})"

      raw_coverage = analyze_repository(path, sha)

      project.reset_db_connection!
      project.builds.where(commit_sha: sha).update(
        coverage2:     raw_coverage[0],
        lines_of_code: raw_coverage[1],
        lines_tested:  raw_coverage[2]
      )
    end
  end

  def analyze_repository(path, sha)
    Timeout::timeout(TIMEOUT) { CoverageAnalyzer.new(path).analyze }
  rescue => error
    log_warning "Cannot analyze Commit #{sha}:\n#{error.message}"

    []
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