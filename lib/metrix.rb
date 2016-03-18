require 'bigdecimal'
require 'date'
require 'octokit'
require 'platform-api'
require 'rugged'
require 'securerandom'
require 'sqlite3'
require 'sequel'
require 'travis/pro'
require 'yaml'

# Deploys on Heroku:
# heroku releases --app intern-aggregator-blue --num 1000 --json

# TODO:
# + Heroku deploys
# + TravisCI builds (+ passed / + failed)
# + Git commits count
# + GitHub comments (PR comments + Commit comments + Issue comments)
# + GitHub PR count (created + merged)
# - CodeClimate code quality
# - Code Coverage
# - Bugs found


COVERAGE_PATTERN = /Coverage\ \=\ (\d+\.\d+)\%/

config              = YAML.load_file('config.yml')
project_name        = config['project_name']
working_dir         = config['working_dir']
heroku_app_name     = config['heroku_app_name']
heroku_api_key      = config['heroku_api_key']
travis_access_token = config['travis_access_token']
github_access_token = config['github_access_token']
github_repository   = config['github_repository']
db_file             = config['cache_db']

db = Sequel.connect("sqlite://#{db_file}")

project = db[:projects].where(name: project_name).first || db[:projects].insert(name: project_name)

p project

stats             = {}
milestone_commits = []

# Git ##########################################################################

repo              = Rugged::Repository.new(working_dir)
walker            = Rugged::Walker.new(repo)

walker.sorting(Rugged::SORT_DATE | Rugged::SORT_REVERSE)
walker.push(repo.head.target)

db[:commits].delete
walker.each do |commit|
  db[:commits].insert(project_id: project[:id], timestamp: commit.time, sha: commit.oid)
end

# walker_commits = walker.group_by { |commit| commit.time.to_date }
# walker_commits.each do |day, commits|
#   stats[day]                 ||= {}
#   stats[day][:commits_count] = commits.size
#
#   last_commit = commits.last
#   milestone_commits << [last_commit.time.to_date, last_commit.oid]
# end
#
# milestone_commits.sort_by! { |commit| commit.first }
# milestone_commits.each do |commit|
#   puts "#{commit.first.iso8601} :: #{commit.last}"
# end
#
# branch = repo.branches.create(branch_id, milestone_commits.first.last)
# repo.checkout(branch)
# # branch.upstream = "origin/#{branch_id}"
# # repo.push 'origin'
#
# puts "Please setup branch '#{branch.name}' as a default branch in GitHub"
#
# gets
#
# puts "Please setup branch 'master' as a default branch in GitHub"
#
# repo.checkout('master')
# repo.branches.delete(branch)
#
# return 0

# TravisCI #####################################################################

Travis::Pro.access_token = travis_access_token
travis                   = Travis::Pro::Repository.find(github_repository)
#builds                   = travis.builds.to_a

db[:builds].delete
travis.builds.each do |build|
  coverage = nil

  build.jobs.first.log.body do |part|
    if part.include?('Coverage = ')
      coverage = BigDecimal(part.match(COVERAGE_PATTERN)[1])
    end
  end

  db[:builds].insert(project_id: project[:id], timestamp: build.started_at, number: build.number, pull_request: build.pull_request, state: build.state, coverage: coverage)
end

return false

builds.reject { |build| build.state == 'canceled' }.group_by { |build| build.started_at.to_date }.each do |day, builds|
  builds.each do |build|
    build.jobs.first.log.body do |part|
      if part.include?('Coverage = ')
        coverage = BigDecimal(part.match(COVERAGE_PATTERN)[1])
      end
    end
  end

  stats[day]                 ||= {}
  stats[day][:builds_total]  = builds.size
  stats[day][:builds_passed] = builds.count { |build| build.state == 'passed' }
  stats[day][:builds_failed] = builds.count { |build| build.state != 'passed' }
end

return false

# Heroku #######################################################################

heroku          = PlatformAPI.connect(heroku_api_key)
heroku_releases = heroku.release.list(heroku_app_name)
heroku_releases.group_by { |release| DateTime.parse(release['created_at']).to_date }.each do |day, releases|
  stats[day]                  ||= {}
  stats[day][:releases_count] = releases.size
end

# GitHub #######################################################################

Octokit.auto_paginate = true

github          = Octokit::Client.new(access_token: github_access_token)
github_pulls    = github.pull_requests(github_repository, state: 'all')
github_comments = github.issues_comments(github_repository) +
    github.pulls_comments(github_repository) +
    github.list_commit_comments(github_repository)

github_pulls.group_by { |pull| pull.created_at.to_date }.each do |day, pulls|
  stats[day]                 ||= {}
  stats[day][:pulls_created] = pulls.size
end

github_pulls.group_by { |pull| pull.merged_at.to_date }.each do |day, pulls|
  stats[day]                ||= {}
  stats[day][:pulls_merged] = pulls.size
end

github_comments.group_by { |comment| comment.created_at.to_date }.each do |day, comments|
  stats[day]                  ||= {}
  stats[day][:comments_count] = comments.size
end

# Code Coverage ################################################################


# CodeClimate ##################################################################


puts stats
