require 'ostruct'

# Fakes for outside objects
class Account
  attr_reader :id

  def self.find_by!(account_no:)
    raise ActiveRecord::RecordNotFound unless account_no.to_i == 1
    new(account_no)
  end

  def initialize(account_no)
    @id = account_no
  end
end

# Fake Rails for Testing
module Rails
  module_function

  def env
    @env ||= ::OpenStruct.new(production?: false)
  end

  def root
    Dir.pwd
  end

  def logger
    @logger ||= Class.new do
      def info(*_args); end

      def debug(*_args); end
    end.new
  end
end

module ActiveRecord
  # Faked AR Error
  class RecordNotFound < StandardError
  end
end
