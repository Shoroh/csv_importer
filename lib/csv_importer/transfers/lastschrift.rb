module CSVImporter
  module Transfers
    # Use this Class for creating a Lastschrift
    class Lastschrift
      attr_reader :dtaus, :row, :config

      def initialize(row)
        @config = CSVImporter.config
        @dtaus = config.dtaus
        @row = row
        @validation_only = config.validation_only
      end

      def import!
        return unless can_import?
        dtaus.add_buchung(
          row.sender_konto,
          row.sender_blz,
          holder,
          BigDecimal(row.amount).abs,
          row.subject
        )
      end

      def can_import?
        if valid_sender?
          true
        else
          add_error(
            "#{row.activity_id}: BLZ/Konto not valid, csv fiile not written"
          )
          false
        end
      end

      def valid_sender?
        dtaus.valid_sender?(row.sender_konto, row.sender_blz)
      end

      private

      def holder
        # TODO: Iconv is deprecated, use String#encode instead.
        @holder ||= Iconv.iconv(
          'ascii//translit', 'utf-8', row.sender_name
        ).to_s.gsub(/[^\w^\s]/, '')
      end
    end
  end
end
