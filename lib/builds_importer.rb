require 'bigdecimal'
require 'travis/pro'

require_relative 'importer'

class BuildsImporter < Importer
  self.resource_name = 'Builds'

  COVERAGE_PATTERN = /Coverage\ \=\ (\d+\.\d+)\%/

  private

  def truncate_resources
    project.builds.delete
  end

  def import_resources
    travis_api.builds.each { |build| imported_resources << import_build(build) }
  end

  def import_build(build)
    log "Parsing Build ##{build[:number]}"

    coverage = nil

    build.jobs.first.log.body do |part|
      if part.include?('Coverage = ')
        coverage = BigDecimal(part.match(COVERAGE_PATTERN)[1])
      end
    end

    project.builds.insert(
        project_id:   project.id,
        timestamp:    build.started_at,
        number:       build.number,
        commit_sha:   build.commit.sha,
        pull_request: build.pull_request,
        state:        build.state,
        coverage:     coverage
    )
  end

  def travis_api
    Travis::Pro.access_token = project.config.travis_access_token

    Travis::Pro::Repository.find(project.config.github_repository)
  end
end