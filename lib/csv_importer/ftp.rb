module CSVImporter
  # The Main Class, which is gathering files from the server
  class FTP
    attr_reader :config, :sftp, :send_email

    def initialize(send_email = true)
      @send_email = send_email
      @config = CSVImporter.config
      @sftp = config.sftp
      ensure_directory_exists
      download_files
    end

    def import
      files.each(&:import)
      cleanup!
    end

    private

    def cleanup!
      done_files = files.group_by(&:status)
      delete_success_files(done_files[:success])
      upload_failed_files(done_files[:failed])
      notify!
    end

    def notify!
      # I'd better send only one email with the list of all files
      # with their stasuses&errors
      files.each do |file|
        file.success? ? notify_success(file) : notify_fail(file)
      end
    end

    def notify_success(file)
      return unless send_email
      BackendMailer.send_import_feedback(
        'Successful Import', "Import of the file #{file.name} done."
      )
    end

    def notify_fail(file)
      return unless send_email
      BackendMailer.send_import_feedback(
        'Import CSV failed', error_builder(file)
      )
    end

    def error_builder(file)
      [
        "Import of the file #{file.name} failed with errors:",
        file.humanized_errors
      ].join("\n")
    end

    def download_files
      files.map do |file|
        sftp.download(file.remote_path, file.local_path)
      end.each(&:wait)
    end

    def files
      @files ||= begin
        sftp.dir.entries(config.remote_path)
            .each_with_object([]) do |entry, files|
          if config.valid_extensions.include?(extension(entry))
            files << File.new(entry)
          end
        end
      end
    end

    def ensure_directory_exists
      [config.download_path, config.upload_path].each do |path|
        FileUtils.mkdir_p(path) unless File.directory?(path)
      end
    end

    def extension(entry)
      entry.name[/\.[^.]+$/]
    end

    def delete_success_files(success_files)
      success_files.map do |file|
        File.delete(file.local_path)
        sftp.remove(file.remote_path)
      end.each(&:wait)
    end

    def upload_failed_files(failed_files)
      failed_files.map do |file|
        local_file = "#{config.upload_path}/#{file.name}"
        File.open(local_file, 'w') do |f|
          f.write(file.humanized_errors)
        end
        sftp.upload(error_file, "/data/files/batch_processed/#{file.name}")
      end.each(&:wait)
    end
  end
end
