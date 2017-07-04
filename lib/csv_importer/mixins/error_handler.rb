require 'csv_importer'

module CSVImporter
  module Mixins
    # We use this handler to bring Errors Handling to a class
    module ErrorHandler
      def errors
        @errors ||= []
      end

      def valid?
        errors.empty?
      end
      alias success? valid?

      def status
        success? ? :success : :fail
      end

      def humanized_errors
        errors.join('; ')
      end

      private

      def add_error(error)
        errors << error
        CSVImporter.config.logger.debug(error)
      end
    end
  end
end
