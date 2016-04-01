require 'bigdecimal'
require 'parallel'
require 'travis/pro'

require_relative 'importer'
require_relative '../utils/test_log_parser'

class BuildsImporter < Importer
  self.resource_type = :builds

  private

  def import_resources
    log 'Fetching builds list'
    builds = travis_api.builds.to_a

    builds_coverage = fetch_builds_coverage(builds)

    log 'Importing builds'
    builds.each { |build| imported_resources << import_build(build, builds_coverage) }
  end

  def import_build(build, builds_stats)
    project.builds.insert(
      project_id:    project.id,
      timestamp:     build.started_at,
      number:        build.number,
      commit_sha:    build.commit.sha,
      pull_request:  build.pull_request,
      state:         build.state,
      coverage:      builds_stats[build][0],
      lines_of_code: builds_stats[build][1],
      lines_tested:  builds_stats[build][2]
    )
  end

  def fetch_builds_coverage(builds)
    builds_coverage = {}

    Parallel.each(builds, in_threads: 8, progress: { title: 'Fetching Builds Logs', format: '       %t |%E | %B | %a' }) do |build|
      builds_coverage[build] = parse_stats(build)
    end

    builds_coverage
  end

  def parse_stats(build)
    log "Parsing Build ##{build[:number]}"

    build.jobs.first.log.body do |part|
      return [] unless part

      return test_log_parser.parse(part)
    end

    []
  end

  def travis_api
    Travis::Pro.access_token = project.config.travis_access_token

    Travis::Pro::Repository.find(project.config.github_repository)
  end

  def test_log_parser
    @test_log_parser ||= TestLogParser.new
  end
end