require 'redis'
require 'awesome_print'

class Frodus
  def id
    5678
  end

  def to_json
    { id: 5678, ack: 'oop', foo: 'bar' }.to_json
  end
end

RSpec.describe RedBus do

  LPUBSUB_SPEC_DEBUG_ON = false

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

    @current_redbus.gather_stats = true

    @the_year = Time.now.year
    @the_month = Time.now.month
  end

  context "active stats collection" do

    it "can collect stats for publish to a channel" do
      @current_redbus.publish( "@test", { "foo" => "bar" } )
      @current_redbus.publish( "@test", { "foo" => "bar" } )

      counts = @current_redbus.counts_for( "@test" )
      expect( counts['published'] ).to_not be(nil)
      expect( counts['published'][@the_year] ).to_not be(nil)
      expect( counts['published'][@the_year][@the_month] ).to eq(2)

      @current_redbus.publish( "#interest1",  { "foo" => "bar" } )
      @current_redbus.publish( "#interest2", { "ack" => "oop" } )

      counts = @current_redbus.counts_for( "#interest1_test1" )
      expect( counts['published'][@the_year][@the_month] ).to eq(1)

      counts = @current_redbus.counts_for( "#interest2_test1" )
      expect( counts['published'][@the_year][@the_month] ).to eq(1)

      counts = @current_redbus.counts_for( "#interest2_test2" )
      expect( counts['published'][@the_year][@the_month] ).to eq(1)
    end

    it "can collect stats for subscribe_once" do
      @current_redbus.publish( "@test", { "foo" => "bar" } )
      result = @current_redbus.subscribe_once( "@test", "Kallback::stash" )

      counts = @current_redbus.counts_for( "@test" )
      expect( counts['published'][@the_year][@the_month] ).to eq(1)
      expect( counts['processed'][@the_year][@the_month] ).to eq(1)
    end

    it "can collect stats for subscribe_async to endpoints" do
      # Publish some data, including the exit message
      @current_redbus.publish( "@test1", { "foo" => "bar" } )
      @current_redbus.publish( "@test1", { "ack" => "oop" } )

      Thread.new do
        sleep(0.1)
        @current_redbus.publish( "@EXIT", {  } )
      end
      # GO!
      @current_redbus.subscribe_async( (@current_redbus.subscribe_list + ['@EXIT']), true, "Kallback::stashstack" )
      # DONE! (after @EXIT processed)
      sleep(0.2)
      
      counts = @current_redbus.counts_for( "@test1" )
      expect( counts['published'][@the_year][@the_month] ).to eq(2)
      expect( counts['processed'][@the_year][@the_month] ).to eq(2)
    end

    it "can collect stats for a basic RPC call" do

      # Arm the RPC send
      rpc_result = nil
      sub_result = nil
      Thread.new do
        sleep(0.1)
        rpc_result = @current_redbus.publish_rpc( "@test1", { "foo" => "bar" } )
      end

      chan, mesg = @current_redbus.subredis.blpop("@test1") #, :timeout => Redbus.timeout)
      if mesg
        data = JSON.parse(mesg)
        sub_result = data
        @current_redbus.pubredis.publish data['rpc_token'], { ack: 'oop' }.to_json
      end
      sleep(0.25)

      counts = @current_redbus.counts_for( "rpc" )
      expect( counts['published'][@the_year][@the_month] ).to eq(1)
      expect( counts['processed'][@the_year][@the_month] ).to eq(1)

      counts = @current_redbus.counts_for( "@test1" )
      expect( counts['published'][@the_year][@the_month] ).to eq(1)
      expect( counts['processed'][@the_year][@the_month] ).to eq(1)
    end


    it "can collect stats for getting an object across an rpc request" do

      # Arm the cachethru send
      cachethru_result = nil
      Thread.new do
        # Wait 1/10th of a second so the responder can spin up
        sleep(0.1)
        cachethru_result = @current_redbus.retrieve( 'Frodus', 5678, "@test1" )
      end

      # This will handle the rpc request and send back data
      chan, mesg = @current_redbus.subredis.blpop("@test1") #, :timeout => Redbus.timeout)
      if mesg
        data = JSON.parse(mesg)
        sub_result = data
        f = Frodus.new
        @current_redbus.deposit(f, data['rpc_token'])
      end

      # Wait a beat to let the threads unwind. This won't be needed in the wild, but since
      # we're running tests locally it's so blazingly fast it creates race condition
      sleep(0.25)

      counts = @current_redbus.counts_for( "rpc" )
      expect( counts['published'][@the_year][@the_month] ).to eq(1)
      expect( counts['processed'][@the_year][@the_month] ).to eq(1)
    end

  end

end

