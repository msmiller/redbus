#!/usr/bin/ruby
# @Author: msmiller
# @Date:   2019-09-16 14:10:55
# @Last Modified by:   msmiller
# @Last Modified time: 2019-10-28 18:39:22
#
# Copyright (c) Sharp Stone Codewerks / Mark S. Miller

# This is for pub/sub and wait with specific messages

module Redbus
  class Lpubsub

    def self.clear_channel(channel)
      $subredis.ltrim(channel, 1, -1)
    end

    # Fire-and-forget publish
    def self.publish(channels, data)
      channel_list = []
      channels.gsub(/\s+/, "").split(',').each do |c|
        # If it's an interest, publish to fan-out list
        if c.include? '#'
          channel_list += Redbus::Registration.fanout_list(c)
p "FANOUT LIST: #{channel_list}"
        else
          channel_list += [ c ]
        end
      end
      channel_list.each do |c|
        $pubredis.lpush c, data.to_json
      end
    end

    # Synchronous subscribe to one channel for one message
    # This will mainly be used for RPC functionality
    def self.subscribe_once(channel, callback=nil)
      if callback
        klass,methud = Redbus::Support.parse_callback(callback)
        return false if methud.nil?
      end
      chan,msg = $subredis.blpop(channel, :timeout => Redbus.timeout)
      if msg.nil?
        # TIMEOUT - msg will be nil
      else
        data = JSON.parse(msg)
        if callback.nil?
          Redbus::Support.dump_message(channel, msg)
        else
          klass.send(methud, chan, JSON.parse(msg))
        end
      end
      return msg
    end

    # Outer function for async subscribe so it can be run as either a thread inside a Rails server
    # or as a standalone daemon launched from the shell
    #
    # Usage: Redbus.subscribe_async(Redbus::Registration.subscribe_list, true/false, Class::callback)
    def self.subscribe_async(channels, threaded=true, callback=nil)
      if callback
        klass,methud = Redbus::Support.parse_callback(callback)
        return false if methud.nil?
      end

      if threaded
        Thread.new do
          do_subscribe_async(channels, true, callback)
        end
      else
        p "INLINE START"
        do_subscribe_async(channels, false, callback)
        p "INLINE DONE"
      end
    end

    # This is the main subscribe loop
    def self.do_subscribe_async(channels, threaded=true, callback=nil)
p "DO_SUBSCRIBE_ASYNC(#{channels}, #{threaded}, #{callback})"
      klass,methud = Redbus::Support.parse_callback(callback)
      while(true)
        # chan,msg = $subredis.blpop(channels, :timeout => 5)
        begin
          chan,msg = $subredis.blpop(channels, :timeout => Redbus.poll_delay)
p "CHAN: #{chan}"
p "MESG: #{msg}"
          if msg.nil?
            # TIMEOUT - msg will be nil
          else
            data = JSON.parse(msg)
            if callback.nil?
              Redbus::Support.dump_message(channel, msg)
            else
p "----> CALLING #{klass}::#{methud} for #{chan}"
              klass.send(methud, chan, JSON.parse(msg))
            end
          end
          # (sleep(Redbus.poll_delay)) if (Redbus.poll_delay > 0)

          # If we're in test mode, we need a clean way to bust out
          if ((chan == '@EXIT') && (Rails.env == 'test'))
            if threaded
              (Thread.exit) 
            else
              break
            end
          end
        rescue
        end
      end # while(true)
    end

    # Shortcut to subscribe to everything registered
    def self.subscribe_all(callback=nil)
      Redbus.subscribe_async(Redbus::Registration.subscribe_list, callback)
    end

  end
end
