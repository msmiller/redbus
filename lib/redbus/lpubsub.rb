# This is for pub/sub and wait with specific messages

module Redbus
  class Lpubsub

    def self.clear_channel(channel)
      $subredis.ltrim(channel, 1, -1)
    end

    # Fire-and-forget publish
    def self.publish(channels, data)
      channels.gsub(/\s+/, "").split(',').each do |c|
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

    # Usage: Redbus.subscribe_async(Redbus::Registration.subscribe_list, Class::callback)
    def self.subscribe_async(channels, callback=nil)

      if callback
        klass,methud = Redbus::Support.parse_callback(callback)
        return false if methud.nil?
      end

      Thread.new do
        while(true)
          #cp "IN WHILE"
          # chan,msg = $subredis.blpop(channels, :timeout => 5)
          chan,msg = $subredis.blpop(channels, :timeout => Redbus.timeout)
          # p "POP #{chan} #{msg}"
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
          (sleep(Redbus.poll_delay)) if (Redbus.poll_delay > 0)

          # If we're in test mode, just run once
          (Thread.exit) if (chan == '@EXIT')

        end # while(true)
      end # Thread
    end



  end
end
