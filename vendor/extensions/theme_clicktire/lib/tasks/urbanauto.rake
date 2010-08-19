require 'rubygems'

namespace :clicktire do
  desc "Read TireRack manufacturer files, and ensure all the performance categories are installed in DB"
  task :update_performance_categories => :environment do
     UrbanAutosport::Administration.get_all_performance_categories
  end
  desc "Read TireRack manufacturer files, and create Tires!"
  task :create_tires => :environment do
     UrbanAutosport::Administration.create_tires
  end
  desc "Read TireRack manufacturer files, and create Option Values"
  task :tirerack_option_values => :environment do
     UrbanAutosport::Administration.parse_tire_option_values
  end
end

# simple alias so clicktire becomes ct
namespace :ct do
  desc "Read TireRack manufacturer files, and ensure all the performance categories are installed in DB" 
  task :upc => "clicktire:update_performance_categories"
  desc "Read TireRack manufacturer files, and create Tires!"
  task :create_tires => "clicktire:create_tires"
  desc "Read TireRack manufacturer files, and create Option Values"
  task :tov => "clicktire:tirerack_option_values" 
end

module UrbanAutosport
  module Administration
    
    THEME_PATH = "#{RAILS_ROOT}/vendor/extensions/theme_clicktire"
    APP_DATA = "#{RAILS_ROOT}/config/application.yml"
    SPREE_DATA_PATH = "#{SPREE_ROOT}/db"
    @@config = nil
    
    # load in the administration YAML
    def self.init
      return if @@config != nil
      require 'active_record'
      require 'fileutils'
      if (!FileTest.exist?(APP_DATA))
        raise StandardError.new("Configuration file '#{APP_DATA}' was not found!\n")
      end
      
      # since this is a YAML file, we can append new keys to it.
      @@config = YAML.load(File.read(APP_DATA))
    end                                                         
                                           
    # for each manufacturer, read the files, get the performance categories all in one big Hash
    # and then check to see if they exist in the Properties. Create any missing Properties
    def self.get_all_performance_categories
      self.init
      self.create_performance_properties  # ensure the property exists before going further 
    end
    
    def self.create_tires
      self.init
      self.create_performance_properties  # ensure the property exists before going further
      self.create_tire_taxons
      self.create_tire_products
    end
    
    # loop through the manufacturers in the tirerack_mfg key and for each one, add the products.
    def self.create_tire_products
      
      start_time = Time.now
      performance_property = Property.find_by_name('performance_category')
      raise StandardError.new("No Property for Performance Category was found!\n") if performance_property.nil?
      
      mfg_list = @@config[:tirerack_mfg]
      mfg_list.each do |mfg|
        
        unless Taxonomy.find_by_name("Tires").nil?
          if Taxon.find(:first, {:conditions => {:name => mfg, :parent_id => Taxon.find_by_name("Tires").id}}).nil?
            puts "\tWorking on products for manufacturer #{mfg}\nHooking up manufacturer to Taxonomy Tires.\n"
            t = Taxon.new({
              :name => mfg,
              :parent_id => Taxon.find_by_name("Tires").id,
              :taxonomy_id => Taxonomy.find_by_name("Tires").id
            })
            t.save!
            puts "Added new Taxon #{t.name}\n"
          end
        else
          raise StandardError.new("No Taxonomy for Tires was found!\n")
        end
        
        unless Taxonomy.find_by_name("Manufacturers").nil?
          if Taxon.find(:first, {:conditions => {:name => mfg, :parent_id => Taxon.find_by_name("Manufacturers").id}}).nil?
            puts "\tWorking on products for manufacturer #{mfg}\nHooking up manufacturer to Taxonomy Manufacturers.\n"
            t = Taxon.new({:name => mfg, :parent_id => Taxon.find_by_name("Manufacturers").id, :taxonomy_id => Taxonomy.find_by_name("Manufacturers").id})
            t.save!
            puts "Added new Taxon #{t.name}\n"
          end
        else
          raise StandardError.new("No Taxonomy for Manufacturers was found!\n")
        end
        
        file = open_file_read('tires', mfg)
        data = YAML.load(file)
        data.each_key do |model|
          p = Product.find_by_name(model)
          if p
            puts "Found existing product #{p.name} with #{p.variants.length} variants\n"
          else
            puts "\tCreating #{model} Product\n"
            new_product = Product.new(:name => model, :price => find_minimum_price(data[model][:variants]), :available_on => Time.now, :description => data[model][:description])
            new_product.save!
            taxon = Taxon.find_all_by_name(mfg)
            new_product.taxons << taxon
            ProductProperty.create(:product_id => new_product.id, :property_id => performance_property.id, :value => data[model][:performance])
            new_product.save!
          
            # add images to the product
            data[model][:images].each do |img|
              begin
                i = Image.new
                i.attachment = File.new(File.join(RAILS_ROOT,"public","images","tirerack",File.basename(img.gsub(/_s.jpg/,'_l.jpg'))))
                i.viewable_id = new_product.id
                i.viewable_type = 'Product'
                i.save  
              rescue
                debuglog "Failed to save Image(s) for Product #{new_product.id} named #{new_product.name}\n"
                puts "Failed to save Image(s) for Product #{new_product.id} named #{new_product.name}\n"
              end
            end
            
            # iterate the :variants key now
            variant_counter = 0
            data[model][:variants].each do |v|
            
              # check to see that the variant is even available before trying to add it
              # :availability and :level are the keys to make up the onhand values
              
              options = {
                :sku => "#{model}_#{variant_counter += 1}",
                :cost_price => v[:price],
                :price => ((v[:price] + 12.5) * 1.35) * 1.16,
                :width => '',  # tires have no width we know off,
                :weight => v[:weight].to_i,
                :on_hand => v[:level].to_i
              }
              new_variant = new_product.variants.create(options)
              new_variant.option_values << OptionValue.find_by_name(v[:load_range].to_s)
              new_variant.option_values << OptionValue.find_by_name(v[:utqg].to_s)
              new_variant.option_values << OptionValue.find_by_name(v[:load_index].to_s)
              new_variant.option_values << OptionValue.find_by_name(v[:load_factor].to_s)
              new_variant.option_values << OptionValue.find_by_name(v[:speed_rating].to_s)
              new_variant.option_values << OptionValue.find_by_name(v[:size].to_s)
              new_variant.option_values << OptionValue.find_by_name(v[:sidewall].to_s)
              new_variant.save!
              puts "Created Variant #{new_variant.sku}\n"
            end
            
          end
        end  
      end
      puts "create_tire task took #{Time.now - start_time} seconds\n" 
    end
                               
    # we need Taxons for Tires connecting the Manufacturers to it
    def self.create_tire_taxons
      puts "Adding Tires taxonomy to the system..."
      if Taxonomy.find_by_name('Tires').nil?
        puts "Creating the Tires Taxonomy...\n"
        Taxonomy.create({:name => 'Tires'})
      end
      puts "done\n"
    end
    
    # support method that simply ensures the Property performance_category exists
    def self.create_performance_properties
      puts "Adding performance categories to the system..."
      if Property.find_by_name('performance_category').nil?
        puts "Created the Property called performance category\n"
        Property.create({:name => 'performance_category', :presentation => 'Performance Category'})
      end
      puts "done\n"
    end
    
    # read the tire files and extract all the possible categories.
    # this is probably not needed.
    def self.get_all_categories
      start_time = Time.now
      categories = {}
      mfg_list = @@config[:tirerack_mfg]
      mfg_list.each do |mfg|
        file = open_file_read('tires', mfg)
        # for each key in this data, look for the performance category
        data = YAML.load(file)
        data.each_key do |model|
          data[model].each_pair do |key,value|
           if key == :performance
             categories[value] = true
           end
          end
        end
      end # mfg loop
      puts "Categories #{categories.to_yaml}\n"
      puts "Task took #{Time.now - start_time} seconds\n" 
      categories
    end
    
    # read the manufacturer files and then write the results to application.yml
    def self.parse_tire_option_values
      self.init
      start_time = Time.now
      model_counter = 0
      variant_counter = 0
      option_list = {}
      mfg_list = get_manufacturer_list
      mfg_list.each do |mfg|
        puts "Creating option values from product data for #{mfg}\n"
        file = open_file_read('tires', mfg)
        data = YAML.load(file)   
        data.each_key do |model|    
          # a new model would be a type of wheel for a manufacturer
          model_counter +=1
          # each model points to an array of variants, each differing in some way
          data[model].each_pair do |key, value|
            if key == :variants
              value.each do |v|
                variant_counter += 1
                unless option_list.has_key?(v[:load_range])
                  option_list[v[:load_range]] = {
                    "option_type" => 'load-range',
                    "name" => v[:load_range],
                    "presentation" => v[:load_range]
                  }
                end
                unless option_list.has_key?(v[:load_factor])
                  option_list[v[:load_factor]] = {
                    "option_type" => 'load-factor',
                    "name" => v[:load_factor],
                    "presentation" => v[:load_factor]
                  }
                end
                
                unless option_list.has_key?(v[:load_index])   
                  option_list[v[:load_index]] = {
                    "option_type" => 'load-index',
                    "name" => v[:load_index],
                    "presentation" => v[:load_index]
                  }
                end
                
               unless option_list.has_key?(v[:sidewall])
                  option_list[v[:sidewall]] = {
                    "option_type" => 'sidewall',
                    "name" => v[:sidewall],
                    "presentation" => v[:sidewall]
                  }
                end 
                
               unless option_list.has_key?(v[:utqg])
                 option_list[v[:utqg]] = {
                   "option_type" => 'utqg',
                   "name" => v[:utqg],
                   "presentation" => v[:utqg]
                 }
               end
               
               unless option_list.has_key?(v[:speed_rating])
                 option_list[v[:speed_rating]] = {
                   "option_type" => 'speed-rating',
                   "name" => v[:speed_rating],
                   "presentation" => v[:speed_rating]
                 }
               end
                
               unless option_list.has_key?(v[:size])
                 option_list[v[:size]] = {
                   "option_type" => 'size',
                   "name" => v[:size],
                   "presentation" => v[:size]
                 }
               end
                
              end
            end
          end
        end
      end
      puts "Writing the options to option_values file now, for #{model_counter} models and #{variant_counter} variants...\n"                     
      @@config[:option_variants].merge!(option_list)
      f = File.open(APP_DATA,'w')
      YAML.dump(@@config, f)
      f.close
      puts "Task took #{Time.now - start_time}\n" 
    end
    
    def self.find_minimum_price(variants)
      price = 100000.0
      variants.each do |variant|
        sample = (variant[:price])
        price = sample if price > sample
      end                             
      price
    end
    
    def self.get_manufacturer_list
      ENV['MFG'].nil? ? @@config[:tirerack_mfg] : [ENV['MFG']]
    end
     
  end
end        

 