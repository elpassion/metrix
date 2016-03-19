require_relative 'github_importer'

class CommentsImporter < GithubImporter

  def import(truncate: false)
    truncate_comments if truncate

    import_comments
  end

  private

  def truncate_comments
    puts '-----> Deleting all project comments'

    project.comments.delete
  end

  def import_comments
    puts "-----> Importing comments from #{project.config.github_repository}"

    github_comments = github_api.issues_comments(project.config.github_repository) +
        github_api.pulls_comments(project.config.github_repository) +
        github_api.list_commit_comments(project.config.github_repository)

    imported_comment_ids = []
    github_comments.each do |comment|
      imported_comment_ids << import_comment(comment)
    end

    puts "       Imported #{imported_comment_ids.size} comments"
  end

  def import_comment(comment)
    project.comments.insert(
        project_id: project.id,
        timestamp:  comment.created_at
    )
  end
end
