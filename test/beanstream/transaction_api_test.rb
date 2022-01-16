require 'test/unit'
require 'beanstream'
require 'shoulda'

module Beanstream
  class TransactionAPITest < Test::Unit::TestCase
    should "encode return exact string" do
      assert_equal("MTIzNDU6YWJjZGVmZw==", Transaction.new.encode("12345", "abcdefg"))
    end
  end
end
