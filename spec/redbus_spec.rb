require 'redis'
require 'awesome_print'
require 'redbus'

RSpec.describe Redbus do

  before :each do
    @current_redbus = RedisBus.new('test1', nil)
  end

  context "gem config" do

    it "has a version number and cache key" do
      expect(Redbus::VERSION).not_to be nil
      expect(Redbus::CACHETHRU_KEY_ROOT).not_to be nil
    end

    it "can initialize" do
      expect(@current_redbus.endpoint).to eq('test1')
      expect(@current_redbus.timeout).to eq(5)
      expect( @current_redbus.topology_cfg ).to eq( nil )
    end

    it "can change settings" do
      expect(@current_redbus.endpoint).to eq('test1')
      expect(@current_redbus.timeout).to eq(5)
      expect( @current_redbus.topology_cfg ).to eq( nil )

      @other_redbus = RedisBus.new('test1', nil, nil)
      @other_redbus.poll_delay = 123
      @other_redbus.timeout = 456
      expect(@other_redbus.poll_delay).to eq(123)
      expect(@other_redbus.timeout).to eq(456)
    end

  end # gem config

#  context "PUBLISH_MODE pass through (Redbus.pubish, ...)" do
#
#    it "can publish to a channel" do
#      expect($pubredis.llen("@test")).to eq(0)
#      Redbus.publish( "@test", { "foo" => "bar" } )
#      expect($pubredis.llen("@test")).to eq(1)
#    end
#
#    it "can subscribe_once" do
#      Redbus.publish( "@test", { "foo" => "bar" } )
#      Redbus.subscribe_once( "@test", "Kallback::stash" )
#    end
#
#  end # gem config


end

