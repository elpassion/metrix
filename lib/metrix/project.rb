require 'ostruct'
require 'yaml'

module Metrix
  class Project
    attr_reader :id, :name, :path, :config

    def initialize(config_file)
      raise ArgumentError, 'Config file not specified' unless config_file
      raise ArgumentError, 'Config file does not exist' unless File.exist?(config_file)

      load_config(config_file)
      initialize_db_project
    end

    def builds
      store[:builds].where(project_id: id)
    end

    def issues
      store[:issues].where(project_id: id)
    end

    def commits
      store[:activities].where(project_id: id, type: 'commit')
    end

    def releases
      store[:activities].where(project_id: id, type: 'release')
    end

    def pull_requests
      store[:activities].where(project_id: id, type: 'pull_request')
    end

    def comments
      store[:activities].where(project_id: id, type: 'comment')
    end

    private

    def load_config(config_file)
      config = YAML.load_file(config_file)

      @name    = config.delete('name') { raise 'Project name not configured' }
      @path    = config.delete('path') { raise 'Project path not configured' }
      @db_path = config.delete('db') { raise 'Project db not configured' }

      @config = OpenStruct.new(config).freeze
    end

    def initialize_db_project
      projects = store[:projects]

      @id = if projects.where(name: name).empty?
              projects.insert(name: name)
            else
              projects.where(name: name).get(:id)
            end
    end

  end
end
