require_relative '../mixins/error_handler'

module CSVImporter
  module Transfers
    # Use this Class like a Null Object
    class NullTransfer
      def initialize(_row); end

      def import!
        false
      end
    end
  end
end
