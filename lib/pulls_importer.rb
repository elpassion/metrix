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
        project_id: project.id,
        timestamp:  pull_request.created_at,
        closed_at:  pull_request.closed_at,
        merged_at:  pull_request.merged_at
    )
  end
end