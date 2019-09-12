# This is for pub/sub and wait with specific messages

module Redbus
  class Registration

    def self.register_endpoint
      $subredis.ltrim(channel, 1, -1)
    end

  end
end
