
module Beanstream
  class ReportingAPI < Transaction
    def reports_url
      "#{Beanstream.api_base_url()}/reports"
    end

    def search_transactions(start_date, end_date, start_row, end_row, criteria=nil)
      if !start_date.is_a?(Time)
        raise InvalidRequestException.new(0, 0, "start_date must be of type Time in ReportingApi.search_transactions", 0)
      end
      if !end_date.is_a?(Time)
        raise InvalidRequestException.new(0, 0, "end_date must be of type Time in ReportingApi.search_transactions", 0)
      end
      if criteria != nil && !criteria.kind_of?(Array) && !criteria.is_a?(Beanstream::Criteria)
        raise InvalidRequestException.new(0, 0, "criteria must be of type Array<Critiera> or Criteria in ReportingApi.search_transactions", 0)
      end
      if criteria.is_a?(Beanstream::Criteria)
        #make it an array
        criteria = Array[criteria]
      end

      startD = start_date.strftime "%Y-%m-%dT%H:%M:%S"
      endD = end_date.strftime "%Y-%m-%dT%H:%M:%S"

      criteria_hash = Array[]
      if criteria != nil && criteria.length > 0
        for c in criteria
          criteria_hash << c.to_hash
        end
      end
      query = {
        "name" => "Search",
        "start_date" => startD,
        "end_date" => endD,
        "start_row" => start_row,
        "end_row" => end_row,
        "criteria" => criteria_hash
      }
      val = transaction_post("POST", reports_url, Beanstream.merchant_id, Beanstream.reporting_api_key, query)
      results = val['records']
    end
  end

  class Criteria
    attr_accessor :field, :operator, :value

    def initialize(field, operator, value)
      @field = field
      @operator = operator
      @value = value
    end

    def to_hash()
      {'field' => @field, 'operator' => @operator, 'value' => @value}
    end
  end
end

module Operators
  EQUALS = "%3D"
  LESS_THAN = "%3C"
  GREATER_THAN = "%3E"
  LESS_THAN_EQUAL = "%3C%3D"
  GREATER_THAN_EQUAL = "%3E%3D"
  STARTS_WITH = "START%20WITH"
end

module Fields
  TransactionId = 1
  Amount = 2
  MaskedCardNumber = 3
  CardOwner = 4
  OrderNumber = 5
  IPAddress = 6
  AuthorizationCode = 7
  TransType = 8
  CardType = 9
  Response = 10
  BillingName = 11
  BillingEmail = 12
  BillingPhone = 13
  ProcessedBy = 14
  Ref1 = 15
  Ref2 = 16
  Ref3 = 17
  Ref4 = 18
  Ref5 = 19
  ProductName = 20
  ProductID = 21
  CustCode = 22
  IDAdjustmentTo = 23
  IDAdjustedBy = 24
end
