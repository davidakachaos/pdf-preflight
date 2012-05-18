require File.dirname(__FILE__) + "/../spec_helper"

describe Preflight::Profiles::PDFX1A do

  it "correctly pass a valid PDF/X-1a file that uses font subsetting" do
    filename  = pdf_spec_file("pdfx-1a-subsetting")
    preflight = Preflight::Profiles::PDFX1A.new
    messages  = preflight.check(filename)

    messages.should == EMPTY_PROFILE_MESSAGES
  end

  it "correctly pass a valid PDF/X-1a file that doesn't use font subsetting" do
    filename  = pdf_spec_file("pdfx-1a-no-subsetting")
    preflight = Preflight::Profiles::PDFX1A.new
    messages  = preflight.check(filename)

    messages.should == EMPTY_PROFILE_MESSAGES
  end

  it "correctly detect files with an incompatible version" do
    filename  = pdf_spec_file("version_1_4")
    preflight = Preflight::Profiles::PDFX1A.new
    messages  = preflight.check(filename)

    messages.should_not == EMPTY_PROFILE_MESSAGES
  end

  it "correctly detect encrypted files with a blank user password" do
    filename  = pdf_spec_file("encrypted")
    preflight = Preflight::Profiles::PDFX1A.new
    messages  = preflight.check(filename)

    messages[:rules].should eql(["Can't preflight an encrypted PDF"])
    messages[:errors].should eql(["Can't preflight an encrypted PDF"])
  end

  it "correctly detect encrypted files with a user password" do
    filename  = pdf_spec_file("encrypted_with_user_pass_apples")
    preflight = Preflight::Profiles::PDFX1A.new
    messages  = preflight.check(filename)

    messages[:rules].should eql(["Can't preflight an encrypted PDF"])
    messages[:errors].should eql(["Can't preflight an encrypted PDF"])
  end

  it "should fail files that use object streams"
  it "should fail files that use xref streams"

end
