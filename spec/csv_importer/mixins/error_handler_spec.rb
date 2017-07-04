require 'spec_helper'

describe 'ErrorHandler module' do
  before do
    module CSVImporter
      # Class for test
      class SomeTest
        include Mixins::ErrorHandler

        def test_to_add_error
          add_error('Some Error')
        end
      end
    end

    @subject = CSVImporter::SomeTest.new
  end

  %w[errors status humanized_errors valid? success?].each do |method|
    it "should respond_to #{method}" do
      expect(@subject).to respond_to(method)
    end
  end

  it 'should be valid if no errors' do
    expect(@subject.valid?).to be_truthy
    expect(@subject.success?).to be_truthy
  end

  it 'should not be valid if errors' do
    @subject.errors << 'Some Error'
    expect(@subject.valid?).to be_falsy
    expect(@subject.success?).to be_falsy
  end

  it 'should be success if no errors' do
    expect(@subject.status).to eq(:success)
  end

  it 'should be fail if has errors' do
    @subject.errors << 'Some Error'
    expect(@subject.status).to eq(:failed)
  end

  it 'can #add_error' do
    @subject.test_to_add_error
    expect(@subject.status).to eq(:failed)
    expect(@subject.valid?).to be_falsy
    expect(@subject.success?).to be_falsy
    expect(@subject.errors).to eq(['Some Error'])
  end

  it 'can #humanized_errors' do
    @subject.test_to_add_error
    @subject.test_to_add_error
    @subject.test_to_add_error
    expect(@subject.humanized_errors).to eq(
      'Some Error; Some Error; Some Error'
    )
  end
end
