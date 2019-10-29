require 'redis'
require 'awesome_print'

RSpec.describe Redbus::Lpubsub do

  before :each do
    $busredis.flushall
    $busredis.flushdb
    Kallback.reset_globals
    # Redbus.timeout = 1
    Redbus::Lpubsub.clear_channel("@test")
    Redbus::Lpubsub.clear_channel("@test1")
    Redbus::Lpubsub.clear_channel("@test2")
    Redbus::Lpubsub.clear_channel("@EXIT")
  end

  context "lpubsub" do

    it "can publish to a channel" do
      expect($pubredis.llen("@test")).to eq(0)
      Redbus::Lpubsub.publish( "@test", { "foo" => "bar" } )
      expect($pubredis.llen("@test")).to eq(1)
    end

    it "can publish to a channel-list" do
      expect($pubredis.llen("@test1")).to eq(0)
      expect($pubredis.llen("@test2")).to eq(0)
      Redbus::Lpubsub.publish( "@test1,@test2", { "foo" => "bar" } )
      Redbus::Lpubsub.publish( "@test1,@test2", { "ack" => "oop" } )
      Redbus::Lpubsub.publish( "@test", { "foo" => "bar" } )
      expect($pubredis.llen("@test1")).to eq(2)
      expect($pubredis.llen("@test2")).to eq(2)
    end

    it "can subscribe_once" do
      Redbus::Lpubsub.publish( "@test", { "foo" => "bar" } )
      result = Redbus::Lpubsub.subscribe_once( "@test", "Kallback::stash" )
      expect(result).not_to be nil
      json_result = JSON.parse(result)
      expect(json_result['foo']).to eq('bar')
    end

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

      expect($pubredis.llen("@EXIT")).to eq(0)
      expect($pubredis.llen("@test1")).to eq(1)
      expect($pubredis.llen("@test2")).to eq(1)
      # This needs a delay so that the @EXIT is handled right
      Thread.new do
        sleep(0.1)
        Redbus::Lpubsub.publish( "@EXIT", {  } )
      end
      # GO!
      Redbus::Lpubsub.subscribe_async( Redbus::Registration.subscribe_list, true, "Kallback::stashstack" )
      # DONE! (after @EXIT processed)
      sleep(0.2)
      expect($pubredis.llen("@test1")).to eq(0)
      expect($pubredis.llen("@test2")).to eq(0)
      expect($pubredis.llen("@EXIT")).to eq(0)

      # Now lets check the results ...
      ap Kallback.stash_stack
      expect(Kallback.stash_stack.length).to eq(3)
      test1_stash = Kallback.stash_stack.select{ |x| x[0] == '@test1'}.first
      expect(test1_stash).to_not be(nil)
      expect(test1_stash[1]["foo"]).to eq("bar")
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

p Redbus::Registration.fanout_list('#users')
p Redbus::Registration.fanout_list('#accounts')


      # We need to put a delay on the @EXIT command or it'll rip through so fast it errors out
      Thread.new do
        sleep(0.1)
        Redbus::Lpubsub.publish( "@EXIT", {  } )
      end

      Redbus::Lpubsub.subscribe_async( Redbus::Registration.subscribe_list, true, "Kallback::stashstack" )
      # DONE! - wait a tick to let everything catch up
      sleep(0.2)

      # p $pubredis.llen("#users_#{Redbus.endpoint}")
      # p $pubredis.llen("#accounts_#{Redbus.endpoint}")
      # p $pubredis.llen("@EXIT")

      expect($pubredis.llen("#users_#{Redbus.endpoint}")).to eq(0)
      expect($pubredis.llen("#accounts_#{Redbus.endpoint}")).to eq(0)
      expect($pubredis.llen("@EXIT")).to eq(0)

      # Now lets check the results ...
      users_stash = Kallback.stash_stack.select{ |x| x[0] == "#users_#{Redbus.endpoint}"}.first
      expect(users_stash).to_not be(nil)
      expect(users_stash[1]["foo"]).to eq("bar")
    end

    it "can subscribe_async in inline mode" do
      # Register the endpoints
      Redbus::Registration.register_endpoint("@test1")
      Redbus::Registration.register_endpoint("@test2")
      Redbus::Registration.register_endpoint("@EXIT")

      # Publish some data, including the exit message
      Redbus::Lpubsub.publish( "@test1",  { "foo" => "bar" } )
      Redbus::Lpubsub.publish( "@test2", { "ack" => "oop" } )
      # This needs a delay so that the @EXIT is handled right
      Thread.new do
        sleep(1)
        Redbus::Lpubsub.publish( "@EXIT", {  } )
      end

      # GO!
      Redbus::Lpubsub.subscribe_async( Redbus::Registration.subscribe_list, false, "Kallback::stashstack" )
      # DONE! (after @EXIT processed)
      expect($pubredis.llen("@test1")).to eq(0)
      expect($pubredis.llen("@test2")).to eq(0)
      expect($pubredis.llen("@EXIT")).to eq(0)

      # Now lets check the results ... should be the same as the endpoints test
      ap Kallback.stash_stack
      expect(Kallback.stash_stack.length).to eq(3)
      test1_stash = Kallback.stash_stack.select{ |x| x[0] == '@test1'}.first
      expect(test1_stash).to_not be(nil)
      expect(test1_stash[1]["foo"]).to eq("bar")
    end
  end # lpubsub

end

