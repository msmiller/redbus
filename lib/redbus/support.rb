module Redbus
  class Support

    def self.rpc_token
      "rpc." + SecureRandom.urlsafe_base64(nil, false)
    end

    #### Registering endpoints when services boot up

    def self.register_endpoint(name)
      $redis.set("endpoints:#{name}", Time.now)
    end

    def self.registered_endpoints
      $redis.keys("endpoints:*").map{ |ep| ep.gsub('endpoints:', '@') }
    end

    def self.endpoint_registrations
      result = {}
      $redis.keys("endpoints:*").map{ |ep| result[ep.gsub('endpoints:', '@')] = $redis.get(ep) }
      return result
    end

    #### Utility

    def self.dump_message(channel, msg)
      data = JSON.parse(msg)
      p "-=> ##{channel}: (#{data.length})"
      p "-=> #{data.inspect}"
    end

  end
end
