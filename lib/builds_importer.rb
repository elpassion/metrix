require 'travis/pro'
require_relative 'importer'

class BuildsImporter < Importer
  COVERAGE_PATTERN = /Coverage\ \=\ (\d+\.\d+)\%/

  def import(truncate: false)
    truncate_builds if truncate

    import_builds
  end

  private

  def truncate_builds
    puts '-----> Deleting all project builds'

    project.builds.delete
  end

  def import_builds
    puts "-----> Importing builds from #{project.config.github_repository}"

    imported_build_ids = []
    travis_api.builds.each { |build| imported_build_ids << import_build(build) }

    puts "       Imported #{imported_build_ids.size} builds"
  end

  def import_build(build)
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