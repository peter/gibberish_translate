require File.dirname(__FILE__) + '/../spec_helper'

describe Gibberish::TranslationsController do
  integrate_views  

  before(:each) do
    Gibberish::Extractor.flush_cache
  end

  ############################################################
  #
  # Index action
  #
  ############################################################

  it "index page: displays all messages paginated by default and defaults locale to the first Gibberish language" do
    get_index_page
    
    assigns(:en_messages).should == all_messages
    assigns(:translated_messages).should == translated_messages
    assigns(:keys).sort.should == all_messages.keys.sort
    assigns(:paginated_keys).sort.should == [all_messages.keys.sort.first]

    controller.send(:translation_locale).to_s.should == "se"
    
    response.should have_tag("table\#messages > tr", 2)
    
    response.should_not have_text("welcome")
    response.body.should =~ /Thanks for registering/
  end

  it "index page: can display page two of all messages" do
    get_index_page(:page => 2)

    assigns(:keys).sort.should == all_messages.keys.sort
    assigns(:paginated_keys).sort.should == [all_messages.keys.sort.last]

    response.should have_tag("table\#messages > tr", 2)

    response.body.should =~ /welcome/
    response.body.should =~ /Welcome to my homepage/    
    response.should_not have_text("register_confirm")
  end

  it "index page: can display untranslated messages" do
    get_index_page(:filter => "untranslated")
    assigns(:keys).should == ["register_confirm"]
  end
  
  it "index page: can display changed messages" do
    get_index_page(:filter => "changed")
    assigns(:keys).should == ["welcome"]
  end
  
  it "index page: can display translated messages" do
    get_index_page(:filter => "translated")
    assigns(:keys).should == ["welcome"]
  end

  it "index page: can filter by key pattern with no wildcard" do
    get_index_page(:key_pattern => "ister_conf")
    assigns(:keys).should == ["register_confirm"]
  end

  it "index page: can filter by key pattern with leading wildcard" do
    get_index_page(:key_pattern => "*confirm")
    assigns(:keys).should == ["register_confirm"]
  end

  it "index page: can filter by key pattern with trailing wildcard" do
    get_index_page(:key_pattern => "register*")
    assigns(:keys).should == ["register_confirm"]    
  end

  it "index page: can filter by key pattern with leading and trailing wildcard" do
    get_index_page(:key_pattern => "*regist*")
    assigns(:keys).should == ["register_confirm"]    
  end

  it "index page: can filter by translation pattern with stars case insensitive" do
    get_index_page(:text_pattern => "*Till min*")
    assigns(:keys).should == ["welcome"]
  end

  it "index page: can filter by translation pattern without stars" do
    get_index_page(:text_pattern => "till min")
    assigns(:keys).should == ["welcome"]
  end

  ############################################################
  #
  # Translate action
  #
  ############################################################

  it "translate action: Updates translations in the YAML file" do
    mock_se_catalog_load

    translated_messages_expect = translated_messages.merge({
      "register_confirm" => {
        :from => "Thanks for registering",
        :to => "Tack för registreringen"
      }
    })
    Gibberish::Catalog.should_receive(:dump).with("se", translated_messages_expect)

    get :translate, :register_confirm => "Tack för registreringen"

    response.should be_redirect
  end

  it "translate action: does not allow dumping translation with mis-matching variable interpolation" do
    mock_se_catalog_load    
    Gibberish::Catalog.should_not_receive(:dump)
    lambda do
      get :translate, :register_confirm => "Tack för registreringen, {user_name}!"
    end.should raise_error(RuntimeError, /variable mismatch/i)
  end

  ############################################################
  #
  # Reload action
  #
  ############################################################

  it "reload action: flushes the extractor cache" do
    Gibberish::Extractor.should_receive(:flush_cache)
    get :reload
  end

  ############################################################
  #
  # Helper methods
  #
  ############################################################
  
  def get_index_page(params = {})
    controller.stub!(:per_page).and_return(1)
    mock_se_catalog_load
    get :index, params    
  end
  
  def mock_se_catalog_load
    Gibberish.stub!(:languages).and_return(["se", "es"])
    extractor = mock(:extractor)
    extractor.should_receive(:messages).and_return(all_messages)
    Gibberish::Extractor.should_receive(:new).and_return(extractor)
    Gibberish::Catalog.should_receive(:load).with("se").and_return(translated_messages)    
  end
  
  def all_messages
    HashWithIndifferentAccess.new({
      :register_confirm => "Thanks for registering",
      :welcome => "Welcome to my homepage"
    })
  end
  
  def translated_messages
    {
      "welcome" => {
        :from => "Hello and welcome to my homepage",
        :to => "Välkommen till min hemsida"
      },
      "good_bye" => {
        :from => "Good Bye!",
        :to => "Farväl"
      }
    }
  end
end
