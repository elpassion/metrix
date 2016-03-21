require_relative 'github_importer'

class CommentsImporter < GithubImporter
  self.resource_type = :comments

  private

  def import_resources
    github_comments = github_api.issues_comments(project.config.github_repository) +
        github_api.pulls_comments(project.config.github_repository) +
        github_api.list_commit_comments(project.config.github_repository)

    github_comments.each do |comment|
      imported_resources << import_comment(comment)
    end
  end

  def import_comment(comment)
    project.comments.insert(
        project_id: project.id,
        timestamp:  comment.created_at
    )
  end
end
