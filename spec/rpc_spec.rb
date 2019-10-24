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

=begin
    # Mockredis will return nil right away if list empty
    it "can handle subscribe timeout" do
      expect($pubredis.llen("@test")).to eq(0)
      result = Redbus::Lpubsub.subscribe_once( "@test", "Kallback::stash" )
      expect(result).to be nil
    end

    it "can subscribe_async to endpoints" do
      # Register the endpoints
      Redbus::Registration.register_endpoint("@test1")
      Redbus::Registration.register_endpoint("@test2")
      Redbus::Registration.register_endpoint("@EXIT")

      # Publish some data, including the exit message
      Redbus::Lpubsub.publish( "@test1",  { "foo" => "bar" } )
      Redbus::Lpubsub.publish( "@test2", { "ack" => "oop" } )

      expect($pubredis.llen("@test1")).to eq(1)
      expect($pubredis.llen("@test2")).to eq(1)
      expect($pubredis.llen("@EXIT")).to eq(0)
      # This needs a delay so that the @EXIT is handled right
      Thread.new do
        sleep(0.25)
        Redbus::Lpubsub.publish( "@EXIT", {  } )
      end
      # GO!
      Redbus::Lpubsub.subscribe_async( Redbus::Registration.subscribe_list, "Kallback::stashstack" )
      # DONE! (after @EXIT processed)
      sleep(0.50)
      expect($pubredis.llen("@test1")).to eq(0)
      expect($pubredis.llen("@test2")).to eq(0)
      expect($pubredis.llen("@EXIT")).to eq(0)

      # Now lets check the results ...
      expect(Kallback.stash_stack.length).to eq(3)
      expect(Kallback.stash_stack[0][0]).to eq("@test1")
      expect(Kallback.stash_stack[1][1]["ack"]).to eq("oop")
    end

    it "can subscribe_async to interests" do
      # Register the endpoints
      Redbus::Registration.register_endpoint("@EXIT")
      Redbus::Registration.register_interest("#users")
      Redbus::Registration.register_interest("#accounts")

      # Publish some data, including the exit message
      Redbus::Lpubsub.publish( "#users",  { "foo" => "bar" } )
      Redbus::Lpubsub.publish( "#accounts", { "ack" => "oop" } )
      expect($pubredis.llen("#users_#{Redbus.endpoint}")).to eq(1)
      expect($pubredis.llen("#accounts_#{Redbus.endpoint}")).to eq(1)

      # We need to put a delay on the @EXIT command or it'll rip through so fast it errors out
      Thread.new do
        sleep(0.25)
        Redbus::Lpubsub.publish( "@EXIT", {  } )
      end

      Redbus::Lpubsub.subscribe_async( Redbus::Registration.subscribe_list, "Kallback::stashstack" )
      # DONE! - wait a tick to let everything catch up
      sleep(0.50)

      # p $pubredis.llen("#users_#{Redbus.endpoint}")
      # p $pubredis.llen("#accounts_#{Redbus.endpoint}")
      # p $pubredis.llen("@EXIT")

      expect($pubredis.llen("#users_#{Redbus.endpoint}")).to eq(0)
      expect($pubredis.llen("#accounts_#{Redbus.endpoint}")).to eq(0)
      expect($pubredis.llen("@EXIT")).to eq(0)

      # Now lets check the results ...
      expect(Kallback.stash_stack.length).to eq(3)
      expect(Kallback.stash_stack[0][0]).to eq("#users_#{Redbus.endpoint}")
      expect(Kallback.stash_stack[1][1]["ack"]).to eq("oop")
    end
=end
  end # lpubsub

end

