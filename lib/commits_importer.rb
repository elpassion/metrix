require 'rugged'
require_relative 'importer'

class CommitsImporter < Importer

  def initialize(*)
    super

    @repo    = Rugged::Repository.new(project.path)
  end

  def import(truncate: false)
    truncate_commits if truncate

    reset_git_repository
    import_commits
  end

  private

  attr_reader :repo

  def reset_git_repository
    repo.reset('origin/HEAD', :hard)
  end

  def truncate_commits
    puts '-----> Deleting all project commits'

    project.commits.delete
  end

  def import_commits
    puts "-----> Importing commits from #{repo.workdir}"

    walker = Rugged::Walker.new(repo)
    walker.sorting(Rugged::SORT_DATE | Rugged::SORT_REVERSE)
    walker.push(repo.head.target)

    imported_commit_ids = []
    walker.each { |commit| imported_commit_ids << import_commit(commit) }

    puts "       Imported #{imported_commit_ids.size} commits"
  end

  def import_commit(commit)
    project.commits.insert(
        project_id: project.id,
        timestamp:  commit.time,
        sha:        commit.oid
    )
  end
end
