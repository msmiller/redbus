module Redbus
  class Support

    def self.rpc_token
      "rpc." + SecureRandom.urlsafe_base64(nil, false)
    end


    # Callbacks MUST be in the form Model::method
    def self.parse_callback(s)
      meth = s.demodulize
      klass = s.deconstantize
      return [klass.constantize, meth]
    end

    #### Utility

    def self.dump_message(channel, msg)
      data = JSON.parse(msg)
      p "-=> ##{channel}: (#{data.length})"
      p "-=> #{data.inspect}"
    end

  end
end
