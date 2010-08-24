# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class ThemeClicktireExtension < Spree::Extension
  version "1.0"
  description "Describe your extension here"
  url "http://yourwebsite.com/clicktire"

  # Please use clicktire/config/routes.rb instead for extension routes.

  # def self.require_gems(config)
  #   config.gem "gemname-goes-here", :version => '1.2.3'
  # end
  
  def activate
        Spree::Config.set(:default_locale => 'en-CA')
        
        Product.class_eval do
          # a scope that finds all products having an option value specified by name, object or id
          Product.named_scope :with_option_value_regex, lambda {|option, value|
            option_type_id = case option
            when String
              option_type = OptionType.find_by_name(option) || option.to_i
            when OptionType
              option.id
            else
              option.to_i
            end
            
            conditions = [
                "option_values.name ILIKE ? AND option_values.option_type_id = ?",
                "%#{value}%", option_type_id
              ]
            {
              :joins => {:variants => :option_values},
              :conditions => conditions
            }
          }
          
          Variant.class_eval do
            def to_hash
              
            end
          end
          # make your helper avaliable in all views
          # Spree::BaseController.class_eval do
          #   helper YourHelper
          # end
        end                    
  
      end
end
