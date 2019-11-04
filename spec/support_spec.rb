require 'redis'
require 'awesome_print'

RSpec.describe RedBus do

  before :each do
  end

  context "support functions" do

    it "can generate a rpc_token" do
      expect(RedBus::rpc_token).to_not be nil
    end

  end # support functions

end

