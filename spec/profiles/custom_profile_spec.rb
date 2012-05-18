require File.dirname(__FILE__) + "/../spec_helper"

class CustomProfile
  include Preflight::Profile

  profile_name "custom"

  rule Preflight::Rules::MaxVersion, 1.3
end

class PpiProfile
  include Preflight::Profile

  warning Preflight::Rules::MinPpi, 200
  error Preflight::Rules::MinPpi, 150
end

describe "Customised profile" do

  it "fail files with a higher version" do
    filename = pdf_spec_file("version_1_4")
    preflight = CustomProfile.new
    messages  = preflight.check(filename)

    messages.should_not be_empty
  end

  it "pass files with an equal version" do
    filename  = pdf_spec_file("version_1_3")
    preflight = CustomProfile.new
    messages  = preflight.check(filename)

    messages.should == EMPTY_PROFILE_MESSAGES
  end

  it "fail files with a low ppi" do
    filename = pdf_spec_file("72ppi")
    preflight = PpiProfile.new

    messages  = preflight.check(filename)

    messages.should_not be_empty
  end

  it "pass files with high ppi" do
    filename  = pdf_spec_file("300ppi")
    preflight = PpiProfile.new
    messages  = preflight.check(filename)

    messages.should == EMPTY_PROFILE_MESSAGES
  end

end
