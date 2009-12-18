require File.dirname(__FILE__) + "/../../spec_helper"
 
describe 'mongo_admin/index' do
  
  before(:each) do
    @klasses = ['First', 'Test']
    assigns[:klasses] = @klasses
  end
  
  it 'should render' do
    do_render
  end
  
  it "should create a list of links to models" do
    do_render
    @klasses.each do |klass|
      response.should have_tag("a[href=?]", "/mongo_admin/show/#{klass}")
    end
  end
  
  def do_render
    render 'mongo_admin/index'
  end

end
