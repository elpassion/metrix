require 'forwardable'

class Importer
  extend Forwardable

  delegate [:log, :log_warning, :log_success] => :logger

  def initialize(project, logger: nil)
    @project = project
    @logger  ||= Metrix::Logger.instance
  end

  def import(truncate: false)
    @truncate = truncate

    log "Importing #{resource_name}", level: 0

    if truncate
      log "Deleting all project #{resource_name}"

      truncate_resources
    end

    do_import
  end

  private

  attr_reader :project, :imported_resources, :skipped_resources, :truncate, :logger

  class << self
    attr_accessor :resource_type
  end

  def do_import
    @imported_resources = []
    @skipped_resources  = []

    log 'Importing'

    import_resources

    log_warning "Skipped #{skipped_resources.size} #{resource_name}" if skipped_resources.any?
    log_success "Imported #{imported_resources.size} #{resource_name}"
  end

  def import_resources
    raise NotImplementedError
  end

  def truncate_resources
    resources_scope.delete
  end

  def resources_scope
    project.public_send(resource_type)
  end

  def resource_type
    self.class.resource_type
  end

  def resource_name
    resource_type.to_s.tr('-_', ' ').capitalize
  end
end
