require 'fileutils'
require 'yaml'

require_relative 'test_log_parser'

class CoverageCalculator
  attr_reader :working_dir

  def initialize(working_dir)
    @working_dir = working_dir
    @running_dir = FileUtils.pwd
  end

  def calculate
    FileUtils.chdir(working_dir)

    db_name     = "metrix_ci_test_#{rand(1000000)}_#{rand(1000000)}}"
    db_settings = {
      'test' => {
        'adapter'  => 'postgresql',
        'database' => db_name
      }
    }

    File.open(File.join(working_dir, 'config', 'database.yml'), 'w') do |file|
      file.puts YAML::dump(db_settings)
    end

    File.open('Gemfile', 'a') do |file|
      file.puts "\ngem 'simplecov', :require => false, :group => :test"
    end

    rd = IO.read 'spec/spec_helper.rb'
    rd = rd.gsub(/require\s+(\'|\")codeclimate\-test\-reporter(\'||\")/, '').gsub(/CodeClimate\:\:TestReporter\.start/, '')
    rd = "require 'simplecov'\nSimpleCov.start 'rails'\n#{rd}"
    IO.write 'spec/spec_helper.rb', rd

    stdout, stderr, status = Open3.capture3('rbenv', 'local', '2.2.3')
    stdout, stderr, status = Open3.capture3('bundle', 'install', '--jobs=3', '--retry=3')
    stdout, stderr, status = Open3.capture3('bundle', 'exec', 'bin/rake', 'db:create', 'db:setup', 'RAILS_ENV=test')
    stdout, stderr, status = Open3.capture3('bundle', 'exec', 'bin/rake')

    return TestLogParser.new.parse(stdout) if stdout && stdout =~ /\S/

    raise stderr
  ensure
    FileUtils.chdir(running_dir)
  end

  private

  attr_reader :running_dir

end