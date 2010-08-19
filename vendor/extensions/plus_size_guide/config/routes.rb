# Put your extension routes here.

#map.psg '/psg', :controller => 'plussizeguide', :action => 'index'
map.resources :plussizeguide, :controller => 'plussizeguide', :only => [:index]
# map.namespace :admin do |admin|
#   admin.resources :whatever
# end  
