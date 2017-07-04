require './lib/csv_importer/mixins/error_handler'
require './lib/csv_importer/transfers/account_transfer'
require './lib/csv_importer/transfers/bank_transfer'
require './lib/csv_importer/transfers/lastschrift'

module CSVImporter
  # Use this class for CSV rows handling
  class Row
    include Mixins::ErrorHandler

    COLUMNS = %w[
      ACTIVITY_ID
      DEPOT_ACTIVITY_ID
      KONTONUMMER
      AMOUNT
      CURRENCY
      ENTRY_DATE
      VALUE_DATE
      UMSATZ_KEY
      UMSATZ_KEY_EXT
      RECEIVER_BLZ
      RECEIVER_KONTO
      RECEIVER_NAME
      SENDER_BLZ
      SENDER_KONTO
      SENDER_NAME
      DESC1
      DESC2
      DESC3
      DESC4
      DESC5
      DESC6
      DESC7
      DESC8
      DESC9
      DESC10
      DESC11
      DESC12
      DESC13
      DESC14
      INT_UMSATZ_KEY
    ].freeze

    attr_reader :row, :sender

    COLUMNS.each do |column|
      define_method(column.downcase) { row[column] }
    end

    def initialize(row)
      @row = row
      validate
      @sender = fetch_sender if valid?
    end

    def import
      return unless valid?
      transfer = transaction_type.new(self)
      transfer.import!
      add_error(transfer.humanized_errors) unless transfer.success?
    rescue => e
      add_error("#{activity_id}: #{e.message}")
    end

    def transaction_type
      if account_transfer?
        Transfers::AccountTransfer
      elsif bank_transfer?
        Transfers::BankTransfer
      elsif lastschrift?
        Transfers::Lastschrift
      else
        add_error("#{activity_id}: Transaction type not found")
        Transfers::NullTransfer
      end
    end

    def account_transfer?
      sender_blz == '00000000' && receiver_blz == '00000000'
    end

    def bank_transfer?
      sender_blz == '00000000' && umsatz_key == '10'
    end

    def lastschrift?
      receiver_blz == '70022200' && umsatz_key == '16'
    end

    def subject
      @subject ||= (1..14).each_with_object('') do |id, subject|
        current_desc = public_send("desc#{id}").to_s
        subject << current_desc unless current_desc.blank?
      end
    end

    private

    def fetch_sender
      ::Account.find_by!(account_no: sender_konto)
    rescue ::ActiveRecord::RecordNotFound
      add_error("#{activity_id}: Account #{sender_konto} not found")
      nil
    end

    def validate
      return if %w[10 16].include?(umsatz_key)
      add_error("#{activity_id}: UMSATZ_KEY #{umsatz_key} is not allowed")
    end
  end
end
