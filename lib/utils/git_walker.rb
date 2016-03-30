require 'fileutils'
require 'open3'
require 'parallel'
require 'rugged'
require 'tmpdir'

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

  def map(shas)
    shas.map do |sha|
      goto(sha)

      yield sha
    end
  end

  def each_in_parallel(shas, processes: 4, chunks_count: nil)
    tmp_directory = create_tmp_directory('parallel-repositories-')

    begin
      chunks_count ||= processes * 4
      chunks       = shas.each_slice((shas.size / chunks_count.to_f).ceil).to_a

      Parallel.map_with_index(chunks, in_processes: processes) do |chunk, index|
        duplicate_path = duplicate_repository(tmp_directory)

        GitWalker.new(duplicate_path).map(chunk) do |sha|
          yield duplicate_path, sha, index
        end
      end
    ensure
      FileUtils.remove_entry(tmp_directory)
    end
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

  def duplicate_repository(tmp_directory)
    dir = create_tmp_directory('repository-', tmp_directory)

    FileUtils.cp_r(File.join(path, '.'), dir)

    dir
  end

  def create_tmp_directory(prefix, tmp = nil)
    tmp ||= FileUtils.mkpath(File.join(FileUtils.pwd, 'tmp'))

    Dir::Tmpname.create(prefix, tmp) do |name|
      Dir.mkdir(name)
    end
  end

end