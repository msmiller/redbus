require 'redis'
require 'awesome_print'

RSpec.describe Redbus::Support do

  before :each do
  end

  context "support functions" do

    it "can generate a rpc_token" do
      expect(Redbus::Support.rpc_token).to_not be nil
    end

  end # support functions

end

