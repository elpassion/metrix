require 'bigdecimal'
require 'parallel'
require 'travis/pro'

require_relative 'importer'

class BuildsImporter < Importer
  self.resource_type = :builds

  COVERAGE_PATTERN_1 = /Coverage\ \=\ (\d+\.\d+)\%/
  COVERAGE_PATTERN_2 = /\((\d+\.\d+)\%\) covered/

  private

  def import_resources
    log 'Fetching builds list'
    builds = travis_api.builds.to_a

    builds_coverage = fetch_builds_coverage(builds)

    log 'Importing builds'
    builds.each { |build| imported_resources << import_build(build, builds_coverage) }
  end

  def import_build(build, builds_coverage)
    project.builds.insert(
        project_id:   project.id,
        timestamp:    build.started_at,
        number:       build.number,
        commit_sha:   build.commit.sha,
        pull_request: build.pull_request,
        state:        build.state,
        coverage:     builds_coverage[build]
    )
  end

  def fetch_builds_coverage(builds)
    builds_coverage = {}

    Parallel.each(builds, in_threads: 8, progress: { title: 'Fetching Builds Logs', format: '       %t |%E | %B | %a' }) do |build|
      builds_coverage[build] = parse_coverage(build)
    end

    builds_coverage
  end

  def parse_coverage(build)
    log "Parsing Build ##{build[:number]}"

    build.jobs.first.log.body do |part|
      return unless part

      if part.include?('Coverage = ')
        return BigDecimal(part.match(COVERAGE_PATTERN_1)[1])
      elsif part.include?('Coverage report generated')
        return BigDecimal(part.match(COVERAGE_PATTERN_2)[1])
      end
    end

    nil
  end

  def travis_api
    Travis::Pro.access_token = project.config.travis_access_token

    Travis::Pro::Repository.find(project.config.github_repository)
  end
end