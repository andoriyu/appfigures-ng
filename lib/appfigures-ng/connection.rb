require 'faraday'
require 'faraday_middleware'
require 'hashie'

class Appfigures
  class Connection < Faraday::Connection
    def initialize(options = {})
      super('https://api.appfigures.com/v2/') do |conn|
        conn.request :json
        conn.response :json, :content_type => /\bjson$/
        conn.response :raise_error
        conn.adapter Faraday.default_adapter
      end
      self.basic_auth options[:login], options[:password]
      self.headers['X-Client-Key'] = options[:client_key]
    end
  end
end
