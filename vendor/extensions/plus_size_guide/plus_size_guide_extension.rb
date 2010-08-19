# Uncomment this if you reference any of your controllers in activate
#require_dependency 'application'

class PlusSizeGuideExtension < Spree::Extension
  version "1.0"
  description "Proxy for PlusSizeGuide XML data allowing Ajax"
  #url "http://localhost:9292/plussizeguide"

  # Please use plus_size_guide/config/routes.rb instead for extension routes.

  # def self.require_gems(config)
  #   config.gem "gemname-goes-here", :version => '1.2.3'
  # end
  
  def activate

    # make your helper avaliable in all views
    # Spree::BaseController.class_eval do
    #   helper YourHelper
    # end
  end
end
