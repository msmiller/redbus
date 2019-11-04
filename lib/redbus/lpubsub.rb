#!/usr/bin/ruby
# @Author: msmiller
# @Date:   2019-09-16 14:10:55
# @Last Modified by:   msmiller
# @Last Modified time: 2019-11-04 11:50:41
#
# Copyright (c) Sharp Stone Codewerks / Mark S. Miller

# This is for pub/sub and wait with specific messages

module Redbus

  class RedisBus

    LPUBSUB_DEBUG_ON = false

    def clear_channel(channel)
      self.subredis.ltrim(channel, 1, -1)
    end

    # Fire-and-forget publish
    def publish(channels, data)
      p "PUBLISH #{channels} / #{data}" if LPUBSUB_DEBUG_ON
      channel_list = []
      channels.gsub(/\s+/, "").split(',').each do |c|
        # If it's an interest, publish to fan-out list
        if c.include? '#'
          channel_list += self.fanout_list(c)
          p "FANOUT LIST: #{channel_list}" if LPUBSUB_DEBUG_ON
        else
          channel_list += [ c ]
        end
      end
      channel_list.each do |c|
        self.pubredis.lpush c, data.to_json
        self.bump(c, 'published')
      end
    end

    # Synchronous subscribe to one channel for one message
    # This will mainly be used for RPC functionality
    def subscribe_once(channel, callback=nil)
      if callback
        klass,methud = RedisBus::parse_callback(callback)
        return false if methud.nil?
      end
      chan,msg = self.subredis.blpop(channel, :timeout => self.timeout)
      if msg.nil?
        # TIMEOUT - msg will be nil
      else
        data = JSON.parse(msg)
        if callback.nil?
          RedisBus::dump_message(channel, msg)
        else
          klass.send(methud, chan, JSON.parse(msg))
        end
      end
      self.bump(chan, 'processed')
      return msg
    end

    # Outer function for async subscribe so it can be run as either a thread inside a Rails server
    # or as a standalone daemon launched from the shell
    #
    # Usage: Redbus.subscribe_async(Redbus::Registration.subscribe_list, true/false, Class::callback)
    def subscribe_async(channels, threaded=true, callback=nil)
      if callback
        klass,methud = RedisBus::parse_callback(callback)
        return false if methud.nil?
      end

      if threaded
        Thread.new do
          p "THREAD START" if LPUBSUB_DEBUG_ON
          do_subscribe_async(channels, true, callback)
          p "THREAD DONE" if LPUBSUB_DEBUG_ON
        end
      else
        p "INLINE START" if LPUBSUB_DEBUG_ON
        do_subscribe_async(channels, false, callback)
        p "INLINE DONE" if LPUBSUB_DEBUG_ON
      end
    end

    # This is the main subscribe loop
    def do_subscribe_async(channels, threaded=true, callback=nil)
      p "DO_SUBSCRIBE_ASYNC(#{channels}, #{threaded}, #{callback})" if LPUBSUB_DEBUG_ON
      klass,methud = RedisBus::parse_callback(callback)
      p "CALLBACK: #{klass},#{methud}" if LPUBSUB_DEBUG_ON
      while(true)
        # chan,msg = self.subredis.blpop(channels, :timeout => 5)
        begin
          chan,msg = self.subredis.blpop(channels, :timeout => self.poll_delay)
          p "CHAN: #{chan}" if LPUBSUB_DEBUG_ON
          p "MESG: #{msg}" if LPUBSUB_DEBUG_ON
          if msg.nil?
            # TIMEOUT - msg will be nil
          else
            data = JSON.parse(msg)
            if callback.nil?
              RedisBus::dump_message(channel, msg)
            else
              p "----> CALLING #{klass}::#{methud} for #{chan}" if LPUBSUB_DEBUG_ON
              klass.send(methud, chan, JSON.parse(msg))
            end
          end
          self.bump(chan, 'processed')
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
    def subscribe_all(threaded=true, callback=nil)
      Redbus.subscribe_async(Redbus::Registration.subscribe_list, threaded, callback)
    end

  end

end

