require 'redis'
require 'awesome_print'

RSpec.describe Redbus do

  before :each do
  end

  context "gem config" do

    it "has a version number" do
      expect(Redbus::VERSION).not_to be nil
    end

    it "can load default config" do
      expect(Redbus.timeout).to eq(5)
    end

    it "can set default config" do
      old_enpoint = Redbus.endpoint
      Redbus.endpoint = "foobar"
      expect(Redbus.endpoint).to eq("foobar")
      Redbus.endpoint = old_enpoint
      expect(Redbus.endpoint).to eq(old_enpoint)
    end

  end # gem config

  context "PUBLISH_MODE pass through (Redbus.pubish, ...)" do

    it "can publish to a channel" do
      expect($pubredis.llen("@test")).to eq(0)
      Redbus.publish( "@test", { "foo" => "bar" } )
      expect($pubredis.llen("@test")).to eq(1)
    end

    it "can subscribe_once" do
      Redbus.publish( "@test", { "foo" => "bar" } )
      Redbus.subscribe_once( "@test", "Kallback::stash" )
    end

  end # gem config


end

