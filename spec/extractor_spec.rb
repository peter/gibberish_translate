require File.dirname(__FILE__) + '/spec_helper'

describe Gibberish::Extractor, "- messages method:" do
  before do
    @extractor = Gibberish::Extractor.new
    @extractor.stub!(:dirs_to_search).and_return([File.join(File.dirname(__FILE__), "files", "valid")])
    @messages = @extractor.messages
  end

  it "returns empty hash if there are no files" do
    extractor = Gibberish::Extractor.new
    extractor.stub!(:dirs_to_search).and_return([File.join(File.dirname(__FILE__), "files", "empty")])
    extractor.messages.should == {}
  end
  
  it "finds messages in erb files" do
    @messages[:erb_message].should == "The ERB message"
  end

  it "finds seven messages in total" do
    @messages.keys.size.should == 7
  end

  #################################################################
  #
  # Single Quotes
  #
  #################################################################

  it "finds single quoted strings" do
    @messages[:single_quoted].should == "Single Quoted {first} {second}"
  end

  it "finds single quoted strings with newlines" do
    @messages[:single_quoted_newline].should == "Single\nQuoted"
  end  

  it "finds single quoted strings with single quotes" do
    @messages[:single_with_quotes].should == "Single with ' quotes"
  end

  #################################################################
  #
  # Double Quotes
  #
  #################################################################

  it "finds double quoted strings" do
    @messages[:double_quoted].should == "double QUOTED"    
  end
  
  it "finds double quoted strings with newlines" do
    @messages[:double_quoted_newline].should == "double
with newline"
  end
  
  it "finds double quoted strings with double quotes" do
    @messages[:double_with_quotes].should == "double With \"\nquotes"
  end

  #################################################################
  #
  # Duplicates
  #
  #################################################################
  
  it "raises an exception if there are two lookups with same key but differnt texts" do
    extractor = Gibberish::Extractor.new
    extractor.stub!(:dirs_to_search).and_return([File.join(File.dirname(__FILE__), "files", "duplicate")])
    lambda do
      extractor.messages.should == {}
    end.should raise_error(RuntimeError, /different texts/i)
  end
  
  #################################################################
  #
  # Single Quotes
  #
  #################################################################

  it "extracts reused keys" do
    @extractor.reused_keys.should == ["erb_message", "single_with_quotes"]
  end
end
