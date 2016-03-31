# require_relative 'builds_importer'
require_relative 'importers/comments_importer'
require_relative 'importers/commits_importer'
# require_relative 'importers/coverage_importer'
require_relative 'importers/pulls_importer'
require_relative 'importers/releases_importer'
# require_relative 'issues_importer'
require_relative 'project'

project = Project.new('config.yml')

CommitsImporter.new(project).import(truncate: true)
ReleasesImporter.new(project).import(truncate: true)
PullsImporter.new(project).import(truncate: true)
CommentsImporter.new(project).import(truncate: true)
# BuildsImporter.new(project).import(truncate: true)
# IssuesImporter.new(project).import(truncate: true)
# CoverageImporter.new(project).import(truncate: true)
