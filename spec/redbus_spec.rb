require 'redis'
require 'redis-objects'
require 'awesome_print'

RSpec.describe Redbus do

  before :each do
    # print " / "
  end

  context "support functions" do

    it "has a version number" do
      expect(Redbus::VERSION).not_to be nil
    end

    it "can generate a rpc_token" do
      expect(Redbus::Support.rpc_token).to_not be nil
    end

    it "can register endpoints" do
      Redbus::Support.register_endpoint('webhook')
      Redbus::Support.register_endpoint('email')
      Redbus::Support.register_endpoint('sms')
      endpoints = Redbus::Support.registered_endpoints
      expect(endpoints.length).to eq(3)
      # ap endpoints
      registrations = Redbus::Support.endpoint_registrations
      expect(registrations.length).to eq(3)
      # ap registrations
    end

  end # support functions

  context "lpubsub" do

    it "can push to a channel-list" do
      expect($pubredis.llen("test")).to eq(0)
      Redbus::Lpubsub.publish( "test", { "foo" => "bar" } )
      expect($pubredis.llen("test")).to eq(1)
      # expect(Redbus::Support.rpc_token).to_not be nil
    end



  end # lpubsub

end
