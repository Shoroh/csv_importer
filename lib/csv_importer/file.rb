require './lib/csv_importer/mixins/error_handler'

module CSVImporter
  # Use this class for File handling
  class File
    include Mixins::ErrorHandler

    attr_reader :file, :dtaus, :config, :sftp

    def initialize(file)
      @config = CSVImporter.config
      @file = file
      @dtaus = config.dtaus
      @sftp = config.sftp
      ensure_directory_exists
    end

    def import
      rows.map do |row|
        Row.new(row)
      end.each(&:import)
      cleanup!
    end

    def name
      file.name
    end

    def remote_path
      @remote_path ||= "/data/files/csv/#{name}"
    end

    def local_path
      @local_path ||= "#{config.download_path}/#{name}"
    end

    private

    def cleanup!
      add_datei
      rows[:failed].each do |row|
        next if row.success?
        add_error("Row ##{row.activity_id}: #{row.humanized_errors}")
      end
    end

    def rows
      @rows ||= CSV.read(
        file,
        col_sep: ';',
        headers: true,
        skip_blanks: true
      )
    end

    def add_datei
      return if !valid? && config.validation_only && dtaus.is_empty?
      dtaus.add_datei("#{path_and_name}_201_mraba.csv")
    end

    def ensure_directory_exists
      return if File.directory?(source_path)
      FileUtils.mkdir_p "#{source_path}/csv/tmp_mraba"
    end

    def source_path
      @source_path ||= "#{::Rails.root}/private/upload"
    end

    def path_and_name
      @path_and_name ||= "#{source_path}/csv/tmp_mraba/DTAUS\
      #{Time.now.strftime('%Y%m%d_%H%M%S')}"
    end
  end
end
