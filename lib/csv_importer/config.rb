require 'logger'
require 'net/sftp'

module CSVImporter
  # Use this class to store some defaults and to setup
  class Config
    attr_accessor :logger, :dtaus, :validation_only,
                  :remote_path, :download_path, :valid_extensions,
                  :ftp_host, :ftp_user, :ftp_options

    attr_reader :sftp

    def initialize
      @logger = defined?(Rails) ? ::Rails.logger : ::Logger.new(STDOUT)
      @dtaus = ::Mraba::Transaction.define_dtaus(
        'RS', 8_888_888_888, 99_999_999, 'Credit collection'
      )
      @validation_only = false
      @remote_path = '/data/files/csv'
      @download_path = "#{::Rails.root}/private/data/download"
      @upload_path = "#{::Rails.root}/private/data/upload"
      @valid_extensions = %w[.csv]
      ftp_defaults
    end

    private

    def ftp_defaults
      @ftp_host = if Rails.env.production?
                    'csv.example.com/endpoint/'
                  else
                    '0.0.0.0:2020'
                  end
      @ftp_user = 'demo_user'
      @ftp_options = { password: 'demo_password' }
      @sftp = Net::SFTP.start(
        ftp_host, ftp_user, ftp_options
      )
    end
  end
end
