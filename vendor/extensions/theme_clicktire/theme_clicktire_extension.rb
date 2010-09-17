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
        Spree::Config.set(:allow_ssl_in_production => 'false')
        Spree::Config.set(:allow_anonymous_checkout => 'true')
        
        # make your helper avaliable in all views
        Spree::BaseController.class_eval do
          helper :clicktire
        end
        
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
            
            conditions = ["option_values.name ~*  ? AND option_values.option_type_id = ?","#{value}", option_type_id ]
            {
              :joins => {:variants => :option_values},
              :conditions => conditions
            }
          }
          
          # products can either be Tires or Wheels for now.. which one is it gonna be
          def main_taxon
            wheels = self.taxons.find_by_taxonomy_id(Taxonomy.find_by_name("Wheels").id)
            wheels.parent.name unless wheels.nil?
            tires = self.taxons.find_by_taxonomy_id(Taxonomy.find_by_name("Tires").id)
            tires.parent.name unless tires.nil?  
          end                                                                       
          
          def self.find_all_variants_by_option_value(option_type, value)
           "Here is a list of variants"
          end
        end
         
        Variant.class_eval do
          def find_option_by_type(option_type)
            ot = OptionType.find_by_name(option_type)
            result = ''
            self.option_values.each do |ov| 
              result = ov.presentation if ov.option_type.id == ot.id
            end
            result
          end
        end
        
  end
end
