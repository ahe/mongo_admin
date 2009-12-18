ActionController::Routing::Routes.draw do |map|
  map.connect '/mongo_admin/post_data/:klass', :controller => 'mongo_admin', :action => 'post_data'
  map.connect '/mongo_admin/post_assoc_data/:klass', :controller => 'mongo_admin', :action => 'post_assoc_data'
end
