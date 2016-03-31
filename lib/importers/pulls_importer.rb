require_relative 'github_importer'

class PullsImporter < GithubImporter
  self.resource_type = :pull_requests

  private

  def import_resources
    pull_requests = github_api.pull_requests(project.config.github_repository, state: 'all')

    pull_requests.each do |pull_request|
      imported_resources << import_pull_request(pull_request)
    end
  end

  def import_pull_request(pull_request)
    project.pull_requests.insert(
      project_id:      project.id,
      type:            'pull_request',
      timestamp:       pull_request.created_at,
      # closed_at:  pull_request.closed_at,
      timestamp_key:   'merged_at',
      timestamp_value: pull_request.merged_at,
      boolean_key:     'is_conflict',
      boolean_value:   pull_request.title =~ CommitsImporter::CONFLICT_PATTERN || pull_request.body =~ CommitsImporter::CONFLICT_PATTERN
    )
  end
end