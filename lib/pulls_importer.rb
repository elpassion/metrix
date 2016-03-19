require_relative 'github_importer'

class PullsImporter < GithubImporter

  def import(truncate: false)
    truncate_pull_requests if truncate

    import_pull_requests
  end

  private

  def truncate_pull_requests
    puts '-----> Deleting all project pull requests'

    project.pull_requests.delete
  end

  def import_pull_requests
    puts "-----> Importing pull requests from #{project.config.github_repository}"

    imported_pull_ids = []
    github_api.pull_requests(project.config.github_repository, state: 'all').each do |pull_request|
      imported_pull_ids << import_pull_request(pull_request)
    end

    puts "       Imported #{imported_pull_ids.size} pull requests"
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