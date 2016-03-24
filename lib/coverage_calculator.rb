require 'fileutils'
require 'yaml'

class CoverageCalculator
  attr_reader :working_dir

  def initialize(working_dir)
    @working_dir = working_dir
    @running_dir = FileUtils.pwd
  end

  def calculate
    FileUtils.chdir(working_dir)

    db_name     = "metrix_ci_test_#{rand(10000)}"
    db_settings = {
        'test' => {
            'adapter'  => 'postgresql',
            'database' => db_name
        }
    }

    File.open(File.join(working_dir, 'config', 'database.yml'), 'w') do |file|
      file.puts YAML::dump(db_settings)
    end

    stdout, stderr, status = Open3.capture3('rbenv', 'local', '2.2.3')
    stdout, stderr, status = Open3.capture3('bundle', 'install', '--jobs=3', '--retry=3')
    stdout, stderr, status = Open3.capture3('bundle', 'exec', 'bin/rake', 'db:create')
    stdout, stderr, status = Open3.capture3('bundle', 'exec', 'bin/rake')

    raise stderr if (status && status.exitstatus != 0) || stderr =~ /\S/
  ensure
    FileUtils.chdir(running_dir)
  end

  private

  attr_reader :running_dir

end