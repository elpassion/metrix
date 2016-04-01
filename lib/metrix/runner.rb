require_relative 'migrator'
require_relative 'project'

module Metrix
  class Runner
    AVAILABLE_METRICS = %w(commits releases pulls comments builds issues coverage)

    def initialize(project = nil)
      @project = project || Project.new('config.yml')
      @logger  = Metrix::Logger.new
    end

    def run(only: nil, except: nil, truncate: true)
      metrics   = filter_metrics(except, only)
      importers = load_importers(metrics)

      run_migrations
      run_importers(importers, truncate)
    end

    private

    attr_reader :project, :logger

    def run_migrations
      store = Metrix::Store.new('store.db')
      store.run_migrations!
    end

    def filter_metrics(except, only)
      metrics = only ? AVAILABLE_METRICS & only : AVAILABLE_METRICS
      except ? metrics - except : metrics
    end

    def run_importers(importers, truncate)
      importers.each do |importer_class|
        importer_class.new(project, logger: logger).import(truncate: truncate)
      end
    end

    def load_importers(metrics)
      metrics.map do |metric|
        Kernel.require_relative("../importers/#{metric}_importer")

        Object.const_get("#{metric.capitalize}Importer")
      end
    end
  end
end