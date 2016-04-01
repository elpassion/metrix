require 'rugged'

require_relative 'importer'

class CommitsImporter < Importer
  self.resource_type = :commits

  CONFLICT_PATTERN = /(c|k)onfli(c|k)t/i

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
      project_id:    project.id,
      type:          'commit',
      timestamp:     commit.time,
      string_key:    'sha',
      string_value:  commit.oid,
      boolean_key:   'is_conflict',
      boolean_value: commit.message =~ CONFLICT_PATTERN
    )
  end

  def reset_git_repository(repo)
    repo.reset('origin/HEAD', :hard)
  end
end
