class Importer
  LOG_PREFIXES   = ['=====> ', '-----> ', '       ']
  LOG_INDICATORS = { info: ' ', warning: '!', success: '*' }

  def initialize(project)
    @project = project
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

  def log(text, level: 2, type: :info)
    prefix       = LOG_PREFIXES[level]
    empty_prefix = ' ' * prefix.length
    prefix[-2]   = empty_prefix[-2] = LOG_INDICATORS[type] if level > 1
    text         = text.strip.gsub(/\n/, "\n#{empty_prefix}")

    puts "#{prefix}#{text}"
  end

  def log_warning(text)
    log(text, level: 2, type: :warning)
  end

  def log_success(text)
    log(text, level: 2, type: :success)
  end

  private

  attr_reader :project, :imported_resources, :skipped_resources, :truncate

  class << self
    attr_accessor :resource_name
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
    raise NotImplementedError
  end

  def resource_name
    self.class.resource_name
  end
end