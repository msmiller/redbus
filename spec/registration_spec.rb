require 'redis'
require 'awesome_print'

RSpec.describe Redbus::Registration do

  before :each do
    $busredis.flushall
    $busredis.flushdb
  end

  context "registration functions" do

    it "can register endpoints" do
      Redbus::Registration.clear_registrations
      registrations = Redbus::Registration.endpoint_registrations
      expect(registrations.length).to eq(0)

      Redbus::Registration.register_endpoint('@webhook')
      Redbus::Registration.register_endpoint('@email')
      Redbus::Registration.register_endpoint('@sms')

      endpoints = Redbus::Registration.registered_endpoints
      # ap endpoints
      expect(endpoints.length).to eq(3)

      registrations = Redbus::Registration.endpoint_registrations
      # ap registrations
      expect(registrations.length).to eq(3)
    end

    it "can register the current endpoint" do
      Redbus::Registration.clear_registrations
      Redbus::Registration.register_endpoint
      endpoints = Redbus::Registration.registered_endpoints

      expect(endpoints.length).to eq(1)
      expect(endpoints[0]).to eq("@#{Redbus.endpoint}")
    end

    it "can register interests" do
      Redbus::Registration.clear_registrations
      registrations = Redbus::Registration.endpoint_registrations
      expect(registrations.length).to eq(0)

      Redbus::Registration.register_interest('#webhook')
      Redbus::Registration.register_interest('#email')
      Redbus::Registration.register_interest('#sms')

      interests = Redbus::Registration.registered_interests
      # ap interests
      expect(interests.length).to eq(3)

      registrations = Redbus::Registration.interest_registrations
      # ap registrations
      expect(registrations.length).to eq(3)
    end

    it "can get a subscribe list" do
      Redbus::Registration.clear_registrations
      registrations = Redbus::Registration.endpoint_registrations
      expect(registrations.length).to eq(0)

      Redbus::Registration.register_endpoint('@webhook')
      Redbus::Registration.register_endpoint('@email')
      Redbus::Registration.register_endpoint('@sms')

      Redbus::Registration.register_interest('#users')
      Redbus::Registration.register_interest('#views')

      subscribe_list = Redbus::Registration.subscribe_list
      # ap subscribe_list
      expect(subscribe_list.length).to eq(5)

    end

    it "can get a fanout list" do
      Redbus::Registration.clear_registrations
      registrations = Redbus::Registration.endpoint_registrations
      expect(registrations.length).to eq(0)

      # Rig first endpoint
      Redbus::Registration.register_endpoint('@users')
      Redbus::Registration.register_interest('#users')
      Redbus::Registration.register_interest('#views')

      # Add another endpoint's worth of stuff
      old_enpoint = Redbus.endpoint
      Redbus.endpoint = "foobar"
      Redbus::Registration.register_interest('#users')
      Redbus::Registration.register_interest('#views')
      Redbus.endpoint = old_enpoint

      fanout_list = Redbus::Registration.fanout_list("#users")
      # ap fanout_list
      # There should be two endpoints for #users, one for each endpoint
      expect( fanout_list.length ).to eq( 2 )
      expect( fanout_list ).to include( "#users_foobar" )
      expect( fanout_list ).to include( "#users_#{old_enpoint}" )

    end

  end # registration functions

end

