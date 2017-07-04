require 'spec_helper'

describe 'CSVImporter::Row' do
  subject { CSVImporter::Row }

  let(:valid_row) do
    CSVImporter::Row::COLUMNS.each_with_object({}) do |column, memo|
      memo[column] = case column
                     when 'UMSATZ_KEY' then '10'
                     when 'SENDER_KONTO' then '1'
                     when 'ACTIVITY_ID' then '42'
                     else ''
                     end
    end
  end

  let(:invalid_row) do
    CSVImporter::Row::COLUMNS.each_with_object({}) do |column, memo|
      memo[column] = ''
    end
  end

  ROW_METHODS = (CSVImporter::Row::COLUMNS + %i[row sender]).freeze

  ROW_METHODS.each do |column|
    it "should respond to #{column}" do
      expect(subject.new(valid_row)).to respond_to(column.downcase)
    end
  end

  %w[10 16].each do |key|
    it "should be valid after initialization when UMSATZ_KEY eq #{key}" do
      invalid_row['UMSATZ_KEY'] = key
      expect(subject.new(valid_row).valid?).to be_truthy
    end
  end

  %w[1 a b 42].each do |key|
    it "should not be valid after initialization when UMSATZ_KEY eq #{key}" do
      invalid_row['UMSATZ_KEY'] = key
      expect(subject.new(invalid_row).valid?).to be_falsey
    end
  end

  it 'successfully fetched a sender from Account if valid' do
    expect(subject.new(valid_row).sender).not_to be_nil
  end

  it 'failed fetching a sender from Account if invalid' do
    expect(subject.new(invalid_row).sender).to be_nil
  end

  it 'records an error when sender not found' do
    valid_row['SENDER_KONTO'] = '15'
    expect(subject.new(valid_row).sender).to be_nil
    expect(subject.new(valid_row).valid?).to be_falsey
    expect(subject.new(valid_row).humanized_errors).to eq(
      '42: Account 15 not found'
    )
  end

  it 'has composit #subject' do
    CSVImporter::Row::COLUMNS.each_with_index do |column, index|
      valid_row[column] = "#{index}\n" if column.match?(/DESC\d{1,2}/)
    end
    expect(subject.new(valid_row).subject).to eq(
      "15\n16\n17\n18\n19\n20\n21\n22\n23\n24\n25\n26\n27\n28\n"
    )
  end

  describe '#lastschrift?' do
    it 'returns true' do
      valid_row['UMSATZ_KEY'] = '16'
      valid_row['RECEIVER_BLZ'] = '70022200'
      expect(subject.new(valid_row).lastschrift?).to be_truthy
      expect(subject.new(valid_row).transaction_type).to be(
        CSVImporter::Transfers::Lastschrift
      )
    end

    it 'returns false' do
      valid_row['UMSATZ_KEY'] = '10'
      valid_row['RECEIVER_BLZ'] = '111111111'
      row = subject.new(valid_row)
      expect(row.lastschrift?).to be_falsy
      expect(row.transaction_type).to be(
        CSVImporter::Transfers::NullTransfer
      )
    end
  end

  describe '#bank_transfer?' do
    it 'returns true' do
      valid_row['UMSATZ_KEY'] = '10'
      valid_row['SENDER_BLZ'] = '00000000'
      expect(subject.new(valid_row).bank_transfer?).to be_truthy
      expect(subject.new(valid_row).transaction_type).to be(
        CSVImporter::Transfers::BankTransfer
      )
    end

    it 'returns false' do
      valid_row['UMSATZ_KEY'] = '10'
      valid_row['SENDER_BLZ'] = '111111111'
      row = subject.new(valid_row)
      expect(row.bank_transfer?).to be_falsy
      expect(row.transaction_type).to be(
        CSVImporter::Transfers::NullTransfer
      )
    end
  end

  describe '#account_transfer?' do
    it 'returns true' do
      valid_row['RECEIVER_BLZ'] = '00000000'
      valid_row['SENDER_BLZ'] = '00000000'
      expect(subject.new(valid_row).account_transfer?).to be_truthy
      expect(subject.new(valid_row).transaction_type).to be(
        CSVImporter::Transfers::AccountTransfer
      )
    end

    it 'returns false' do
      valid_row['RECEIVER_BLZ'] = '111111111'
      valid_row['SENDER_BLZ'] = '111111111'
      row = subject.new(valid_row)
      expect(row.account_transfer?).to be_falsy
      expect(row.transaction_type).to be(
        CSVImporter::Transfers::NullTransfer
      )
    end
  end

  describe '#transaction_type' do
    it 'returns NullTransfer if transaction_type not found' do
      row = subject.new(valid_row)
      row.transaction_type
      expect(row.humanized_errors).to eq(
        '42: Transaction type not found'
      )
      expect(row.transaction_type).to be(
        CSVImporter::Transfers::NullTransfer
      )
    end

    it 'returns valid AccountTransfer class' do
      allow_any_instance_of(
        CSVImporter::Row
      ).to receive(:account_transfer?).and_return(true)
      expect(subject.new(valid_row).transaction_type).to be(
        CSVImporter::Transfers::AccountTransfer
      )
    end

    it 'returns valid BankTransfer class' do
      allow_any_instance_of(
        CSVImporter::Row
      ).to receive(:bank_transfer?).and_return(true)
      expect(subject.new(valid_row).transaction_type).to be(
        CSVImporter::Transfers::BankTransfer
      )
    end

    it 'returns valid lastschrift class' do
      allow_any_instance_of(
        CSVImporter::Row
      ).to receive(:lastschrift?).and_return(true)
      expect(subject.new(valid_row).transaction_type).to be(
        CSVImporter::Transfers::Lastschrift
      )
    end
  end

  describe '#import' do
    it 'fires transaction_type.import!(self) if valid' do
      allow_any_instance_of(
        CSVImporter::Row
      ).to receive(:account_transfer?).and_return(true)
      row = subject.new(valid_row)
      expect(row.transaction_type).to receive(:new).with(row)
      row.import
    end

    it 'does not fire transaction_type.import!(self) if invalid' do
      allow_any_instance_of(
        CSVImporter::Row
      ).to receive(:valid?).and_return(false)
      row = subject.new(invalid_row)
      expect(row.transaction_type).to_not receive(:new)
      row.import
    end

    it 'receives an error if something went wrong' do
      allow_any_instance_of(
        CSVImporter::Row
      ).to receive(:transaction_type).and_return(
        CSVImporter::Transfers::Lastschrift
      )
      allow_any_instance_of(CSVImporter::Transfers::Lastschrift).to receive(
        :import!
      ).and_raise(StandardError.new('Some Error from Lastschrift!'))
      row = subject.new(valid_row)
      row.import
      expect(row.humanized_errors).to eq('42: Some Error from Lastschrift!')
    end
  end
end
