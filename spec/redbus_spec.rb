require 'redis'
require 'redis-objects'
require 'awesome_print'

RSpec.describe Redbus do

  before :each do
    print " / "
  end

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
    registrations = Redbus::Support.rendpoint_registrations
    expect(registrations.length).to eq(3)
    # ap registrations
  end

end
