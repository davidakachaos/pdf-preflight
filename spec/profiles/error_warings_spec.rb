require File.dirname(__FILE__) + "/../spec_helper"

class InstanceRuleProfile
  include Preflight::Profile

  profile_name "custom"
end

describe "Test profile to accept errors and warnings" do
  subject { InstanceRuleProfile }
  it { should respond_to(:error) }
  it { should respond_to(:warning) }

  subject { InstanceRuleProfile.new }
  it { should respond_to(:error) }
  it { should respond_to(:warning) }
  it { should respond_to(:check) }

end
