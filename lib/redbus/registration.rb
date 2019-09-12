module Redbus
  class Registration

    # ########
    # Endpoints are for direct message requests. Such as "tell the mail-sender to send an email"

    # The default here is to register the current instance's config'd endpoint - which will be
    # the case most of the time.
    def self.register_endpoint(name = "@#{Redbus.endpoint}")
      $redis.set("endpoints:#{name}", Time.now)
    end

    # TODO: self.unregister_endpoint(name = "@#{Redbus.endpoint}")

    # This returns a list of the endpoint keys
    def self.registered_endpoints
      $redis.keys("endpoints:*").map{ |ep| key_to_endpoint(ep) }
    end

    # This is a hash which includes the timestamp the endpoint was registered at
    def self.endpoint_registrations
      result = {}
      $redis.keys("endpoints:*").map{ |ep| result[key_to_endpoint(ep)] = $redis.get(ep) }
      return result
    end

    # ########
    # Interests are for fan-out receipt of things a service may be interested in.
    # For instance "I want to know when something happens to Users"

    def self.register_interest(name)
      $redis.set("interests:#{name}:#{Redbus.endpoint}", Time.now)
    end

    # This returns a list of the interests keys
    def self.registered_interests
      $redis.keys("interests:*:#{Redbus.endpoint}").map{ |ep| key_to_interest(ep) }
    end

    # This is a hash which includes the timestamp the interests was registered at
    def self.interest_registrations
      result = {}
      $redis.keys("interests:*:#{Redbus.endpoint}").map{ |ep| result[key_to_interest(ep)] = $redis.get(ep) }
      return result
    end

    # ########
    # Gather up all the registered things as a key list for BLPOP
    #
    # Note that the interests create different channels for each endpoint. So if your endpoint is "foo",
    # and you're registering interest in "bar", the channel will be "#foo_bar".

    def self.subscribe_list
      endpoints = registered_endpoints
      interests = registered_interests.map { |k| "#{k}_#{Redbus.endpoint}" }

      return(endpoints + interests)
    end

    # ########
    # Build the fan-out list to LPUSH to for an interest
    def self.fanout_list(channel)
      interests = registered_interests.map { |k| "#{k}_#{Redbus.endpoint}" }

      interests = $redis.keys("interests:#{channel}:*") #.map{ |ep| result[key_to_interest(ep)] = $redis.get(channel) }
      interests = interests.map { |k| k.gsub("interests:", "").gsub("#{channel}:", "#{channel}_") }

      return(interests)
    end

    # Utils

    def self.clear_registrations
      $redis.keys("endpoints:*").each{ |k| $redis.del(k) }
      $redis.keys("interests:*").each{ |k| $redis.del(k) }
    end

    def self.key_to_endpoint(k)
      k.to_s.gsub('endpoints:', '')
    end

    def self.key_to_interest(k)
      k.to_s.gsub('interests:', '').gsub(":#{Redbus.endpoint}", '')
    end

  end
end
