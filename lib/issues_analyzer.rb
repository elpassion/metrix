require 'fileutils'
require 'json'

class IssuesAnalyzer
  attr_reader :working_dir

  def initialize(working_dir)
    @working_dir = working_dir
    @running_dir = FileUtils.pwd
  end

  def analyze
    FileUtils.chdir(working_dir)

    stdout, stderr, status = Open3.capture3('codeclimate', 'analyze', '-f', 'json')

    raise stderr if (status && status.exitstatus != 0) || stderr =~ /\S/

    JSON.parse(stdout)
  ensure
    FileUtils.chdir(running_dir)
  end

  private

  attr_reader :running_dir

end