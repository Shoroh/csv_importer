module CSVImporter
  module Transfers
    # Use this Class for creating a Bank Transfer
    class BankTransfer
      attr_reader :row, :validation_only

      def initialize(row)
        @row = row
        @validation_only = CSVImporter.config.validation_only
      end

      def import!
        return unless can_import?
        bank_transfer.save!
      end

      def can_import?
        if !bank_transfer.valid?
          add_error(
            "#{row.activity_id}: BankTransfer validation error(s): \
            #{bank_transfer.errors.full_messages.join('; ')}"
          )
          false
        else
          !validation_only
        end
      end

      private

      def bank_transfer
        @bank_transfer ||= row.sender.build_transfer(
          amount: row.amount.to_f,
          subject: row.subject,
          rec_holder: row.receiver_name,
          rec_account_number: row.receiver_konto,
          rec_bank_code: row.receiver_blz
        )
      end
    end
  end
end
