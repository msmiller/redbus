# This is for pub/sub and wait with specific messages

module Redbus
  class Pubsub

    # Fire-and-forget publish
    def self.publish(channels, data)
      channels.gsub(/\s+/, "").split(',').each do |c|
        $pubredis.publish c, data.to_json
      end
    end

    # Synchronous subscribe
    def self.subscribe(channels, callback=nil)
      $subredis.subscribe(channels) do |on|
        on.message do |channel, msg|
          data = JSON.parse(msg)
          if callback.nil?
            dump_message(channel, msg)
          else
            eval("#{callback}(channel, msg)")
          end
        end
      end
    end

    # Synchronous psubscribe
    def self.psubscribe(pattern, callback=nil)
      $subredis.psubscribe(pattern) do |on|
        on.pmessage do |pattern, channel, msg|
          data = JSON.parse(msg)
          if callback.nil?
            dump_message(channel, msg)
          else
            eval("#{callback}(channel, msg)")
          end
        end
      end
    end

  end
end
