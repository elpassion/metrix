require 'fileutils'

require_relative '../coverage_calculator'
require_relative '../importer'
require_relative '../utils/git_walker'

class CoverageImporter < Importer
  self.resource_type = :builds

  def initialize(*)
    super

    @current_path = FileUtils.pwd
  end

  private

  attr_reader :current_path

  def truncate_resources
    resources_scope.update(coverage: nil)
  end

  def import_resources
    shas   = builds_scope(truncate).order(:number).limit(3).select_map(:commit_sha)
    walker = GitWalker.new(project.path)
    shas.select! { |sha| walker.exists?(sha) }

    coverages = walker.map_in_parallel(shas) do |path, sha, chunk_index|
      log "Analyzing Commit #{sha} (chunk ##{chunk_index + 1})"

      [sha, analyze_repository(path, sha)]
    end
  end

  def analyze_repository(path, sha)
    FileUtils.cp_r(File.join(current_path, 'codeclimate/.'), path)

    CoverageCalculator.new(path).calculate
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