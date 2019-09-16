require 'redis'
require 'awesome_print'

RSpec.describe Redbus::Lpubsub do

  before :each do
    Kallback.reset_globals
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

    it "can subscribe_async" do
      # Register the endpoints
      Redbus::Registration.register_endpoint("@test1")
      Redbus::Registration.register_endpoint("@test2")
      Redbus::Registration.register_endpoint("@EXIT")

      # Publish some data, including the exit message
      Redbus::Lpubsub.publish( "@test1",  { "foo" => "bar" } )
      Redbus::Lpubsub.publish( "@test2", { "ack" => "oop" } )
      Redbus::Lpubsub.publish( "@EXIT", {  } )

      expect($pubredis.llen("@test1")).to eq(1)
      expect($pubredis.llen("@test2")).to eq(1)
      expect($pubredis.llen("@EXIT")).to eq(1)
      # GO!
      Redbus::Lpubsub.subscribe_async( Redbus::Registration.subscribe_list, "Kallback::stash" )
      # DONE!
      sleep(0.1)
      expect($pubredis.llen("@test1")).to eq(0)
      expect($pubredis.llen("@test2")).to eq(0)
      expect($pubredis.llen("@EXIT")).to eq(0)

      # expect(result).not_to be nil
      # json_result = JSON.parse(result)
      # expect(json_result['foo']).to eq('bar')
    end

  end # lpubsub

end

