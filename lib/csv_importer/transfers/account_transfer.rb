require_relative '../mixins/error_handler'

module CSVImporter
  module Transfers
    # Use this Class for creating an Account Transfer
    class AccountTransfer
      include Mixins::ErrorHandler

      attr_reader :row, :validation_only

      def initialize(row)
        @row = row
        @validation_only = CSVImporter.config.validation_only
      end

      def import!
        return unless can_import?
        if row.depot_activity_id.blank?
          account_transfer.save!
        else
          account_transfer.complete_transfer!
        end
      end

      def can_import?
        if account_transfer && !account_transfer.valid?
          add_error(
            "#{row.activity_id}: AccountTransfer validation error(s): \
            #{account_transfer.errors.full_messages.join('; ')}"
          )
          false
        else
          valid? && !validation_only
        end
      end

      private

      def account_transfer
        @account_transfer ||= if row.depot_activity_id.blank?
                                account_transfer_builder
                              else
                                account_transfer_finder
                              end
      end

      def account_transfer_builder
        row.sender.credit_account_transfers.build(
          amount: row.amount,
          subject: row.subject,
          receiver_multi: row.receiver_konto,
          date: row.entry_date.to_date,
          skip_mobile_tan: true
        )
      end

      def account_transfer_finder
        account_transfer = row.sender.credit_account_transfers.find_by!(
          id: row.depot_activity_id
        )
        if pending?(account_transfer)
          account_transfer.subject = row.subject
          account_transfer
        end
      rescue ActiveRecord::RecordNotFound
        add_error("#{row.activity_id}: AccountTransfer not found")
        nil
      end

      def pending?(account_transfer)
        if account_transfer.state == 'pending'
          true
        else
          add_error(
            "#{row.activity_id}: AccountTransfer state expected 'pending' but \
            was '#{account_transfer.state}'"
          )
          false
        end
      end
    end
  end
end
