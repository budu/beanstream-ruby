require 'beanstream/transaction'
require 'beanstream/payments_api'
require 'beanstream/profiles_api'
require 'beanstream/reporting_api'
require 'beanstream/util'
require 'beanstream/exceptions'

module Beanstream

  @url_prefix = "www"
  @url_suffix = "api"
  @url_base = "beanstream.com"
  @url_version = "v1"
  @ssl_ca_cert = File.dirname(__FILE__) + '/resources/cacert.pem'
  @timeout = 80
  @open_timeout = 40

  class << self
    attr_accessor :merchant_id, :payments_api_key, :profiles_api_key, :reporting_api_key
    attr_accessor :url_prefix, :url_base, :url_suffix, :url_version
    attr_accessor :url_payments, :url_return, :url_void
    attr_accessor :ssl_ca_cert, :timeout, :open_timeout
  end

  def self.api_host_url()
    "https://#{@url_prefix}.#{url_base}"
  end

  def self.api_base_url()
    "/#{url_suffix}/#{url_version}"
  end

  def self.PaymentsAPI()
    Beanstream::PaymentsAPI.new()
  end

  def self.ProfilesAPI()
    Beanstream::ProfilesAPI.new()
  end

  def self.ReportingAPI()
    Beanstream::ReportingAPI.new()
  end
end


def run()
  Beanstream.merchant_id = "300200578"
  Beanstream.payments_api_key = "4BaD82D9197b4cc4b70a221911eE9f70"
  result = Beanstream.PaymentsAPI().make_creditcard_payment(12.5)
  puts "Payment result: #{result}"
end
