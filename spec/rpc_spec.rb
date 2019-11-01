require 'redis'
require 'awesome_print'

RSpec.describe RedisBus do

  DEBUG_ON = false

  before :each do
    Kallback.reset_globals

    setup_test_bus
    @current_redbus.busredis.flushall
    @current_redbus.busredis.flushdb
    @yaml_data = YAML.load( File.read( File.expand_path("../#{@yaml_file}", __FILE__) ) )
    @current_redbus.clear_channel("@test")
    @current_redbus.clear_channel("@test1")
    @current_redbus.clear_channel("@test2")
    @current_redbus.clear_channel("@EXIT")
  end

  context "rpc" do

    it "can do a basic RPC call" do

      # Arm the RPC send
      rpc_result = nil
      sub_result = nil
      Thread.new do
        # Wait 1/10th of a second so the responder can spin up
        sleep(0.1)
        rpc_result = @current_redbus.publish_rpc( "@test", { "foo" => "bar" } )
      end

      # This will handle the rpc request and send back data
      chan, mesg = @current_redbus.subredis.blpop("@test") #, :timeout => Redbus.timeout)
      if mesg
        p "RESPONDING TO: #{chan}, #{mesg} ..." if DEBUG_ON
        data = JSON.parse(mesg)
        sub_result = data
        @current_redbus.pubredis.publish data['rpc_token'], { ack: 'oop' }.to_json
        p "... SENT!" if DEBUG_ON
      end

      if DEBUG_ON
        p "----"
        p "sub_result:"
        ap sub_result
        p "rpc_result:"
        ap rpc_result
        p "----"
      end

      # Wait a beat to let the threads unwind. This won't be needed in the wild, but since
      # we're running tests locally it's so blazingly fast it creates race condition
      sleep(0.25)

      expect(rpc_result).not_to be nil
      expect(rpc_result['ack']).to eq('oop')
    end

  end # lpubsub

end

