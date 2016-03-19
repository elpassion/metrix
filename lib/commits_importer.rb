require 'rugged'
require_relative 'importer'

class CommitsImporter < Importer
  self.resource_name = 'Commits'

  private

  def import_resources
    repo = Rugged::Repository.new(project.path)
    reset_git_repository(repo)

    walker = Rugged::Walker.new(repo)
    walker.sorting(Rugged::SORT_DATE | Rugged::SORT_REVERSE)
    walker.push(repo.head.target)

    walker.each { |commit| imported_resources << import_commit(commit) }
  end

  def import_commit(commit)
    project.commits.insert(
        project_id: project.id,
        timestamp:  commit.time,
        sha:        commit.oid
    )
  end

  def reset_git_repository(repo)
    repo.reset('origin/HEAD', :hard)
  end

  def truncate_resources
    project.commits.delete
  end
end
