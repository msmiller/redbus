require 'redis'
require 'awesome_print'

RSpec.describe Redbus::Lpubsub do

  before :each do
    Kallback.reset_globals
    Redbus::Lpubsub.clear_channel("@test")
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
      #ap Kallback.chan
      #ap Kallback.mesg
      Redbus::Lpubsub.publish( "@test", { "foo" => "bar" } )
      Redbus::Lpubsub.subscribe_once( "@test", "Kallback::stash" )
      #ap Kallback.chan
      #ap Kallback.mesg
      # Redbus::Lpubsub.subscribe_once( "@test", "Kallback::dump" )
    end

####    it "can handle subscribe timeout" do
####      ap Kallback.chan
####      ap Kallback.mesg
####      #Redbus::Lpubsub.publish( "@test", { "foo" => "bar" } )
####      expect($pubredis.llen("@test")).to eq(0)
####      ap Redbus::Lpubsub.subscribe_once( "@test", "Kallback::stash" )
####      ap Kallback.chan
####      ap Kallback.mesg
####      # Redbus::Lpubsub.subscribe_once( "@test", "Kallback::dump" )
####    end

  end # lpubsub

end

