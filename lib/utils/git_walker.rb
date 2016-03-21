require 'fileutils'
require 'open3'
require 'rugged'

class GitWalker
  attr_reader :path

  def initialize(path)
    raise ArgumentError, "#{path} does not exist" unless File.exist?(path)
    raise ArgumentError, "#{path} is not directory" unless File.directory?(path)

    @path = path
    @repo = Rugged::Repository.new(path)
  end

  def exists?(sha)
    repo.exists?(sha)
  end

  def goto(sha)
    raise "Commit #{sha} does not exist" unless exists?(sha)

    repo.reset(sha, :hard)
    clean_repository

    yield if block_given?
  end

  private

  attr_reader :repo

  def clean_repository
    _, stderr, status = Open3.capture3('git', "--git-dir=#{repo.path}", "--work-tree=#{path}", 'clean', '--force')

    if (status && status.exitstatus != 0) || stderr =~ /\S/
      raise "Could not clean repository: #{stderr || status}"
    end
  end

end