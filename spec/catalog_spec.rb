require File.dirname(__FILE__) + '/spec_helper'

describe Gibberish::Catalog do
  before do
    @@catalog_file = File.join(File.dirname(__FILE__), "files", "se.yml")
    Gibberish::Catalog.stub!(:file_path).and_return(@@catalog_file)
    @messages = {
      "whats_up" => {
        :from => "What's up?",
        :to => "Hur är läget?"
      },
      "not_bad" => {
        :from => "Not bad...",
        :to => "Inte illa..."
      }
    }
    @locale = "se"
    Gibberish::Extractor.stub!(:cached_messages).and_return({
      "whats_up" => "What's up dude?",
      "welcome" => "Welcome"
    })
  end

  after(:all) do
    File.delete(@@catalog_file)
  end
  
  it "can dump hash to YAML with the dump method and reproduce the data with the load method. Only dumps keys in the en locale" do
    Gibberish::Catalog.dump(@locale, @messages)
    Gibberish::Catalog.load(@locale).should == @messages.slice("whats_up")
  end
end
