require_relative 'builds_importer'
require_relative 'comments_importer'
require_relative 'commits_importer'
require_relative 'issues_importer'
require_relative 'project'
require_relative 'pulls_importer'
require_relative 'releases_importer'

project = Project.new('config.yml')

# CommitsImporter.new(project).import(truncate: true)
# ReleasesImporter.new(project).import(truncate: true)
# PullsImporter.new(project).import(truncate: true)
# CommentsImporter.new(project).import(truncate: true)
# BuildsImporter.new(project).import(truncate: true)
IssuesImporter.new(project).import(truncate: true)
