require File.dirname(__FILE__) + "/../../spec_helper"
 
describe 'mongo_admin/show' do
  
  before(:each) do
    @klass = Announce
    assigns[:klass] = @klass
  end
  
  it 'should render' do
    do_render
  end
  
  def do_render
    render 'mongo_admin/show'
  end

end
