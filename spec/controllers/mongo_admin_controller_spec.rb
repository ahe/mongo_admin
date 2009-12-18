require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

TEST_ID = '4b22123ef704a00198000001'

describe MongoAdminController do
  
  before(:each) do
    Dir.stub!(:chdir).and_return(["announce.rb", "offer.rb"])
  end
  
  describe "responding to GET index" do
    
    it "should generate a list of classes" do
      get :index
      assigns[:klasses].should == [Announce, Offer]
    end
    
  end
  
  describe "responding to GET show" do
    
    it "should expose the requested model as a class" do
      get :show, :id => 'announce'
      assigns[:klass].should == Announce
    end
    
    describe "treating records" do
    
      before(:each) do
        @announce = Announce.new(:title => 'test', :price => 1500, :id => TEST_ID)
        Announce.stub!(:count).and_return(1)
      end
      
      it "should generate a JSON representation of the records (_id in first position)" do
        Announce.should_receive(:paginate).and_return([@announce])
        get :show, :id => 'announce', :format => 'json', :rows => 10
        response.body.should include(%Q(["4b22123ef704a00198000001","1500.0","test","false","",""]))
      end
      
      it "should generate the correct find conditions (string)" do
        Announce.should_receive(:paginate).with(:page => '1', :per_page => '10', :conditions => { :title => /te/ }, :order => ' ').and_return([@announce])
        get :show, :id => 'announce', :format => 'json', :page => '1', :rows => '10', :_search => 'true', :title => 'te'
      end
      
      it "should generate the correct find conditions (numbers)" do
        Announce.should_receive(:paginate).with(:page => '1', :per_page => '10', :conditions => { :price => 150.3, :year => 2010 }, :order => ' ').and_return([@announce])
        get :show, :id => 'announce', :format => 'json', :page => '1', :rows => '10', :_search => 'true', :price => '150.3', :year => '2010'
      end
      
      it "should generate the correct find conditions (boolean)" do
        Announce.should_receive(:paginate).with(:page => '1', :per_page => '10', :conditions => { :published => true }, :order => ' ').and_return([@announce])
        get :show, :id => 'announce', :format => 'json', :page => '1', :rows => '10', :_search => 'true', :published => 'true'
      end
      
      it "should generate the correct find conditions (time)" do
        date_str = '2009-12-16'
        date = Date.parse(date_str)
        date_condition = { '$gt' => date.to_time, '$lt' => (date+1.day).to_time }
        Announce.should_receive(:paginate).with(:page => '1', :per_page => '10', :conditions => { :created_at => date_condition }, :order => ' ').and_return([@announce])
        get :show, :id => 'announce', :format => 'json', :page => '1', :rows => '10', :_search => 'true', :created_at => date_str
      end
      
      it "should generate the correct order condition" do
        Announce.should_receive(:paginate).with(:page => '1', :per_page => '10', :conditions => {}, :order => 'title desc').and_return([@announce])
        get :show, :id => 'announce', :format => 'json', :page => '1', :rows => '10', :sidx => 'title', :sord => 'desc'
      end
      
      it "should count the total number of records (with the condition)" do
        Announce.should_receive(:count).with({ :title => /te/ })
        get :show, :id => 'announce', :format => 'json', :page => '1', :rows => '10', :_search => 'true', :title => 'te'
      end
    end
    
  end
  
  describe "responding to GET associations" do
    
    it "should expose the requested model as a class" do
      get :associations, :id => 'announce', :format => 'json', :rows => 10
      assigns[:klass].should == Announce
    end
    
    describe "when no parent is given" do
      
      it "should render empty JSON" do
        get :associations, :id => 'announce', :format => 'json', :rows => 10
        response.body.should == %Q({"page":"","total":1,"records":"0"})
      end
      
    end
    
    describe "when parent + parent_id are given" do
      
      before(:each) do
        @offers = mock_model(Array, :size => 0, :paginate => [])        
        @announce = mock_model(Announce, :offers => @offers)
        Announce.should_receive(:find).with(TEST_ID).and_return(@announce)
      end
      
      it "should find the requested parent" do
        get :associations, :id => 'offer', :parent => 'announce', :parent_id => TEST_ID, :format => 'json', :rows => 10
      end
      
      describe "and the specified model is a Document" do
        it "should paginate the children and return the JSON" do
          @offers.should_receive(:paginate).and_return([])
          get :associations, :id => 'offer', :parent => 'announce', :parent_id => TEST_ID, :format => 'json', :rows => 10
        end
        
        it "should use the search criterias if they are set" do
          @offers.should_receive(:paginate).with(:page => '1', :per_page => '10', :conditions => { :price => 300.0 }, :order => ' ').and_return([])
          get :associations, :id => 'offer', :parent => 'announce', :parent_id => TEST_ID, :format => 'json', :page => 1, :rows => 10, :_search => 'true', :price => '300'
        end
      end
      
      describe "and the specified model is an EmbeddedDocument" do
        it "should return all embedded documents" do
          @pictures = []
          @announce.should_receive(:pictures).and_return(@pictures)
          get :associations, :id => 'picture', :parent => 'announce', :parent_id => TEST_ID, :format => 'json', :rows => 10
        end
      end
      
    end
    
  end
  
  describe "responding to POST post_data" do
    
    describe "when adding a record" do
      it "should create a new record" do
        Announce.should_receive(:create).with({:title=>'test', :price=>nil, :published=>nil, :year=>nil, :created_at=>nil})
        post :post_data, :oper => 'add', :klass => 'announce', :title => 'test'
      end
    end
    
    describe "when editing a record" do
      it "should update the specified record" do
        @announce = mock_model(Announce)
        Announce.should_receive(:find).with('5').and_return(@announce)
        @announce.should_receive(:update_attributes).with({:title=>'test', :price=>nil, :published=>nil, :year=>nil, :created_at=>nil})        
        post :post_data, :klass => 'announce', :id => '5', :title => 'test'
      end
    end
    
    describe "when deleting a record" do
      it "should destroy the specified record" do
        @announce = mock_model(Announce)
        Announce.should_receive(:find).with('5').and_return(@announce)
        @announce.should_receive(:destroy)
        post :post_data, :oper => 'del', :klass => 'announce', :id => '5'
      end
    end
    
  end
  
  describe "responding to POST post_assoc_data" do
    
    before(:each) do
      @offers = []
      @offer_1 = mock_model(Offer, :id => 1)
      @offer_2 = mock_model(Offer, :id => 2)
      @offers << @offer_1
      @offers << @offer_2      
      @announce = mock_model(Announce, :offers => @offers)
      Announce.should_receive(:find).with('5').and_return(@announce)
      @announce.should_receive(:save)
    end
    
    describe "when adding a record" do
      it "should create a new record" do
        @offer = mock_model(Offer)
        Offer.should_receive(:new).with({:price => '100'}).and_return(@offer)
        @announce.offers.should_receive(:<<).with(@offer)
        post :post_assoc_data, :oper => 'add', :klass => 'offer', :parent => 'announce', :parent_id => '5', :price => '100'
      end
    end
    
    describe "when editing a record" do
      it "should update the specified record" do
        @offer_2.should_receive(:update_attributes).with({:price => '100'})
        post :post_assoc_data, :id => '2', :klass => 'offer', :parent => 'announce', :parent_id => '5', :price => '100'
      end
    end
    
    describe "when deleting a record" do
      it "should destroy the specified record" do
        @offer = mock_model(Offer)
        Offer.should_receive(:find).with('2').and_return(@offer)
        @offer.should_receive(:destroy)
        post :post_assoc_data, :oper => 'del', :id => '2', :klass => 'offer', :parent => 'announce', :parent_id => '5', :price => '100'
      end
    end
    
  end
  
end