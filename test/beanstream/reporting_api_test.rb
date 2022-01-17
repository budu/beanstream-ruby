require 'test/unit'
require 'beanstream'
require 'shoulda'

module Beanstream
  class ReportingAPITest < Test::Unit::TestCase
    setup do
      Beanstream.merchant_id = "300200578"
      Beanstream.payments_api_key = "4BaD82D9197b4cc4b70a221911eE9f70"
      Beanstream.reporting_api_key = "4e6Ff318bee64EA391609de89aD4CF5d"
    end

    should "make reports url be the same" do
      assert_equal("/api/v1/reports", ReportingAPI.new.reports_url())
    end
  end

  class ReportingAPIIntegrationTest < Test::Unit::TestCase
    setup do
      Beanstream.merchant_id = "300200578"
      Beanstream.payments_api_key = "4BaD82D9197b4cc4b70a221911eE9f70"
      Beanstream.reporting_api_key = "4e6Ff318bee64EA391609de89aD4CF5d"
    end

    should "have successfully found my payments" do
      prefix = SecureRandom.hex(4)
      # prepare a payment
      orderNum1 = PaymentsAPI.generateRandomOrderId(prefix)
      puts "OrderID 1: #{orderNum1}"
      purchase = {
        "order_number" => orderNum1,
        "amount" => 100,
        "payment_method" => PaymentMethods::CARD,
        "card" => {
          "name" => "Mr. Card Testerson",
          "number" => "4030000010001234",
          "expiry_month" => "07",
          "expiry_year" => "22",
          "cvd" => "123",
          "complete" => true
        },
        "custom" => {
          "ref1" => prefix
        }
      }
      # make a 1st purchase
      result = Beanstream.PaymentsAPI.make_payment(purchase)
      assert(PaymentsAPI.payment_approved(result))
      transaction_1_id = result['id']

      # make a 2nd purchase
      orderNum2 = PaymentsAPI.generateRandomOrderId(prefix)
      puts "OrderID 2: #{orderNum2}"
      purchase['amount'] = 33.29
      purchase['order_number'] = orderNum2
      result = Beanstream.PaymentsAPI.make_payment(purchase)
      assert(PaymentsAPI.payment_approved(result))
      transaction_2_id = result['id']

      # make a 3nd purchase
      orderNum3 = PaymentsAPI.generateRandomOrderId(prefix)
      puts "OrderID 3: #{orderNum3}"
      purchase['amount'] = 21.55
      purchase['order_number'] = orderNum3
      result = Beanstream.PaymentsAPI.make_payment(purchase)
      assert(PaymentsAPI.payment_approved(result))
      transaction_3_id = result['id']

      # search for transactions
      last3Hours = Time.now - 3*60*60
      next3Hours = Time.now + 3*60*60
      results = Beanstream.ReportingAPI.search_transactions(last3Hours, next3Hours, 1, 3)
      assert(results != nil)
      assert(results.length == 3)

      # find transaction 1 from order number
      results = Beanstream.ReportingAPI.search_transactions(
        last3Hours,
        next3Hours,
        1,
        10,
        Criteria.new(
          Fields::OrderNumber,
          Operators::EQUALS,
          orderNum1
        )
      )
      assert(results != nil)
      puts "Report search by order number\n: #{results}"
      assert(results.length == 1, "Found #{results.length} instead")

      # find transaction 2 and 3 from ref1 and amount
      results = Beanstream.ReportingAPI.search_transactions(last3Hours, next3Hours, 1, 10,
        Array[
          Criteria.new(Fields::Ref1, Operators::EQUALS, prefix),
          Criteria.new(Fields::Amount, Operators::LESS_THAN, 50)
        ]
       )
      assert(results != nil)
      puts "Report search by order number and amount\n: #{results}"
      assert(results.length == 2, "Found #{results.length} instead")
    end
  end
end
