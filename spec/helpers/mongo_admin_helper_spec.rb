require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MongoAdminHelper do
  
  describe "generate_grid_columns" do
    it "should generate a list of columns for the specified klass" do
      cols = helper.generate_grid_columns(Announce)
      expected = [{ :field => 'id', :label => 'ID', :sortable => true },
       { :field => 'price', :label => 'price', :editable => true, :sortable => true },
       { :field => 'title', :label => 'title', :editable => true, :sortable => true },
       { :field => 'published', :label => 'published', :editoptions => { :value => [['true','yes'],['false','no']] }, 
         :editable => true, :edittype => 'select', :sortable => true },
       { :field => 'year', :label => 'year', :editable => true, :sortable => true },
       { :field => 'created_at', :label => 'created_at', :editable => true, :sortable => true }]
      cols.should == expected
    end
    
    describe "with an EmbeddedDocument" do
      it "should generate non-sortable columns" do
        cols = helper.generate_grid_columns(Picture)
        expected = [{ :field => 'id', :label => 'ID', :sortable => false },
                    { :field => 'name', :label => 'name', :sortable => false, :editable => true }]
        cols.should == expected
      end
    end
    
    describe "when using in a master-details relationship" do
      it "should not include foreign keys" do
        cols = helper.generate_grid_columns(Offer, Announce)
        expected = [{ :field => 'id', :label => 'ID', :sortable => true },
                    { :field => 'price', :label => 'price', :sortable => true, :editable => true }]
        cols.should == expected
      end
    end
  end

end
