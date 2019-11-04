#!/usr/bin/ruby
# @Author: msmiller
# @Date:   2019-09-12 13:49:17
# @Last Modified by:   msmiller
# @Last Modified time: 2019-11-04 10:54:15
#
# Copyright (c) Sharp Stone Codewerks / Mark S. Miller

module Redbus

  class RedisBus

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
