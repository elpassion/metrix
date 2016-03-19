require 'platform-api'
require_relative 'importer'

class ReleasesImporter < Importer

  def import(truncate: false)
    truncate_releases if truncate

    import_releases
  end

  private

  def truncate_releases
    puts '-----> Deleting all project releases'

    project.releases.delete
  end

  def import_releases
    puts "-----> Importing releases from #{project.config.heroku_app_name}"

    releases = heroku_api.release.list(project.config.heroku_app_name)

    imported_release_ids = []
    releases.each { |release| imported_release_ids << import_release(release) }

    puts "       Imported #{imported_release_ids.size} commits"
  end

  def import_release(release)
    project.releases.insert(
        project_id:  project.id,
        timestamp:   DateTime.parse(release['created_at']),
        version:     release['version'],
        description: release['description']
    )
  end

  def heroku_api
    @heroku_api ||= PlatformAPI.connect(project.config.heroku_api_key)
  end
end
