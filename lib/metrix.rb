require 'date'
require 'octokit'
require 'platform-api'
require 'rugged'
require 'travis/pro'
require 'yaml'

# Deploys on Heroku:
# heroku releases --app intern-aggregator-blue --num 1000 --json

# TODO:
# + Heroku deploys
# + TravisCI builds (+ passed / + failed)
# + Git commits count
# + GitHub comments (PR comments + Commit comments + Issue comments)
# + GitHub PR count
# - CodeClimate code quality
# - Code Coverage
# - Bugs found

config              = YAML.load_file('config.yml')
working_dir         = config['working_dir']
heroku_app_name     = config['heroku_app_name']
heroku_api_key      = config['heroku_api_key']
travis_access_token = config['travis_access_token']
github_access_token = config['github_access_token']
github_repository   = config['github_repository']

stats                    = {}

# TravisCI

Travis::Pro.access_token = travis_access_token
travis                   = Travis::Pro::Repository.find(github_repository)
builds                   = travis.builds.to_a

builds.reject { |build| build.state == 'canceled' }.group_by { |build| build.started_at.to_date }.each do |day, builds|
  stats[day]                 ||= {}
  stats[day][:builds_total]  = builds.size
  stats[day][:builds_failed] = builds.count { |build| build.state == 'failed' }
  stats[day][:builds_passed] = builds.count { |build| build.state != 'failed' }
end

# Heroku

heroku          = PlatformAPI.connect(heroku_api_key)
heroku_releases = heroku.release.list(heroku_app_name)
heroku_releases.group_by { |release| DateTime.parse(release['created_at']).to_date }.each do |day, releases|
  stats[day]                  ||= {}
  stats[day][:releases_count] = releases.size
end

# GitHub

Octokit.auto_paginate = true

github          = Octokit::Client.new(access_token: github_access_token)
github_pulls    = github.pull_requests(github_repository, state: 'open')
github_pulls    += github.pull_requests(github_repository, state: 'closed')
github_comments = github.issues_comments(github_repository)
github_comments += github.pulls_comments(github_repository)
github_comments += github.list_commit_comments(github_repository)

github_pulls.group_by { |pull| pull.created_at.to_date }.each do |day, pulls|
  stats[day]               ||= {}
  stats[day][:pulls_count] = pulls.size
end

github_comments.group_by { |comment| comment.created_at.to_date }.each do |day, comments|
  stats[day]                  ||= {}
  stats[day][:comments_count] = comments.size
end

# Git

repo   = Rugged::Repository.new(working_dir)
walker = Rugged::Walker.new(repo)

walker.sorting(Rugged::SORT_DATE | Rugged::SORT_REVERSE)
walker.push(repo.head.target)

daily_commits = walker.group_by { |commit| commit.time.to_date }
daily_commits.each do |day, commits|
  last_commit = commits.last

  stats[day]                 ||= {}
  stats[day][:commits_count] = commits.size
end

puts stats
