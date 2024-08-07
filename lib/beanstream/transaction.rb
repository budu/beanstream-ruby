require 'rest-client'
require 'base64'
require 'json'

module Beanstream
  class Transaction

    def encode(merchant_id, api_key)
      str = "#{merchant_id}:#{api_key}"
      enc = Base64.encode64(str).gsub("\n", "")
    end

    def transaction_post(method, url_path, merchant_id, api_key, data={})
      enc = encode(merchant_id, api_key)

      path = Beanstream.api_host_url+url_path
      #puts "processing the data: #{method} #{path} #{data.to_json}"

      req_params = {
        :verify_ssl => OpenSSL::SSL::VERIFY_PEER,
        :timeout => Beanstream.timeout,
        :open_timeout => Beanstream.open_timeout,
        :headers => {
          :authorization => "Passcode #{enc}",
          :content_type => "application/json"
        },
        :method => method,
        :url => path,
        :payload => data.to_json
      }

      begin
        result = RestClient::Request.execute(req_params)
        returns = JSON.parse(result)
      rescue RestClient::ExceptionWithResponse => ex
        if ex.response
          raise handle_api_error(ex)
        else
          raise handle_restclient_error(ex)
        end
      rescue RestClient::Exception => ex
        raise handle_restclient_error(ex)
      end

    end

    def handle_api_error(ex)
      #puts "error: #{ex}"

      http_status_code = ex.http_code
      message = ex.message
      code = 0
      category = 0

      begin
        obj = JSON.parse(ex.http_body)
        obj = Util.symbolize_names(obj)
        code = obj[:code]
        category = obj[:category]
        message = obj[:message]
      rescue JSON::ParserError
        puts "Error parsing json error message"
      end

      if http_status_code == 302
        raise InvalidRequestException.new(code, category, "Redirection for IOP and 3dSecure not supported by the Beanstream SDK yet. #{message}", http_status_code)
      elsif http_status_code == 400
        raise InvalidRequestException.new(code, category, message, http_status_code)
      elsif code == 401
        raise UnauthorizedException.new(code, category, message, http_status_code)
      elsif code == 402
        raise BusinessRuleException.new(code, category, message, http_status_code)
      elsif code == 403
        raise ForbiddenException.new(code, category, message, http_status_code)
      elsif code == 405
        raise InvalidRequestException.new(code, category, message, http_status_code)
      elsif code == 415
        raise InvalidRequestException.new(code, category, message, http_status_code)
      elsif code >= 500
        raise InternalServerException.new(code, category, message, http_status_code)
      else
        raise BeanstreamException.new(code, category, message, http_status_code)
      end
    end

    def handle_restclient_error(e)

      case e
      when RestClient::RequestTimeout
        message = "Could not connect to Beanstream"

      when RestClient::ServerBrokeConnection
        message = "The connection to the server broke before the request completed."

      when RestClient::SSLCertificateNotVerified
        message = "Could not verify Beanstream's SSL certificate. " \
          "Please make sure that your network is not intercepting certificates. "

      when SocketError
        message = "Unexpected error communicating when trying to connect to Beanstream. "

      else
        message = "Unexpected error communicating with Beanstream. "

      end

      raise APIConnectionError.new(message + "\n\n(Network error: #{e.message})")
    end
  end

end
