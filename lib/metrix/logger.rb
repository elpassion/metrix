module Metrix
  class Logger
    include Singleton

    LOG_PREFIXES   = ['=====> ', '-----> ', '       ']
    LOG_INDICATORS = { info: ' ', warning: '!', success: '*' }

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
  end
end