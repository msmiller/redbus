require 'redis'
require 'awesome_print'

RSpec.describe Redbus::Lpubsub do

  before :each do
    $redis.flushall
    $redis.flushdb
    Kallback.reset_globals
    # Redbus.timeout = 1
    Redbus::Registration.register_endpoint("@test")
    Redbus::Lpubsub.clear_channel("@test")
    Redbus::Lpubsub.clear_channel("@EXIT")
  end

  context "rpc" do

    it "can do a basic RPC call" do

      # Arm the RPC send
      rpc_result = nil
      sub_result = nil
      Thread.new do
        # Wait 1/10th of a second so the responder can spin up
        sleep(0.1)
        rpc_result = Redbus::Rpc.publish_rpc( "@test", { "foo" => "bar" } )
      end

      # This will handle the rpc request and send back data
      chan, mesg = $subredis.blpop("@test") #, :timeout => Redbus.timeout)
      if mesg
        data = JSON.parse(mesg)
        sub_result = data
        $pubredis.publish data['rpc_token'], { ack: 'oop' }.to_json
      end

      # p "----"
      # p "sub_result:"
      # ap sub_result
      # p "rpc_result:"
      # ap rpc_result
      # p "----"

      # Wait a beat to let the threads unwind. This won't be needed in the wild, but since
      # we're running tests locally it's so blazingly fast it creates race condition
      sleep(0.25)

      expect(rpc_result).not_to be nil
      expect(rpc_result['ack']).to eq('oop')
    end

  end # lpubsub

end

