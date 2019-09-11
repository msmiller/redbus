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
    def self.subscribe_once(channel, callback=nil)
      if callback
        klass,methud = Redbus::Support.parse_callback(callback)
        return false if methud.nil?
      end
      chan,msg = $subredis.blpop(channel, :timeout => 5)

p "CHAN RESULT: #{chan} / #{chan.nil?}"
      data = JSON.parse(msg)
      if callback.nil?
        Redbus::Support.dump_message(channel, msg)
      else
        klass.send(methud, chan, JSON.parse(msg))
      end
    end

    # Synchronous subscribe to one channel
    def self.subscribe(channel, callback=nil)
p "in"
x = $subredis.blpop(channel, :timeout => 5)
ap x
      $subredis.blpop(channel, :timeout => 5) do |on|
        on.message do |channel, msg|

          data = JSON.parse(msg)
          ap data
          if callback.nil?
            Redbus::Support.dump_message(channel, msg)
          else
            eval("#{callback}(channel, msg)")
          end
        end
      end
    end

  end
end
