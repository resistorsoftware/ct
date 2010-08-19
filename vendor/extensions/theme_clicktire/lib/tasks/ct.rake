require 'rubygems'
require 'ap'
require 'mechanize'
require 'open-uri' 

namespace :scraper do
  desc "Test Scraper class"
  task :test => :environment do
     scraper = Scraper.new
  end
end  

namespace :urbanauto do
  desc "UrbanAuto - create Options (Types and Values)"
  task :create_options => :environment do
    ua = UrbanAuto.new
    ua.create_option_types
    ua.create_option_values
  end
  desc "UrbanAuto - download Tirerack images if needed"
  task :tirerack_images => :environment do
    ua = UrbanAuto.new
    ua.get_tirerack_images
  end
  desc "UrbanAuto - audit Tirerack Products for images."
  task :audit_tirerack_images => :environment do
    ua = UrbanAuto.new
    ua.audit_tirerack_images
  end
  
  desc "UrbanAuto - audit Tirerack Products for Pricing."
  task :audit_tirerack_prices => :environment do
    ua = UrbanAuto.new
    ua.audit_tirerack_prices
  end
  
  desc "UrbanAuto - audit Tirerack Products for Property."
  task :audit_tirerack_property => :environment do
    ua = UrbanAuto.new
    ua.audit_tirerack_properties
  end
  
  desc "UrbanAuto - audit Products for Option Types."
  task :audit_option_types => :environment do
    ua = UrbanAuto.new
    ua.audit_option_types
  end
  
  desc "UrbanAuto - import Tirerack Products from scraped data files."
  task :import_tirerack_products => :environment do
    ua = UrbanAuto.new
    ua.import_tirerack_products
  end
  
  desc "UrbanAuto - scan/parse scraped Tirerack data files, to find any new missing option values."
  task :parse_tire_option_values => :environment do
    ua = UrbanAuto.new
    ua.parse_tire_option_values
    # we could follow this up with a create_option_value call,
    # but only if we reboot the config to re-read the application.yml
    ua.run
    ua.create_option_values
  end 
  
  desc "Remove Erroneous option values from Tires"
  task :fix_option_values => :environment do
    ua = UrbanAuto.new
    ua.redo_option_values_tirerack
  end
  
end

# UrbanAuto is a class to encapsulate all the small maintenance issues associated with inventory
class UrbanAuto
  
  THEME_PATH = "#{RAILS_ROOT}/vendor/extensions/theme_clicktire"
  APP_DATA = "#{RAILS_ROOT}/config/application.yml"
  SPREE_DATA_PATH = "#{SPREE_ROOT}/db"
  
  # secret sauce credentials
  URL_TIRERACK = 'http://www.tirerackwholesale.com'
  LOGIN_TIRERACK = 'urban.autosport@hotmail.com'
  PWD_TIRERACK = 'iluvmom'

  URL_DIRECT = 'http://www.directperformance.com'
  LOGIN_DIRECT = 'direct'
  PWD_DIRECT = 'buymore'
  
                                                                                       
  def initialize
    puts "UrbanAuto is initialized and ready for use\n"
    @@config = nil
    self.run
  end
  
  def run
    puts "UrbanAuto class initialized, setting up application\n"
    return if @@config != nil
    require 'active_record'
    require 'fileutils'
    if (!FileTest.exist?(APP_DATA))
      raise StandardError.new("Configuration file '#{APP_DATA}' was not found!\n")
    end
    @@config = YAML.load(File.read(APP_DATA))
  end
  
  # tirerack stuff is protected so we need to login before doing anything
  def tirerack_login
    a = Mechanize.new { |agent| agent.user_agent_alias = 'Mac Safari'}
    page = a.get("http://www.tirerackwholesale.com/whlogin/Login.jsp")
    form = page.form_with(:name => "login")
    form.customerID = LOGIN_TIRERACK
    form.passWord = PWD_TIRERACK
    page = a.submit(form)
    puts "Logged in to Tirerack, resulting in #{page.class}\n"
  end
  
  # create_option_types examines the option_types key in application.yml and creates any keys found that
  # are not already in the DB
  def create_option_types
    option_types = @@config[:option_types]
    puts "Creating Option Types for UrbanAuto site, #{option_types.length} options found to check.\n"
    created = 0
    option_types.each_key do |ot|
      if OptionType.find(:first, :conditions => {:name => option_types[ot][:name]}).nil?
        OptionType.create({:name => option_types[ot][:name], :presentation => option_types[ot][:presentation]})
        created += 1
      end
    end
    puts "Created #{created} Option Types\n"
  end  
  
  # Parse through manufacturer files and extract the variant options, creating Option Values for ones that do not exist already
  def create_option_values
    puts "Creating option values for ClickTire Spree site.\n"
    options = @@config[:option_variants]
    created = 0
    options.each_key do |o|
      # we changed the option_values format in the config file, sometimes we have an array to dig into...
      ap options[o]
      if options[o].instance_of?(Array)
        options[o].each do |option|
          option_type = OptionType.find_by_name(option['option_type'])
          if OptionValue.find(:first, :conditions => {:option_type_id => option_type.id, :name => option['name'].to_s}).nil?
            created += 1
            OptionValue.create({:option_type_id => option_type.id, :name => option['name'].to_s, :presentation => option['presentation'].to_s})
          end
        end
      else
        option_type = OptionType.find_by_name(options[o]['option_type'])
        if OptionValue.find(:first, :conditions => {:option_type_id => option_type.id, :name => options[o]['name'].to_s}).nil?
          created += 1
          OptionValue.create({:option_type_id => option_type.id, :name => options[o]['name'].to_s, :presentation => options[o]['presentation'].to_s})
        end
      end
    end
    puts "Created #{created} Option Values for Variants\n" 
  end
  
  # loop through all the tires, and redo the option values assigned to the variants to clean them up
  def redo_option_values_tirerack
    start_time = Time.now
    mfg_list = get_manufacturer_list
    count_v = 0
    count_p = 0
    mfg_list.each do |mfg|
      data = YAML.load(open_file_read('tires', mfg))
      data.each_key do |model|
        p = Product.find_by_name(model)
        if p.master.nil?
          price = get_lowest_price_from_yaml(data[model][:variants])
          Variant.create({
            :product_id => p.id,
            :is_master => true,
            :price => price,
            :cost_price => price
           }) 
        end
        
        count_p += 1
        if p
          # add the variants we need now
          variant_counter = 0
          data[model][:variants].each do |v|
            # check to see that the variant is even available before trying to add it
            # :availability and :level are the keys to make up the onhand values
            
            # unfortunately, some variants have a price of zero... so at least give them the price of the variant with one
            if v[:price] == 0.0
              price = get_lowest_price_from_yaml(data[model][:variants])
            else
              price = v[:price]
            end
                
            options = {
              :sku => "#{model}_#{variant_counter += 1}",
              :cost_price => price,
              :price => markup_tirerack(price),
              :width => '',
              :weight => v[:weight].to_i,
              :on_hand => v[:level].to_i
            }
            
            begin      
              new_variant = p.variants.create(options)
              
           #   puts "Load Range #{OptionValue.find(:first, :conditions => {:name => v[:load_range].to_s, :option_type_id => OptionType.find_by_name('load-range').id})}\n"
              new_variant.option_values << OptionValue.find(:first, :conditions => {:name => v[:load_range].to_s, :option_type_id => OptionType.find_by_name('load-range').id})
              
           #   puts "UTQG: #{OptionValue.find(:first, :conditions => {:name => v[:utqg].to_s, :option_type_id => OptionType.find_by_name('utqg').id})}\n"
              new_variant.option_values << OptionValue.find(:first, :conditions => {:name => v[:utqg].to_s, :option_type_id => OptionType.find_by_name('utqg').id})
              
          #    puts "Load Index: #{OptionValue.find(:first, :conditions => {:name => v[:load_index].to_s, :option_type_id => OptionType.find_by_name('load-index').id})}\n"
              new_variant.option_values << OptionValue.find(:first, :conditions => {:name => v[:load_index].to_s, :option_type_id => OptionType.find_by_name('load-index').id})
              
          #    puts "Load Factor: #{OptionValue.find(:first, :conditions => {:name => v[:load_factor].to_s, :option_type_id => OptionType.find_by_name('load-factor').id})}\n"                                                                                                                                                                    
              new_variant.option_values << OptionValue.find(:first, :conditions => {:name => v[:load_factor].to_s, :option_type_id => OptionType.find_by_name('load-factor').id})
                                                                                                                                                                                   
            #  puts "Speed Rating: #{OptionValue.find(:first, :conditions => {:name => v[:speed_rating].to_s, :option_type_id => OptionType.find_by_name('speed-rating').id})}\n"
              new_variant.option_values << OptionValue.find(:first, :conditions => {:name => v[:speed_rating].to_s, :option_type_id => OptionType.find_by_name('speed-rating').id})
              
             # puts "Size: #{OptionValue.find(:first, :conditions => {:name => v[:size].to_s, :option_type_id => OptionType.find_by_name('size').id})}\n"
              new_variant.option_values << OptionValue.find(:first, :conditions => {:name => v[:size].to_s, :option_type_id => OptionType.find_by_name('size').id})
              
             # puts "SideWall: #{OptionValue.find(:first, :conditions => {:name => v[:sidewall].to_s, :option_type_id => OptionType.find_by_name('sidewall').id})}\n"
              new_variant.option_values << OptionValue.find(:first, :conditions => {:name => v[:sidewall].to_s, :option_type_id => OptionType.find_by_name('sidewall').id})
              new_variant.save!
           #   puts "Created Variant #{new_variant.sku}\n"
              count_v += 1
            rescue => error
              ap p
              ap options
              ap v
             puts "Could not built the variant for the product due to error: #{error}\n"
            end
          end
        end
      end  
    end
    puts "redo_option_values_tirerack task took #{Time.now - start_time} seconds and worked on #{count_p} products, #{count_v} with variants\n" 
  end
  
  # loop through the manufacturers in the tirerack_mfg key and for each one, add the products.
  def import_tirerack_products
    start_time = Time.now
    performance_property = Property.find_by_name('performance_category')
    raise StandardError.new("No Property for Performance Category was found!\n") if performance_property.nil?
    manufacturer_property = Property.find_by_name('manufacturer')
    raise StandardError.new("No Property for Manufacturer was found!\n") if manufacturer_property.nil?
    
    mfg_list = get_manufacturer_list
    
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
          
          #TODO: we want to add all the option values again, this time with the correct option types for the product.
          
          
        else
          puts "\tCreating #{model} Product\n"
          new_product = Product.new(:name => model, :price => get_tirerack_variant_minprice(data[model][:variants]), :available_on => Time.now, :description => data[model][:description])
          new_product.save!
          
          # add taxons and properties now
          new_product.taxons << Taxon.find_all_by_name(mfg)
          ProductProperty.create(:product_id => new_product.id, :property_id => performance_property.id, :value => data[model][:performance])
          ProductProperty.create(:product_id => new_product.id, :property_id => manufacturer_property.id, :value => mfg)
          new_product.save!
        
          # add images to the product
          data[model][:images].each do |img|
            begin
              i = Image.new
              i.attachment = File.new(File.join(RAILS_ROOT,"public","images","tirerack",File.basename(img).gsub(/_s.jpg/,'_l.jpg')))
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
            ap v
            # check to see that the variant is even available before trying to add it
            # :availability and :level are the keys to make up the onhand values
            options = {
              :sku => "#{model}_#{variant_counter += 1}",
              :cost_price => v[:price],
              :price => markup_tirerack(v[:price]),
              :width => '',
              :weight => v[:weight].to_i,
              :on_hand => v[:level].to_i
            }
            new_variant = new_product.variants.create(options)
            begin
              # TODO: This is flawed since some Option Values belong to different types.
              new_variant.option_values << OptionValue.find_by_name(v[:load_range].to_s)
              new_variant.option_values << OptionValue.find_by_name(v[:utqg].to_s)
              new_variant.option_values << OptionValue.find_by_name(v[:load_index].to_s)
              new_variant.option_values << OptionValue.find_by_name(v[:load_factor].to_s)
              new_variant.option_values << OptionValue.find_by_name(v[:speed_rating].to_s)
              new_variant.option_values << OptionValue.find_by_name(v[:size].to_s)
              new_variant.option_values << OptionValue.find_by_name(v[:sidewall].to_s)
              new_variant.save!
              puts "Created Variant #{new_variant.sku}\n"
            rescue => error
              raise StandardError.new("Something happened in the Option Value find #{error}\n")
            end
          end
        end
      end  
    end
    puts "create_tire task took #{Time.now - start_time} seconds\n" 
  end
  
  # each tirerack product has images. check to see if the images listed in the mfg file exist in the public/images/tirerack
  # directory. If they do not, then we should login and download said images... to make the collection complete.
  def get_tirerack_images
    start_time = Time.now
    tirerack_login
    completed = {}
    mfg_list = get_manufacturer_list
    mfg_list.each do |mfg|
      data = YAML.load(open_file('tires', mfg)) 
      puts "Checking Manufacturer #{mfg}\n"
      data.each_key do |model|
        puts "\tModel: #{model}\n"
        data[model][:images].each do |img|
          # base will be just image name but with the _s.jpg extension
          base = File.basename(img)
          large = base.gsub(/_s.jpg/,"_l.jpg")
          if completed.has_key?(base)
            puts "\t...already processed #{base}\n" 
          else
            # check if image exists
            puts "Checking if #{large} exists in public/images/tirerack.\n" 
            unless File.exists?(File.join(RAILS_ROOT,"public","images","tirerack",large))
              puts "Image #{large} was NOT found, Download it now...\n"
              iuri =  URI.parse('http://www.tirerackwholesale.com/') + URI.parse(img.gsub(/_s.jpg/,'_l.jpg'))
              # write the binary image data to the public/images/wheels directory and be sure to log the filename too for later reference
              begin
                File.open(File.join(RAILS_ROOT, 'public','images','tirerack',File.basename(iuri.path)), 'wb') do | f |
                  f << iuri.read 
                end  
              rescue Timeout::Error
                puts "timed out trying to download #{File.basename(iuri.path)}"
              end
              puts "Image #{large} downloaded.\n"
              completed[base] = true
            else
              puts "Image #{large} was found, SKIP it...\n"
            end
          end
        end
      end
    end
    puts "Downloaded #{completed.length} images, in #{Time.now - start_time} seconds.\n"
  end
  
  # read the manufacturer files and then write the results to application.yml 
  # this has been re-factored to take into account there is probably an option value the same, but with a different type.
  def parse_tire_option_values
    start_time = Time.now
    model_counter = 0
    variant_counter = 0
    option_list = {}
    valid_options = %w{load_range load_factor load_index sidewall utqg speed_rating size}
    mfg_list = get_manufacturer_list
    mfg_list.each do |mfg|
      puts "Creating option values from product data for #{mfg}, adding them to application.yml\n"
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
              v.each_key do |k|
                if valid_options.include?(k.to_s)
                  option_list[v[k]] = [] unless option_list.has_key?(v[k])
                  new_option_value = {
                    "option_type" => k.to_s.dasherize,
                    "name" => v[k].to_s,
                    "presentation" => v[k].to_s
                  }
                  option_list[v[k]] << new_option_value unless option_list[v[k]].include?(new_option_value)
                end
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
  
  # iterate all the Products that are Tires, and see if the images exist for them
  def audit_tirerack_images
    mfg_list = get_manufacturer_list
    Product.in_taxon('Tires').each do |tire|
      if tire.images.empty?
        # does it exist in our public/images/tirerack directory?
        # only way to tell would be to query the product file and try and extract the image name
        mfg_list.each do |mfg|
          key = get_product_key(mfg, tire.name) if tire.taxons.map(&:name).include?(mfg)
          if key.instance_of?(Hash) && key.has_key?(:images)
            key[:images].each do |img|
              # check if this image exists now                                   
              base = File.basename(img).gsub(/_s.jpg/,'_l.jpg')
              if File.exists?(File.join(RAILS_ROOT, "public", "images", "tirerack",base))
                # OK.. so assign it to the product then.. since it already exists
                begin
                  # add this variants image to the product as an image for the product
                  i = Image.new
                  i.attachment= File.new(File.join(RAILS_ROOT, "public", "images", "tirerack",base))
                  i.viewable_id = tire.id
                  i.viewable_type = 'Product'
                  i.save
                rescue
                  debuglog "updating Product Image Failed\n"
                end
              end
            end
          end
        end
      end
    end
  end
  
  # iterate all the Products that are Tires, and see if the manufacturer property exists for them
  def audit_tirerack_properties
    mfg_list = get_manufacturer_list
    manufacturer_property = Property.find_by_name('manufacturer')
    counter = 0
    Product.in_taxon('Tires').each do |tire|
      mfg_list.each do |mfg|
        if tire.taxons.map(&:name).include?(mfg)
          # does this tire have the manufacturer property! If not make it so...
          if !tire.properties.include?('manufacturer')
            ProductProperty.create(:product_id => tire.id, :property_id => manufacturer_property.id, :value => mfg)
            counter += 1
          end
        end
      end
    end
    puts "Updated #{counter} Tire Products to have an appropriate manufacturer Property\n"
  end
  
  # iterate all the Products and ensure any option_types assigned to variants are present
  def audit_option_types
    counter = 0
    Product.all.each do |product|
      # all products assigned variants with options, should have a entry in model ProductOptionType
      if product.has_variants?
        product.variants.each do |variant|
          # here is my array of option_types for the Product
          option_types = OptionValue.find_all_by_id(variant.option_value_ids).map(&:option_type_id).uniq
          option_types.each do |ot|
            if ProductOptionType.find(:first, :conditions => {:product_id => product.id, :option_type_id => ot}).nil?
              ProductOptionType.create({:product_id => product.id, :option_type_id => ot})
              counter += 1
            end
          end
        end
      end
    end
    puts "Updated #{counter} ProductOptionTypes for Products\n"
  end
  
  # iterate all the Tire Products and ensure any errant option_types assigned to variants are eliminated
  def audit_errant_product_option_values
    counter = 0
    Product.in_taxon("Tires").each do |product|
      if product.has_variants?
        product.variants.each do |variant|
          v = variant.option_values.find_by_option_type_id(OptionType.find_by_name('wheel-color').id)
          ap "#{v.id} is a bad option value for variant #{variant.id}" unless v.nil?
        end
      end
    end
    puts "Removed #{counter} Erroneous Option Values from Tire Products\n"
  end
  
  # iterate all the Products that are Tires, and see if the images exist for them
  def audit_tirerack_prices
    Product.in_taxon('Tires').each do |tire|
      minimum = get_minimum_price(tire)
      if tire.price != minimum
        begin
          product = Product.find(tire.id)
          product.price = minimum
          product.save!
          puts "Updated price for Tire #{tire.id}\n"
        rescue => error
          puts "Could not save a change in price? #{error}\n"
        end
      end
    end
  end
  
  def get_manufacturer_list
    ENV['MFG'].nil? ? @@config[:tirerack_mfg] : [ENV['MFG']]
  end
  
  # iterate all of a products variants and return the minimum price
  def get_minimum_price(product)
    if product.has_variants?
      product.variants.map(&:price).sort.first
    else
      product.price  
    end
  end
  
  # iterate all of a products variants and return the minimum price
  def get_maximum_price(product)
    if product.has_variants?
      product.variants.map(&:price).sort.last
    else
      product.price  
    end
  end
  
  # given a product model and the manufacturer, suck out the key from the yaml file
  def get_product_key(mfg, product)
    data = YAML.load(open_file('tires', mfg))
    key = data.fetch(product)
  end
  
  # return the lowest price with the markup for tirerack
  def get_tirerack_variant_minprice(variants)
    markup_tirerack(variants.map {|v| v[:price]}.sort.first)
  end
  
  # add the price markup to cost price for product
  def markup_tirerack(price)
    (((price + 12.50) * 1.35) * 1.16)                      
  end

  def open_file(prefix, mfg)
    if defined?(RAILS_ROOT)
      begin             
        out = File.new(File.join(RAILS_ROOT, 'db',prefix,"#{mfg}.yml"),'r')
      rescue
        puts "File for #{mfg} was not found.\n"
      end
    else
      begin
        # we are not in a rails program so try writing out to the current directory
        out = File.open(File.join(__DIR__,prefix,"#{mfg}.yml"),'r')
      rescue
        puts "File for #{mfg} was not found.\n" 
      end
    end
  end
  
  def get_lowest_price_from_yaml(variants)
    variants.map {|v| v[:price]}.reject {|v| v == 0.0}.sort.first
  end
  
end

# Scraper encapsulates the logic for Scraping data from Direct and Tirerack
class Scraper
  
  # we can steal specs and store them in a nice structure
  # this constant is based on a visual exam of the spec table, unlikely to change but you never know
  # we had to do this crazy row/column thing as the XPath was unable to parse the <tr> elements surrounding table rows.
  COLUMNS = 13   

  # these are the three columns we want to deal with in the specification <table> element
  SIZE = 0        
  UTQG = 1        
  WEIGHT = 5
  
  def initialize
    puts "Scraper is initialized and ready for action\n" 
    @specifications = {}
    @@config = nil
    self.run
  end
            
  def run
    puts "Scraper class initialized, setting up application\n"
    return if @@config != nil
    require 'active_record'
    require 'fileutils'
    if (!FileTest.exist?(APP_DATA))
      raise StandardError.new("Configuration file '#{APP_DATA}' was not found!\n")
    end
    @@config = YAML.load(File.read(APP_DATA))
  end
  
  # given some path to some spec file, open it                                                                 
  def open_path(path)
    begin
      File.new(path, 'r')
    rescue 
      puts "Could not open provided path #{path}\n"
      exit
    end  
  end
  
  # returns a Document that can be searched for Tire specifications
  def open_specifications(file)
    begin                                          
      @specification_document = Nokogiri::HTML(file)
      file.close
    rescue
      puts "Could not parse file with Nokogiri::HTML!\n"
      exit
    end
  end
  
  def parse_specifications_document
    if @specification_document.nil?
      raise "Error no specification file found to parse"
      exit
    end
    
    # not sure why we had trouble getting at the <tr> elements here, so we made up a row/col based management system
    data = @specification_document.search('//table[@class="ruler"]/tbody/td')
    range = 0..data.count/COLUMNS-1  # how many rows in the specs table
    range.each do |r|
      # play a crazy game with gsub and search to get load and speed rating from specs size column 0
      col0 = SIZE+(r*COLUMNS)
      size_content = data[col0].content
      size = data[col0].search("b").first.content
      size_a_content = data[col0].search("a").first.content

      unless data[col0].search("a").search("span").first.nil?
        size_a_span_content = data[col0].search("a").search("span").first.content
        intermediate = size_a_content.gsub(size_a_span_content,'').strip    
        regex = /(\d{0,3}|\d{0,3}\/\d{0,3})([A-Z]+)/.match(intermediate)
        load_index = regex[1]
        speed_rating =  regex[2]
      else            
        intermediate = size_a_content.strip
        unless intermediate.empty?
          regex = /(\d{3,}|\d{3,}\/\d{3,})([A-Z]+)/.match(intermediate)
          load_index = regex[1]
          speed_rating =  regex[2]
        else
          load_index = 'n/a'
          speed_rating = 'n/a'
        end
      end

      load_factor = size_content.gsub(size_a_content,'').gsub(size,'').gsub(/\302\240/,'').gsub(/\n\t/,'').strip
      hover_text = data[UTQG+(r*COLUMNS)].search("a").search("span").first.content

      # key off of size since it should be unique in a specs table
      unless @specifications.has_key?(size)
        @specifications[size] = {
          :tire_details => []
        }
      end
      @specifications[size][:tire_details] << {
        # utqg has a span element with hover text we want to remove, we already calculated that
        :utqg => data[UTQG+(r*COLUMNS)].search("a").first.content.gsub(hover_text,''),
        # weight is easy, just take the integer of whatever is in the fifth column
        :weight => data[WEIGHT+(r*COLUMNS)].content.to_i,
        :load_index => load_index,
        :speed_rating => speed_rating,
        :load_factor => load_factor
      }
    end
  end
  
  def parse_size_pricing(file)
    while line = file.gets
      ap line
      size =  /^([0-9]+\/?\.?[0-9]+[A-Z]+[0-9]+\.?\d?|[0-9]+X[0-9]+\.?[0-9]+[A-Z][0-9]+)(Blackwall|Outlined White Letters|Raised White Letters|narrow white stripe|white stripe|raised black letters)/i.match(line)
      # The Load Rating and Speed Rating  <MatchData "Serv. Desc: 91Y" 1:"91" 2:"Y">
      index = /(?:Serv\.\sDesc:\s?)(?:\()?(\d{0,3}|\d{0,3}\/\d{0,3})([A-Z]+)(?:\))?/.match(line)
      unless index.nil? || index[1].nil?
        load_index = index[1]
      else
        load_index = 'n/a'
      end

      unless index.nil? || index[2].nil?
        speed_rating = index[2] 
      else
        speed_rating = 'n/a'
      end

      # Load Range if applicable <MatchData "Load Range XL" 1:"XL">
      range = /(?:Load\sRange\s?)([A-Z]+)/.match(line)
      unless range.nil?
        load_range = range[1]
      else
        load_range = ''
      end

      # Price (can be very fucking complicated it seems)
      # Orig. Price:$138.00 (each)$124.00
      # Price: $128.00 (each)
      # Price $128.00 (each) Special
      # <MatchData "Price:$138.00 (each)$124.00" 1:"138.00" 2:"124.00">
      price = /(?:Price:\s?)\$([0-9]+\.[\d]{2})\s\(each\)(\$?([0-9]+\.[\d]{2})|Special)?/.match(line)

      #Availability
      # Estimated Availability: In Stock
      # Estimated Availability: Fewer than 11
      # Estimated Availability: Back Order
      availability = /(Not Available|In Stock|Fewer than|Back Order|Special Order|\d{2}\/\d{2}\/\d{2})\s([0-9]+)?/i.match(line)
      # <MatchData "Fewer than 99" 1:"Fewer than" 2:"99">
      status = availability[1]
      # set level according to the status
      case status
        when 'Fewer than'
          level = availability[2]
        when 'Not Available'
          level = 0
        when 'Back Order'
          level = 0
        when 'Special Order'
          level = 0
        when 'In Stock'
          level = 8
      end
      
      result = {
        :original_index => index,
        :size => size[1],
        :sidewall => size[2],
        :load_index => load_index,
        :speed_rating => speed_rating,
        :load_range => load_range,
        :price => price[2].nil? ? price[1].to_f : price[2].to_f,
        :availability => status,
        :level => level,
      }
      
      ap "Before"
      ap result
      
      # merge this result with the one from @specifications matching on size key

      if(@specifications.has_key?(result[:size]))
        ap "We found tire #{result[:size]} as a match in specifications"
        specs = @specifications[result[:size]][:tire_details]
        # don't bother doing anything but a merge if only one exists
        if specs.length == 1 
          result.merge!(specs.first)
        else
          # try and find a match. first with multiple keys
          result.merge!(find_with_multiple_keys(result, specs)) 
        end
        
        ap "After"
        ap result
      end
      
    end
  end
  
  def find_with_multiple_keys(original, specs)
    # this would be a default match if one is not found.. this could be better
    match = {
      :utqg => 'n/a',
      :weight => '30'
    }
    specs.each do |spec|
       if spec[:load_index] == original[:load_index] && spec[:speed_rating] == original[:speed_rating]
           match = original.merge!(spec)
           ap "merged on both load_index and speed_rating"
           break match
       end
    end
    match
  end
  
end