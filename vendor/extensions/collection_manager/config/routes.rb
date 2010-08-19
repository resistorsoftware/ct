# Put your extension routes here.
#map.resources :collections, :controller => 'collections', :member => {:tires => :get, :wheels => :get}
map.psg_search '/collections', :controller => 'collections', :action => 'show'   
# map.namespace :admin do |admin|
#   admin.resources :whatever
# end  
