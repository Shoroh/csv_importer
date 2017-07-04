require './lib/csv_importer/config'

# Main Module
module CSVImporter
  class << self
    attr_writer :config

    def config
      @config ||= Config.new
    end

    def configure
      yield(config) if block_given?
    end

    def reset
      @config = Config.new
    end
  end
end
