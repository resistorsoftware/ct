module Spree
  module Clicktire
    # Singleton class to access the Clicktire configuration object (ClicktireConfiguration.first by default) and it's preferences.
    #
    # Usage:
    # Spree::Clicktire::Config[:foo] # Returns the foo preference
    # Spree::Clicktire::Config[] # Returns a Hash with all the tax preferences
    # Spree::Clicktire::Config.instance # Returns the configuration object (HerokuConfiguration.first)
    # Spree::Clicktire::Config.set(preferences_hash) # Set the tax preferences as especified in +preference_hash+
    class Config
      include Singleton
      include PreferenceAccess
    
      class << self
        def instance
          return nil unless ActiveRecord::Base.connection.tables.include?('configurations')
          ClicktireConfiguration.find_or_create_by_name("Default clicktire configuration")
        end
      end
    end
  end
end