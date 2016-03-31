require 'ostruct'
require 'sqlite3'
require 'sequel'
require 'yaml'

class Project
  attr_reader :id, :name, :path, :config

  def initialize(config_file)
    raise ArgumentError, 'Config file not specified' unless config_file
    raise ArgumentError, 'Config file does not exist' unless File.exist?(config_file)

    load_config(config_file)
    initialize_db_project
  end

  def builds
    db[:builds].where(project_id: id)
  end

  def issues
    db[:issues].where(project_id: id)
  end

  def commits
    db[:activities].where(project_id: id, type: 'commit')
  end

  def releases
    db[:activities].where(project_id: id, type: 'release')
  end

  def pull_requests
    db[:activities].where(project_id: id, type: 'pull_request')
  end

  def comments
    db[:activities].where(project_id: id, type: 'comment')
  end

  def transaction(&block)
    db.transaction(&block)
  end

  def reset_db_connection!
    @db = nil
  end

  private

  attr_reader :db_path

  def load_config(config_file)
    config = YAML.load_file(config_file)

    @name    = config.delete('name') { raise 'Project name not configured' }
    @path    = config.delete('path') { raise 'Project path not configured' }
    @db_path = config.delete('db') { raise 'Project db not configured' }

    @config = OpenStruct.new(config).freeze
  end

  def db
    @db ||= Sequel.connect("sqlite://#{db_path}")
  end

  def initialize_db_project
    projects = db[:projects]

    @id = if projects.where(name: name).empty?
            projects.insert(name: name)
          else
            projects.where(name: name).get(:id)
          end
  end

end