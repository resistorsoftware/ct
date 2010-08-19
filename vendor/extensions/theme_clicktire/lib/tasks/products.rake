require 'open-uri'

namespace :clicktire do 
  
  desc "ClickTire.com Application Installer"
  task :install => :environment do
    ClickTire::Installer.run
  end
  
  desc "Download Direct Performance inventory images"
  task :download_direct_images => :environment do
    ClickTire::Installer.download_direct_images
  end
   
  desc "Create/Update Direct Performance Wheels to Inventory"
  task :set_direct => :environment do
    ClickTire::Installer.set_direct
  end
  
  desc "Create/Update Direct Performance Wheels to Inventory with S3 Images"
  task :insert_direct => :environment do
    ClickTire::Installer.insert_direct
  end
  
  desc "Add Option Values to the application.yaml file from Direct Wheel files"
  task :init_option_values => :environment do
    ClickTire::Installer.init_option_values
  end
  
  desc "Add Option Values to the DB from application.yaml"
  task :create_option_values => :environment do
    ClickTire::Installer.init
    #ClickTire::Installer.create_option_types
    ClickTire::Installer.create_option_values
  end
  
  
end  
  
namespace :ct do

  desc "ClickTire.com Application Installer"
  task :install => "clicktire:install"

  desc "Create/Update Direct Performance Wheels to Inventory"
  task :set_direct => "clicktire:set_direct"

  desc "Create/Update Direct Performance Wheels to Inventory with S3 Images"
  task :insert_direct => "clicktire:insert_direct"

  desc "Download Direct Performance inventory images"
  task :download_direct_images => "clicktire:download_direct_images"

  desc "Add Option Values to the application.yaml file from Direct Wheel files"
  task :init_option_values => "clicktire:init_option_values"
end

module ClickTire
  module Installer
    
    THEME_PATH = "#{RAILS_ROOT}/vendor/extensions/theme_clicktire"
    APP_DATA = "#{RAILS_ROOT}/config/application.yml"
    SPREE_DATA_PATH = "#{SPREE_ROOT}/db"
    
    @@config = nil
    
    def self.init
      return if @@config != nil
      require 'active_record'
      require 'fileutils'
      if (!FileTest.exist?(APP_DATA))
        raise StandardError.new("Configuration file '#{APP_DATA}' was not found!\n")
      end
      @@config = YAML.load(File.read(APP_DATA))
    end                                              
    
    def self.run
      self.init
      self.reset_options
      self.create_directories
      self.create_option_types
      self.create_option_values
      self.create_properties
    end
    
    def self.set_direct
      self.init
      self.create_wheel_products
    end
    
    def self.insert_direct
      self.init
      self.insert_direct_wheels
    end
    
    # write a bunch of option values to the application.yml file in config
    def self.init_option_values
      self.init
      self.parse_option_values
    end
    
    def self.download_direct_images 
      puts "Downloading product images for Direct Performance Manufacturers\n"
      self.init
      self.get_direct_images
    end
    
    def self.reset_options
      puts "Reset the option_values table and sequence to empty.\n"
      if OptionValue.count > 0
        puts "\tremoving #{OptionValue.count} Option Values\n"
        OptionValue.destroy_all
        OptionValue.connection.reset_pk_sequence!(OptionValue.table_name)
        puts "\tRemoved all values and reset the PK for Option Values.\n"
      end                                                               
      
      puts "Reset the option_types and sequence to empty.\n"
      if OptionType.count > 0
        puts "\tremoving #{OptionType.count} Option Types\n"
        OptionType.destroy_all
        OptionType.connection.reset_pk_sequence!(OptionType.table_name)
        puts "\tRemoved all values and reset the PK for Option Types.\n"
      end
      
      puts "Reset the Properties and sequence to empty\n"
      if Property.count > 0
        Property.destroy_all
        Property.connection.reset_pk_sequence!(Property.table_name)
      end
      
      puts "Reset the Taxons/Taxonomies and their sequences to empty\n"
      if Taxon.count > 0
        Taxon.destroy_all
        Taxon.connection.reset_pk_sequence!(Taxon.table_name)
      end
      if Taxonomy.count > 0
        Taxonomy.destroy_all
        Taxonomy.connection.reset_pk_sequence!(Taxonomy.table_name)
      end
    end
    
    def self.create_directories
      # we need db/wheels and db/tires
      if (!FileTest.exist?("#{RAILS_ROOT}/db/wheels"))
        FileUtils.mkdir "#{RAILS_ROOT}/db/wheels"
        puts "Created directory for wheels.\n"
      else
        puts "Directory db/wheels already exists.\n"
      end                                          
      if (!FileTest.exist?("#{RAILS_ROOT}/db/tires"))
        FileUtils.mkdir "#{RAILS_ROOT}/db/tires"
        puts "Created directory for tires\n"
      else
        puts "Directory db/tires already exists.\n"
      end  
    end
    
    def self.create_option_types
      puts "Creating option types for ClickTire Spree site...\n"
      option_types = @@config[:option_types]
      option_types.each_key do |ot|
        if OptionType.find(:first, :conditions => {:name => option_types[ot][:name]}).nil?
          OptionType.create({:name => option_types[ot][:name], :presentation => option_types[ot][:presentation]})
        end
      end
    end
    
    def self.create_option_values
      puts "Creating option values for ClickTire Spree site...\n"
      options = @@config[:option_variants]
      created = 0
      options.each_key do |o|
        
        puts "Trying to see if option #{options[o]['option_type']} exists.\n"
        option_type = OptionType.find_by_name(options[o]['option_type'])
        
        # only add an option value if in fact it does not already exist
        if OptionValue.find(:first, :conditions => {:option_type_id => option_type.id, :name => options[o]['name'].to_s}).nil?
          created += 1
          OptionValue.create({:option_type_id => option_type.id, :name => options[o]['name'].to_s, :presentation => options[o]['presentation'].to_s})
        else
          puts "Option Value #{options[o]['name']} existed, ignored create\n"
        end
      end
      puts "Created #{created} new Option Values for Variants\n" 
    end

    def self.create_properties
      puts "Adding Properties to the system\n"
      Property.create({:name => 'manufacturer', :presentation => 'Manufacturer'})
    end

    def self.get_direct_images
      start_time = Time.now
      completed = {}
      mfg_list = @@config[:direct_performance_mfg]
      mfg_list.each do |mfg|
        puts "\telapsed time #{Time.now - start_time}\n"
        file = open_file_read('wheels', mfg)
        data = YAML.load(file) 
        puts "Manufacturer #{mfg}\n"
        # data is a Hash so we can extract the key value pairs and go to town
        data.each_key do |model|
          puts "\t#{model}\n"
          data[model].each_pair do |key,value|
            if key == :variants
              value.each do |v|
                if completed.has_key?(v[:image])
                  puts "\t...already processed #{v[:image]}\n" 
                else
                  puts "\tDownloading #{v[:image]}\n"
                  baseuri = URI.parse('https://www.directperformance.com/')
                  iuri =  baseuri + URI.parse(v[:image])
                  # write the binary image data to the public/images/wheels directory and be sure to log the filename too for later reference
                  File.open(File.join(RAILS_ROOT, 'public','images','wheels',File.basename(iuri.path)), 'wb') do | f |
                    f << iuri.read
                  end
                  completed[v[:image]] = true
                end
              end
            end
          end
        end
        puts "Downloaded #{completed.length} images\n"
      end
    end
      
    def self.create_wheel_products
      start_time = Time.now
      mfg_property = Property.find_by_name('manufacturer')
      
      # puts "Creating/updating Wheel Products...\n"
      #      if Product.count > 0
      #        puts "\tremoving #{Product.count} Products\n"
      #        Product.destroy_all
      #        Product.connection.reset_pk_sequence!(Product.table_name)
      #        puts "\tremoving #{Variant.count} Product Variants\n"
      #        Variant.destroy_all
      #        Variant.connection.reset_pk_sequence!(Variant.table_name)
      #        puts "\tCompleted initial preparations...\nCreating Wheels Taxonomy"
      #      end
      #      
      #      if Taxonomy.find_by_name("Wheels").nil?
      #        t = Taxonomy.new(:name => "Wheels")
      #        t.save!
      #        puts "Created the Wheels taxonomy.\n"
      #      end
      #      
      #      if Taxonomy.find_by_name("Manufacturers").nil?
      #        t = Taxonomy.new(:name => "Manufacturers")
      #        t.save!
      #        puts "Created the Manufacturers taxonomy.\n"
      #      end          
      
      # find the manufacturers in the main config
      mfg_list = @@config[:direct_performance_mfg]
      mfg_list.each do |mfg|
        puts "\telapsed time #{Time.now - start_time}\n"
        # auto add manufacturers to the Wheels Taxon
        unless Taxonomy.find_by_name("Wheels").nil?
          if Taxon.find(:first, {:conditions => {:name => mfg, :parent_id => Taxon.find_by_name("Wheels").id}}).nil?
            puts "\tWorking on products for manufacturer #{mfg}\nHooking up manufacturer to Taxonomy Wheels.\n"
            t = Taxon.new({:name => mfg, :parent_id => Taxon.find_by_name("Wheels").id, :taxonomy_id => Taxonomy.find_by_name("Wheels").id})
            t.save!
            puts "Added new Taxon #{t.name}\n"
          end
        else
          puts "We did not find the Taxon for Wheels!!! Whoops\n"
          exit
        end
        
        unless Taxonomy.find_by_name("Manufacturers").nil?
          if Taxon.find(:first, {:conditions => {:name => mfg, :parent_id => Taxon.find_by_name("Manufacturers").id}}).nil?
            puts "\tWorking on products for manufacturer #{mfg}\nHooking up manufacturer to Taxonomy Manufacturers.\n"
            t = Taxon.new({:name => mfg, :parent_id => Taxon.find_by_name("Manufacturers").id, :taxonomy_id => Taxonomy.find_by_name("Manufacturers").id})
            t.save!
            puts "Added new Taxon #{t.name}\n"
          end
        else
          puts "We did not find the Taxon for Manufacturers! Whoops\n"
          exit
        end
        
        file = open_file_read('wheels', mfg)
        data = YAML.load(file)   
        data.each_pair do |product, variants|
          p = Product.find_by_name(product)
          if(p)
            puts "Found existing product #{p.name} with #{variants.length} variants\n"
          else                                                         
            puts "Creating #{product} which has #{variants.length} variants\n"
            new_product = Product.new(:name => product, :price => find_minimum_price(variants), :available_on => Time.now)
            new_product.save!
            
            taxon = Taxon.find_all_by_name(mfg)
            new_product.taxons << taxon
            #new_product.save!
            
            ProductProperty.create(:product_id => new_product.id, :property_id => mfg_property.id, :value => mfg)
            new_product.save!
            
            # now the variants of the product
            variants.each do |variant|
              options = {
                :sku => product + '::' + variant['color'],
                :cost_price => variant['price'].gsub(/[$]/,''),
                :price => (variant['price'].gsub(/[$]/,'').to_f) * 1.25,
                :width => variant['width'],
                :on_hand => 12
              }
              new_variant = new_product.variants.create(options)
              new_variant.option_values << OptionValue.find_by_name(variant['diameter'].to_s)
              new_variant.option_values << OptionValue.find_by_name(variant['offset'].to_s)
              new_variant.option_values << OptionValue.find_by_name(variant['bolt_pattern'].to_s)
              new_variant.option_values << OptionValue.find_by_name(variant['description'].parameterize)
              new_variant.save!
            end 
          end
        end
      end
    puts "Task took #{Time.now - start_time}\n"
    end
    
    def self.insert_direct_wheels
      start_time = Time.now
      mfg_property = Property.find_by_name('manufacturer')
      puts "Creating/updating Wheel Products...\n"
      
      # if Product.count > 0
      #        puts "\tremoving #{Product.count} Products\n"
      #        Product.destroy_all
      #        Product.connection.reset_pk_sequence!(Product.table_name)
      #        puts "\tremoving #{Variant.count} Product Variants\n"
      #        Variant.destroy_all
      #        Variant.connection.reset_pk_sequence!(Variant.table_name)
      #        puts "\tCompleted initial preparations...\nCreating Wheels Taxonomy"
      #      end
      #      
      #      if Taxonomy.find_by_name("Wheels").nil?
      #        t = Taxonomy.new(:name => "Wheels")
      #        t.save!
      #        puts "Created the Wheels taxonomy.\n"
      #      end
      #      
      #      if Taxonomy.find_by_name("Manufacturers").nil?
      #        t = Taxonomy.new(:name => "Manufacturers")
      #        t.save!
      #        puts "Created the Manufacturers taxonomy.\n"
      #      end       
      
      # find the manufacturers in the main config
      mfg_list = @@config[:direct_performance_mfg]
      mfg_list.each do |mfg|
        puts "\telapsed time #{Time.now - start_time}\n"
        # auto add manufacturers to the Wheels Taxon
        unless Taxonomy.find_by_name("Wheels").nil?
          if Taxon.find(:first, {:conditions => {:name => mfg, :parent_id => Taxon.find_by_name("Wheels").id}}).nil?
            puts "\tWorking on products for manufacturer #{mfg}\nHooking up manufacturer to Taxonomy Wheels.\n"
            t = Taxon.new({:name => mfg, :parent_id => Taxon.find_by_name("Wheels").id, :taxonomy_id => Taxonomy.find_by_name("Wheels").id})
            t.save!
            puts "Added new Taxon #{t.name}\n"
          end
        else
          puts "We did not find the Taxon for Wheels!!! Whoops\n"
          exit
        end
        
        unless Taxonomy.find_by_name("Manufacturers").nil?
          if Taxon.find(:first, {:conditions => {:name => mfg, :parent_id => Taxon.find_by_name("Manufacturers").id}}).nil?
            puts "\tWorking on products for manufacturer #{mfg}\nHooking up manufacturer to Taxonomy Manufacturers.\n"
            t = Taxon.new({:name => mfg, :parent_id => Taxon.find_by_name("Manufacturers").id, :taxonomy_id => Taxonomy.find_by_name("Manufacturers").id})
            t.save!
            puts "Added new Taxon #{t.name}\n"
          end
        else
          puts "We did not find the Taxon for Manufacturers! Whoops\n"
          exit
        end
        
        file = open_file_read('wheels', mfg)
        data = YAML.load(file)
        data.each_key do |model|
          p = Product.find_by_name(model)
          if p
            puts "Found existing product #{p.name} with #{p.variants.length} variants\n"
          else
            puts "\tCreating #{model} Product\n"
            new_product = Product.new(:name => model, :price => 0.0, :available_on => Time.now)
            new_product.save!
            taxon = Taxon.find_all_by_name(mfg)
            new_product.taxons << taxon
            ProductProperty.create(:product_id => new_product.id, :property_id => mfg_property.id, :value => mfg)
            new_product.save!  
            data[model].each_pair do |key,value|
              if key == :variants
                # update the product to have the lowest variant price now.
                new_product.price = find_minimum_price(value)
                new_product.save!
                # create each variant now
                value.each do |v|
                  if value.index(v) == 0
                    begin
                      # add this variants image to the product as an image for the product
                      i = Image.new
                      i.attachment=File.new(File.join(RAILS_ROOT,"public","images","wheels",File.basename(v[:image])))
                      i.viewable_id = new_product.id
                      i.viewable_type = 'Product'
                      i.save
                    rescue
                      debuglog "INSERT_DIRECT_PRODUCT Failed to save Image for Product #{new_product.id} named #{new_product.name}\n"
                    end
                  end
                  options = {
                    :sku => v[:product_code],
                    :cost_price => v[:price].gsub(/[$]/,''),
                    :price => ((v[:price].gsub(/[$]/,'').to_f) * 1.35)*1.16,
                    :width => v[:width],
                    :on_hand => v[:on_hand][:OH].to_i + v[:on_hand][:AZ].to_i + v[:on_hand][:TX].to_i
                  }
                  new_variant = new_product.variants.create(options)
                  new_variant.option_values << OptionValue.find_by_name(v[:diameter].to_s)
                  new_variant.option_values << OptionValue.find_by_name(v[:offset].to_s)
                  new_variant.option_values << OptionValue.find_by_name(v[:bolt_pattern].to_s)
                  new_variant.option_values << OptionValue.find_by_name(v[:description].parameterize)
                  new_variant.save!
                  # Upload the corresponding image for this product to S3
                  begin
                    i = Image.new
                    i.attachment=File.new(File.join(RAILS_ROOT,"public","images","wheels",File.basename(v[:image])))
                    i.viewable_id = new_variant.id
                    i.viewable_type = 'Variant'
                    i.save
                    puts "Uploaded Image #{v[:image]} to S3 for Variant\n"
                  rescue
                    debuglog "INSERT_DIRECT_VARIANT Failed to upload image for Variant #{new_variant.id}\n"
                  end
                end
              elsif key == :description
                new_product.description = value
                new_product.save!
              end
            end
          end  
        end
      end
    puts "Task took #{Time.now - start_time}\n"
    end
    
    # read the manufacturer files and then write the results to application.yml
    def self.parse_option_values
      start_time = Time.now
      model_counter = 0
      variant_counter = 0
      option_list = {}
      mfg_list = @@config[:direct_performance_mfg]
      mfg_list.each do |mfg|
        puts "Creating option values from product data for #{mfg}\n"
        file = open_file_read('wheels', mfg)
        data = YAML.load(file)   
        data.each_key do |model|    
          # a new model would be a type of wheel for a manufacturer
          model_counter +=1
          # each model points to an array of variants, each differing in some way
          data[model].each_pair do |key, value|
            if key == :variants
              value.each do |v|
                variant_counter += 1
                unless option_list.has_key?(v[:color])
                  option_list[v[:color]] = {
                    "option_type" => 'wheel-color',
                    "name" => v[:color],
                    "presentation" => v[:color]
                  }
                end
                unless option_list.has_key?(v[:description].parameterize)
                  option_list[v[:description].parameterize.to_s] = {
                    "option_type" => 'description',
                    "name" => v[:description].parameterize.to_s,
                    "presentation" => v[:description]
                  }
                end
                
                unless option_list.has_key?(v[:offset])   
                  option_list[v[:offset]] = {
                    "option_type" => 'offset',
                    "name" => v[:offset],
                    "presentation" => v[:offset]
                  }
                end
                
               unless option_list.has_key?(v[:diameter])
                  option_list[v[:diameter]] = {
                    "option_type" => 'diameter',
                    "name" => v[:diameter],
                    "presentation" => v[:diameter]
                  }
                end 
                
               unless option_list.has_key?(v[:bolt_pattern])
                 option_list[v[:bolt_pattern]] = {
                   "option_type" => 'bolt-pattern',
                   "name" => v[:bolt_pattern],
                   "presentation" => v[:bolt_pattern]
                 }
               end
                
              end
            end
          end
        end
      end
      puts "Writing the color_list to option_values file now, for #{model_counter} models and #{variant_counter} variants...\n"                     
      f = File.open(APP_DATA,'a')
      data = {:option_variants => option_list}
      f.write(data.to_yaml)
      f.close
      puts "Task took #{Time.now - start_time}\n" 
    end
    
    def self.find_minimum_price(variants)
      price = 100000.0
      variants.each do |variant|
        sample = (variant[:price].gsub(/[$]/,'').to_f)
        price = sample if price > sample
      end                             
      price
    end
    
    def self.extract_attribute(obj, attribute)
      result = nil
      obj.each do |o|
        o.each_pair do |k,v|
          result = v if k == attribute
        end
      end
      result
    end
      
  end
end


private

def open_file_read(prefix, mfg)
  if defined?(RAILS_ROOT)
    begin             
      f = File.join(RAILS_ROOT, 'db',prefix,"#{mfg}.yml")
      out = File.open(f,'r')
    rescue
      puts "File #{f} was not found to exist... return nothing I guess...\n or create the file as empty and return that.\n"
    end
  else
    # we are not in a rails program so try writing out to the current directory
    out = File.open(File.join(__DIR__,prefix,"#{mfg}.yml"),'r')
  end
end 

def open_spree_file(prefix, mfg)
  if defined?(SPREE_ROOT)
    out = File.open(File.join(SPREE_ROOT, 'db',prefix,"#{mfg}.yml"),'w')
  else
    # we are not in a rails program so try writing out to the current directory
    out = File.open(File.join(__DIR__,prefix,"#{mfg}.yml"),'w')
  end
end     

def self.open_root_file(prefix, mfg)
  if defined?(RAILS_ROOT)
    out = File.open(File.join(RAILS_ROOT, 'db',"#{mfg}.yml"),'w')
  else
    # we are not in a rails program so try writing out to the current directory
    out = File.open(File.join(__DIR__,prefix,"#{mfg}.yml"),'w')
  end
end

