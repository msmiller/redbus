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

  context "lpubsub" do

    it "can publish to a channel" do
      expect(@current_redbus.pubredis.llen("@test")).to eq(0)
      @current_redbus.publish( "@test", { "foo" => "bar" } )
      expect(@current_redbus.pubredis.llen("@test")).to eq(1)
    end

    it "can publish to a channel-list" do
      expect(@current_redbus.pubredis.llen("@test1")).to eq(0)
      expect(@current_redbus.pubredis.llen("@test2")).to eq(0)
      @current_redbus.publish( "@test1,@test2", { "foo" => "bar" } )
      @current_redbus.publish( "@test1,@test2", { "ack" => "oop" } )
      @current_redbus.publish( "@test", { "foo" => "bar" } )
      expect(@current_redbus.pubredis.llen("@test1")).to eq(2)
      expect(@current_redbus.pubredis.llen("@test2")).to eq(2)
    end

    it "can subscribe_once" do
      @current_redbus.publish( "@test", { "foo" => "bar" } )
      result = @current_redbus.subscribe_once( "@test", "Kallback::stash" )
      expect(result).not_to be nil
      json_result = JSON.parse(result)
      expect(json_result['foo']).to eq('bar')
    end

    # Mockredis will return nil right away if list empty
    it "can handle subscribe timeout" do
      expect(@current_redbus.pubredis.llen("@test")).to eq(0)
      result = @current_redbus.subscribe_once( "@test", "Kallback::stash" )
      expect(result).to be nil
    end

    it "can subscribe_async to endpoints" do
      # Publish some data, including the exit message
      @current_redbus.publish( "@test1",  { "foo" => "bar" } )
      @current_redbus.publish( "@test2", { "ack" => "oop" } )

      expect(@current_redbus.pubredis.llen("@EXIT")).to eq(0)
      expect(@current_redbus.pubredis.llen("@test1")).to eq(1)
      expect(@current_redbus.pubredis.llen("@test2")).to eq(1)
      # This needs a delay so that the @EXIT is handled right
      Thread.new do
        sleep(0.1)
        @current_redbus.publish( "@EXIT", {  } )
      end
      # GO!
      @current_redbus.subscribe_async( (@current_redbus.subscribe_list + [ '@EXIT', '@test2']), true, "Kallback::stashstack" )
      # DONE! (after @EXIT processed)
      sleep(0.2)
      expect(@current_redbus.pubredis.llen("@test1")).to eq(0)
      expect(@current_redbus.pubredis.llen("@test2")).to eq(0)
      expect(@current_redbus.pubredis.llen("@EXIT")).to eq(0)

      # Now lets check the results ...
      ap Kallback.stash_stack if DEBUG_ON
      expect(Kallback.stash_stack.length).to eq(3)
      test1_stash = Kallback.stash_stack.select{ |x| x[0] == '@test1'}.first
      expect(test1_stash).to_not be(nil)
      expect(test1_stash[1]["foo"]).to eq("bar")
    end

    it "can subscribe_async to interests" do

      p "----" if DEBUG_ON
      p @current_redbus.fanout_list('interest1') if DEBUG_ON
      p @current_redbus.fanout_list('interest2') if DEBUG_ON
      p "----" if DEBUG_ON

      # Publish some data, including the exit message
      @current_redbus.publish( "#interest1",  { "foo" => "bar" } )
      @current_redbus.publish( "#interest2", { "ack" => "oop" } )
      expect(@current_redbus.pubredis.llen("#interest1_#{@current_redbus.endpoint}")).to eq(1)
      expect(@current_redbus.pubredis.llen("#interest2_#{@current_redbus.endpoint}")).to eq(1)


      # We need to put a delay on the @EXIT command or it'll rip through so fast it errors out
      Thread.new do
        sleep(0.1)
        @current_redbus.publish( "@EXIT", {  } )
      end

      @current_redbus.subscribe_async( (@current_redbus.subscribe_list + [ '@EXIT', '@test2']), true, "Kallback::stashstack" )
      # DONE! - wait a tick to let everything catch up
      sleep(0.2)

      # p @current_redbus.pubredis.llen("#interest1_#{@current_redbus.endpoint}")
      # p @current_redbus.pubredis.llen("#interest2_#{@current_redbus.endpoint}")
      # p @current_redbus.pubredis.llen("@EXIT")

      expect(@current_redbus.pubredis.llen("#interest1_#{@current_redbus.endpoint}")).to eq(0)
      expect(@current_redbus.pubredis.llen("#interest2_#{@current_redbus.endpoint}")).to eq(0)
      expect(@current_redbus.pubredis.llen("@EXIT")).to eq(0)

      # Now lets check the results ...
      p "========" if DEBUG_ON
      ap Kallback.stash_stack if DEBUG_ON
      users_stash = Kallback.stash_stack.select{ |x| x[0] == "#interest1_#{@current_redbus.endpoint}"}.first
      expect(users_stash).to_not be(nil)
      expect(users_stash[1]["foo"]).to eq("bar")
    end

    it "can subscribe_async in inline mode" do

      # Publish some data, including the exit message
      @current_redbus.publish( "@test1",  { "foo" => "bar" } )
      @current_redbus.publish( "@test2", { "ack" => "oop" } )
      # This needs a delay so that the @EXIT is handled right
      Thread.new do
        sleep(1)
        @current_redbus.publish( "@EXIT", {  } )
      end

      # GO!
      @current_redbus.subscribe_async( (@current_redbus.subscribe_list + [ '@EXIT', '@test2']), false, "Kallback::stashstack" )
      # DONE! (after @EXIT processed)
      expect(@current_redbus.pubredis.llen("@test1")).to eq(0)
      expect(@current_redbus.pubredis.llen("@test2")).to eq(0)
      expect(@current_redbus.pubredis.llen("@EXIT")).to eq(0)

      # Now lets check the results ... should be the same as the endpoints test
      ap Kallback.stash_stack if DEBUG_ON
      expect(Kallback.stash_stack.length).to eq(3)
      test1_stash = Kallback.stash_stack.select{ |x| x[0] == '@test1'}.first
      expect(test1_stash).to_not be(nil)
      expect(test1_stash[1]["foo"]).to eq("bar")
    end
  end # lpubsub

end

