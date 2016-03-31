require 'date'
require 'platform-api'

require_relative '../importer'

class ReleasesImporter < Importer
  self.resource_type = :releases

  private

  def import_resources
    releases = heroku_api.release.list(project.config.heroku_app_name)
    releases.each { |release| imported_resources << import_release(release) }
  end

  def import_release(release)
    project.releases.insert(
      project_id:    project.id,
      type:          'release',
      timestamp:     DateTime.parse(release['created_at']),
      integer_key:   'version',
      integer_value: release['version'],
      string_key:    'description',
      string_value:  release['description']
    )
  end

  def heroku_api
    @heroku_api ||= PlatformAPI.connect(project.config.heroku_api_key)
  end
end
