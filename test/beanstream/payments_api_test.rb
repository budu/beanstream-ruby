require 'test/unit'
require 'beanstream'
require 'shoulda'

module Beanstream
  class PaymentsAPITest < Test::Unit::TestCase
    should "canery test print out Beanstream!" do
      puts "Beanstream!"
      assert true
    end

    should "make payment url be the same" do
      assert_equal("/v1/payments/", PaymentsAPI.new.make_payment_url())
    end

    should "make return url be the same" do
      assert_equal("/v1/payments/1234/returns", PaymentsAPI.new.payment_returns_url("1234"))
    end

    should "make void url be the same" do
      assert_equal("/v1/payments/1234/void", PaymentsAPI.new.payment_void_url("1234"))
    end
  end

  class PaymentsAPIIntegrationTest < Test::Unit::TestCase
    setup do
      Beanstream.merchant_id = "300200578"
      Beanstream.payments_api_key = "4BaD82D9197b4cc4b70a221911eE9f70"
    end

    # Card purchase
    should "have successful credit card payment" do
      result = Beanstream.PaymentsAPI.make_payment(
        {
          :order_number => PaymentsAPI.generateRandomOrderId("test"),
          :amount => 100,
          :payment_method => PaymentMethods::CARD,
          :card => {
            :name => "Mr. Card Testerson",
            :number => "4030000010001234",
            :expiry_month => "07",
            :expiry_year => "22",
            :cvd => "123",
            :complete => true
          }
        }
      )
      puts "result: #{result}"

      assert(PaymentsAPI.payment_approved(result))
      transaction_id = result['id']
      puts "TransactionId: #{transaction_id}"
    end

    # Token purchase
    should "purchase successfully with a legato token" do
      token = Beanstream.PaymentsAPI.get_legato_token(
        {
          :number => "4030000010001234",
          :expiry_month => "07",
          :expiry_year => "22",
          :cvd => "123"
        }
      )
      puts "token result: #{token}"
      assert(token != nil)

      begin
        result = Beanstream.PaymentsAPI.make_payment(
          {
            :order_number => PaymentsAPI.generateRandomOrderId("test"),
            :amount => 13.99,
            :payment_method => PaymentMethods::TOKEN,
            :token => {
              :name => "Bobby Test",
              :code => token,
              :complete => true
            }
          }
        )
        puts "result: #{result}"
        assert(PaymentsAPI.payment_approved(result))
      rescue BeanstreamException => ex
        assert(false)
      end
    end

    # Card decline
    should "have declined credit card payment" do

      decline = false
      begin
        result = Beanstream.PaymentsAPI.make_payment(
        {
          :order_number => PaymentsAPI.generateRandomOrderId("test"),
          :amount => 100,
          :payment_method => PaymentMethods::CARD,
          :card => {
            :name => "Mr. Card Testerson",
            :number => "4003050500040005", #declined card
            :expiry_month => "07",
            :expiry_year => "22",
            :cvd => "123",
            :complete => true
          }
        })
        puts "Success! TransactionID: #{result['id']}"

      rescue BeanstreamException => ex
        decline = true
        puts "Exception: #{ex.user_facing_message}"
        assert(ex.user_facing_message == "DECLINE")
        assert(ex.is_user_error())
      end

      assert(decline)
    end

    # PreAuth card
    should "have successful credit card pre-auth and completion" do

      decline = false
      begin
        result = Beanstream.PaymentsAPI.make_payment(
          {
            :order_number => PaymentsAPI.generateRandomOrderId("test"),
            :amount => 100,
            :payment_method => PaymentMethods::CARD,
            :card => {
              :name => "Mr. Card Testerson",
              :number => "4030000010001234",
              :expiry_month => "07",
              :expiry_year => "22",
              :cvd => "123",
              :complete => false
            }
          }
        )
        puts "result: #{result}"
        assert(PaymentsAPI.payment_approved(result))
        transaction_id = result['id']
        puts "TransactionId: #{transaction_id}"

        result = Beanstream.PaymentsAPI.complete_preauth(transaction_id, 59.50)
        puts "completion result: #{result}"
        assert(PaymentsAPI.payment_approved(result))

      rescue BeanstreamException => ex
        decline = true
        puts "Exception: #{ex.user_facing_message}"
        assert(ex.user_facing_message == "DECLINE")
        assert(ex.is_user_error())
      end

      assert(!decline)
    end

    # PreAuth token
    should "pre-auth and complete successfully with a legato token" do

      # 1) get token (this is normally done in the client app)
      token = Beanstream.PaymentsAPI.get_legato_token(
        {
          :number => "4030000010001234",
          :expiry_month => "07",
          :expiry_year => "22",
          :cvd => "123"
        }
      )
      puts "token result: #{token}"
      assert(token != nil)

      # 2) make pre-auth
      begin
        result = Beanstream.PaymentsAPI.make_payment(
          {
            :order_number => PaymentsAPI.generateRandomOrderId("test"),
            :amount => 13.99,
            :payment_method => PaymentMethods::TOKEN,
            :token => {
              :name => "Bobby Test",
              :code => token,
              :complete => false
            }
          }
        )
        puts "result: #{result}"
        assert(PaymentsAPI.payment_approved(result))
        transaction_id = result['id']

        # 3) complete purchase
        result = Beanstream.PaymentsAPI.complete_preauth(transaction_id, 10.33)
        puts "completion result: #{result}"
        assert(PaymentsAPI.payment_approved(result))
      rescue BeanstreamException => ex
        puts "card declined"
        assert(false)
      end
    end

    # Return
    should "have successful credit card payment, then get the payment, then return the payment" do

      result = Beanstream.PaymentsAPI.make_payment(
        {
          :order_number => PaymentsAPI.generateRandomOrderId("test"),
          :amount => 100,
          :payment_method => PaymentMethods::CARD,
          :card => {
            :name => "Mr. Card Testerson",
            :number => "4030000010001234",
            :expiry_month => "07",
            :expiry_year => "22",
            :cvd => "123",
            :complete => true
          }
        }
      )

      transaction_id = result['id']

      # => test get payments
      get_result = Beanstream.PaymentsAPI.get_transaction(transaction_id)
      assert_equal "P",         get_result["type"]
      assert_equal "Approved",  get_result["message"]

      # => test return payment
      return_result = Beanstream.PaymentsAPI.return_payment(transaction_id, 100)
      assert_equal "Approved",  return_result["message"]
      assert_equal "R",         return_result["type"]
      get_after_return = Beanstream.PaymentsAPI.get_transaction(transaction_id)
      assert_equal 100.0, get_after_return["total_refunds"]

      # => try to void the payment after returning
      assert_raises InvalidRequestException do
        Beanstream.PaymentsAPI.void_payment(transaction_id, 100)
      end
    end

    # Void
    should "have successful credit card payment, then void the payment" do

      result = Beanstream.PaymentsAPI.make_payment(
        {
          :order_number => PaymentsAPI.generateRandomOrderId("test"),
          :amount => 100,
          :payment_method => PaymentMethods::CARD,
          :card => {
            :name => "Mr. Card Testerson",
            :number => "4030000010001234",
            :expiry_month => "07",
            :expiry_year => "22",
            :cvd => "123",
            :complete => true
          }
        }
      )

      transaction_id = result['id']

      # => test void payment
      void_result = Beanstream.PaymentsAPI.void_payment(transaction_id, 100)
      assert_equal "Approved",  void_result["message"]
      assert_equal "VP",        void_result["type"]
      get_after_void = Beanstream.PaymentsAPI.get_transaction(transaction_id)
      assert_equal "VP", get_after_void["adjusted_by"][0]["type"]

      # => try to return the payment after voiding
      assert_raises InvalidRequestException do
        Beanstream.PaymentsAPI.return_payment(transaction_id, 100)
      end
    end

    should "not get a random transaction id" do
      assert_raises InvalidRequestException do
        Beanstream.PaymentsAPI.get_transaction("500")
      end
    end

    should "not return a random transaction id" do
      assert_raises InvalidRequestException do
        Beanstream.PaymentsAPI.return_payment("500", 100)
      end
    end

    should "not void a random transaction id" do
      assert_raises InvalidRequestException do
        Beanstream.PaymentsAPI.void_payment("500", 100)
      end
    end
  end
end
