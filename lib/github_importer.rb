require 'octokit'
require_relative 'importer'

class GithubImporter < Importer

  private

  def github_api
    Octokit.auto_paginate = true

    Octokit::Client.new(access_token: project.config.github_access_token)
  end

end