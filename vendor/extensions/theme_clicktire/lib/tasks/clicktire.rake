require 'rubygems'
require 'mechanize'
require 'open-uri'

# secret sauce credentials
URL_TIRERACK = 'http://www.tirerackwholesale.com'
LOGIN_TIRERACK = 'urban.autosport@hotmail.com'
PWD_TIRERACK = 'iluvmom'

URL_DIRECT = 'http://www.directperformance.com'
LOGIN_DIRECT = 'direct'
PWD_DIRECT = 'buymore' 

COLUMNS = 13   

# these are the three columns we want to deal with in the specification <table> element
SIZE = 0        
UTQG = 1        
WEIGHT = 5

namespace :clicktire do
  desc "Login to Direct Performance and Scrape Wheel Descriptions"
  task :get_descriptions do
    puts "Login to Direct Performance - Manufacturer: #{ENV['MFG'].nil? ? 'None Specified' : ENV['MFG'] }"
    manufacturers = []
    if ENV['MFG'].nil?
      
      # look for the config file containing a list of manufacturers to scrape
      if defined?(RAILS_ROOT)
        @mfg_list = YAML.load_file(File.join(RAILS_ROOT,'config','direct_performance.yml'))
      end
      
      unless @mfg_list.nil?
        puts "Config file has #{@mfg_list[:mfg].length} manufacturers to process...\n"
        manufacturers = @mfg_list[:mfg]
      else
        puts "No config file was found and no Manufacturers was specified. Try rake ct:update_direct MFG=Drag for example\n"
        exit
      end
    else
      manufacturers = [ENV['MFG']]
    end
    
    agent = Mechanize.new
    page = agent.get(URL_DIRECT+'/dtw/welcome.do')
    form = page.form_with(:name => "loginForm")
    form.username = LOGIN_DIRECT
    form.password = PWD_DIRECT
    page = agent.submit(form)           # Log us in to the site, resulting page has pricing selection
    
    # Choose Pricing Mode (Wholesale or none at all, radio buttons)
    # input element name=priceDisplayMode
    form = page.form_with(:name => 'pricingModeForm')
    form.radiobutton_with(:value => /0/).check
    page = agent.submit(form)           # take us to the page where we can now click the link to wheels or tires with wholesale prices
    page = agent.page.link_with(:text => 'Wheels').click
    direct_data = []
    
    while mfg = manufacturers.shift
      form = page.form_with(:name => 'wheelSearchForm')
      form.field_with(:name => 'wheelSearching.manufacturer').option_with(:value => mfg).select
      data = agent.submit(form) 
      # loop  through all the pages to get at all the variants.
      links = data.link_with(:text => 'More info ...')
      product_id = /[0-9]+/.match(links.attributes.get_attribute('onclick'))
      details_page = agent.get(URL_DIRECT+"/dtw/appWheelDetails.do?prodcode=#{product_id}")
      cells = details_page.search('//table//tr[3]').search('td')
      description = cells.last.content.strip
      img = cells[1].search('img').first
      baseuri = URI.parse('https://www.directperformance.com/')
      iuri =  baseuri + URI.parse(img['src'])
      # write the binary image data to the public/images/wheels directory and be sure to log the filename too for later reference
      File.open(File.join(RAILS_ROOT, 'public','images','wheels',File.basename(iuri.path)), 'wb') do | f |
        f << iuri.read
      end
    end
  end
  
  desc "Login to Direct Performance and Scrape Wheels"
  task :get_wheels do
    puts "Login to Direct Performance - Manufacturer: #{ENV['MFG'].nil? ? 'None Specified' : ENV['MFG'] }"
    manufacturers = []
    if ENV['MFG'].nil?
      
      # look for the config file containing a list of manufacturers to scrape
      if defined?(RAILS_ROOT)
        @mfg_list = YAML.load_file(File.join(RAILS_ROOT,'config','direct_performance.yml'))
      end
      
      unless @mfg_list.nil?
        puts "Config file has #{@mfg_list[:mfg].length} manufacturers to process...\n"
        manufacturers = @mfg_list[:mfg]
      else
        puts "No config file was found and no Manufacturers was specified. Try rake ct:update_direct MFG=Drag for example\n"
        exit
      end
    else
      manufacturers = [ENV['MFG']]
    end
    
    agent = Mechanize.new
    page = agent.get(URL_DIRECT+'/dtw/welcome.do')
    form = page.form_with(:name => "loginForm")
    form.username = LOGIN_DIRECT
    form.password = PWD_DIRECT
    page = agent.submit(form)           # Log us in to the site, resulting page has pricing selection
    
    # Choose Pricing Mode (Wholesale or none at all, radio buttons)
    # input element name=priceDisplayMode
    form = page.form_with(:name => 'pricingModeForm')
    form.radiobutton_with(:value => /0/).check
    page = agent.submit(form)           # take us to the page where we can now click the link to wheels or tires with wholesale prices
    page = agent.page.link_with(:text => 'Wheels').click
    # direct_data is an array of manufacturers we will write out to the result file
    direct_data = []
    
    while mfg = manufacturers.shift
      #page = agent.get(URL_DIRECT+'/dtw/appWheelSearch.do')
      puts "Processing wheels for manufacturer #{mfg}\n"
      out = open_file("wheels",mfg)
      
      # we create a hash keyed on the model, where each model has variants, which is an array of hashes
      models = {}
      
      # now we have access to the Direct Wheel Selection form. Loop through manufacturers for data
      # This page is always known as /dtw/appWheelSearch.do
      form = page.form_with(:name => 'wheelSearchForm')
      form.field_with(:name => 'wheelSearching.manufacturer').option_with(:value => mfg).select
      data = agent.submit(form)
    
      # Place all this in a paging loop so we get ALL the wheels for the Manufacturer
      links = data.links_with(:href => /appWheelSortResults.do\?pager.offset=/)
      if links.length > 0 
        start = links.first.href.match(/\d{2}/)[0].to_i
        finish = links.last.href.match(/\d{1,4}/)[0].to_i
        puts "We will search a total of #{finish / start} pages\n"
       # finish = 10 # Comment this out when you want to run ALL the pages and not just the first one
      else 
        # no links, no paging so set finish to be 10 which will ensure we only do this paging thing once
        start = finish = 10
      end
      
      while start <= finish do
        puts "Processing Page #{start / 10}\n"
      
        # paging is controlled by these things.<a href="/dtw/appWheelSortResults.do?pager.offset=10">2</a>
        #tables = data.xpath('//comment()[.="wheels found table"]/following-sibling::table[1]/table[1]/a').each do |link|
        #  href = link.attribute('href').to_s
        #  puts "Found an href to check #{href}\n"
        #  puts "Found a paging link to page #{link.inner_text()}\n" unless href.match(/dtw/).nil?
        #end
        #puts "Current page has #{data.links_with(:href => /appWheelSortResults.do\?pager.offset=\d\d$/).length} paging links\n"
        #data.links_with(:href => /appWheelSortResults.do\?pager.offset=\d\d$/).each do |link|
        #   links << link.href unless links.include?(link.href)
        #end
        #puts "Links array now contains #{links.length.to_s} links"
      
        results = []
        data.search('//comment()[.="start, wheel info"]//following-sibling::*').each do |cell|
          # cell is a table. We need to extract more than a few things out of it to keep this a well-oiled machine
          extras = get_product_data(cell)
          unless extras.nil?
            #puts "Processed product code #{extras[:product_code]}\n"
            url ="https://www.directperformance.com/dtw/appWheelDetails.do?prodcode=#{extras[:product_code]}"
            popup = agent.get(url)
            # transfer all the data from this one wheel to results for later processing
            results << {
              :description => popup.search("tr")[2].search("td").last.content.strip,
              :extras => extras,
              :content => cell.content.gsub(/\s/," ").squeeze(" ").strip()
            }
          end
        end
        
        results.each do |r|
          # groupings for the following Regex
          # 1= manufacturer
          # 2= model of the wheel (includes any hyphens or numbers eg: DR-31)
          # 3= the words of a description up until a number occurs (which should be the wheel size eg 15X7)
          regex = Regexp.new("(^#{mfg})\s([-?A-Za-z0-9]+)([\\w\\s]+)")
          mfg_model = regex.match(r[:content])
          unless mfg_model.nil?
            details = {
              :mfg => mfg_model[1],
              #:model => mfg_model[2],
              :model => r[:extras][:model].gsub(mfg,'').strip,
              :description => r[:extras][:description]
              #:description => mfg_model[3] 
            }
            
            details = correct_details(details)
             
            # groupings for the following crazy ass regex 
            # 1=size
            # 2=diameter
            # 3=optional decimal for diameter
            # 4=bolt-pattern
            # 5,6=optional extra bolt pattern
            # 7=offset (can be plus or minus)
            # 8=color code
            #                1        2         3                4          5                     6                              7             8
            #holygrail = /([0-9]+)X([0-9]+)(\.[0-9]|\s)?(\s?[0-9]-[0-9]+)(\.\d{0,2})?(\/\d{3}|\s|\/\d{3}.[0-9]?|[A-Z]+?)?(-?[0-9]+|\s?[0-9]+)([A-Z]+)/.match(r)
            holygrail = /([0-9]+)X([0-9]+)(\.[0-9]|\s)?(\s?[0-9]-[0-9]+)(\.\d{0,2})?(\/\d{3}|\s|\/\d{3}.[0-9]?|\w{0,3})?(?:\s?)(-?[0-9]+)([A-Z]+)/.match(r[:content])
            unless holygrail.nil?
              diameter = holygrail[1]
              width = holygrail[2]
              width += holygrail[3] unless holygrail[3].nil?
              bolt_pattern = holygrail[4]
              #bolt_pattern += holygrail[5] unless holygrail[5].nil?
              bolt_pattern += holygrail[6] unless holygrail[6].nil?
              offset = holygrail[7] unless holygrail[7].nil?
              color = holygrail[8] unless holygrail[8].nil?
            end
            price = /\$\d{1,3}.(\d{2})/.match(r[:content])
            on_hand = /(AZ\s[0-9]+\s)(OH\s[0-9]+\s)(TX\s[0-9]+)/.match(r[:content])
            az = /[0-9]+/.match(on_hand[1])
            oh = /[0-9]+/.match(on_hand[2])
            tx = /[0-9]+/.match(on_hand[3])
            puts "#{r[:content]}\nMfg: #{details[:mfg]}, Model: #{details[:model]}, Description: #{details[:description]}, Price: #{price}, Diameter: #{diameter}, Width: #{width}, Bolt Pattern: #{bolt_pattern}, Offset: #{offset}, Color: #{color}\n"
            unless models.has_key?(details[:model])
              models[details[:model]] = {:description => r[:description], :variants => []}
            end 
            models[details[:model]][:variants] << {
              :description => details[:description].strip,
              :price => price[0],
              :diameter => diameter.to_f,
              :width => width.to_f,
              :bolt_pattern => bolt_pattern.strip,
              :offset => offset.to_i,
              :color => color,
              :on_hand => {:AZ => az[0].to_i, :OH => oh[0].to_i, :TX => tx[0].to_i},
              :image => r[:extras][:image],
              :logo => r[:extras][:logo],
              :product_code => r[:extras][:product_code]
            }
          end
        end
      
        # click to get a new data page and bump the paging to ensure we escape this loop
        href = Regexp.new(Regexp.escape("appWheelSortResults.do?pager.offset=#{start}"))
        data = data.link_with(:href => href).click unless data.link_with(:href => href).nil?
        start += 10
      end
      YAML.dump(models, out)
      out.close  
    end
  end
  
  desc "Login to the Tire Rack and scrape data"
  task :scrape_tirerack do
    puts "Login to Tire Rack - Manufacturer: #{ENV['MFG'].nil? ? 'None Specified' : ENV['MFG'] }"
     manufacturers = []
     if ENV['MFG'].nil?
       # look in the config file key tirerack_mfg containing a list of manufacturers to scrape
       if defined?(RAILS_ROOT)
         config = YAML.load_file(File.join(RAILS_ROOT,'config','application.yml'))
         @mfg_list = config[:tirerack_mfg]
       end

       unless @mfg_list.nil?
         puts "Config file has manufacturers #{@mfg_list.join(', ')} to process...\n"
         manufacturers = @mfg_list
       else
         puts "No config file was found and no Manufacturers was specified. Try rake ct:update_tirerack MFG=Goodyear for example\n"
         exit
       end
     else
       manufacturers = [ENV['MFG']]
     end
     
     a = Mechanize.new { |agent| agent.user_agent_alias = 'Mac Safari'}
     page = a.get("http://www.tirerackwholesale.com/whlogin/Login.jsp")
     form = page.form_with(:name => "login")
     form.customerID = LOGIN_TIRERACK
     form.passWord = PWD_TIRERACK
     a.submit(form)
     page = a.get(URL_TIRERACK+'/tires/tirebran.jsp')
     # OK, the page is now available to click buttons in search of tires. we're logged in!
     # We are on the tire brand page and free to choose from any Brand available.
     # tires_data is an array of manufacturers we will write out to the result file
     tires_data = []
     while mfg = manufacturers.shift
       puts "Processing tire manufacturer: #{mfg}\n"
       out = open_file("tires",mfg)
       
       # we create a hash keyed on the model, where each model has variants, which is an array of hashes
       models = {}
       # now we have access to the Tire Rack Brand selection form. Loop through manufacturers for data
       href = Regexp.new(mfg, true)
       tire_brand = page.link_with(:href => href).click
       # Now that we are on a tire brand page, there are tons of clicks we can take to get us some tire info
       href = Regexp.new(Regexp.escape("tires/tires.jsp?tireMake=#{mfg}"))
       tire_brand.links_with(:href => href).each do |link|
          tire_model = link.href.split('=').last
          puts "#{mfg}, link: #{link.href} tire model: #{tire_model.gsub(/[+]/," ")}\n"
          # take me to this tires basic display page, where I can click a link for all the tires themselves
          tires = link.click
          # before scraping Prices and Sizes, get the description, and the specs for the Tire, as well as performance category
          # Description is on this page.. so we need to access it. We can also grab the images from this page.
          # Comment before description is <!--Insert Tire Copy here. If these is more than fits comfortably, it goes to a separate column in the database and displays in a new table row that spans across the table.-->
          description = ""
          desc_page = tires.search("//comment()['<!--Insert Tire Copy here. If these is more than fits comfortably, it goes to a separate column in the database and displays 
          in a new table row that spans across the table.-->']//following-sibling::p")
          unless desc_page.empty?
            desc_page[2..-1].each {|p| description += (p.content + "\n")}
          else
            description = "This tire has no Description from Tirerack. Please find one from another source."
          end
          
          # fill an array with the images associated with this tire model
          root = tires.search("//comment()[.=' If there is anything in the database for an optional image, \n     display it here instead of the normal images ']//following-sibling::table//tr")
          images = root[1].search("img").map {|img| img.attributes['src'].value}
          unless images.length
            images = root[2].search("img").map {|img| img.attributes['src'].value}
          end
          
          # download these precious images to the tire images directory we specified in the config
          images.each do |img|
            # sample file name... replace the _s with _l to get the large:    gy_wranglerdt_ci2_s.jpg
            base = File.basename(img).gsub(/_s.jpg/,'_l.jpg') 
            unless File.exists?(File.join(RAILS_ROOT, "public", "images", "tirerack", base))
              iuri =  URI.parse('http://www.tirerackwholesale.com/') + URI.parse(img.gsub(/_s.jpg/,'_l.jpg'))
              # write the binary image data to the public/images/wheels directory and be sure to log the filename too for later reference
              begin
                File.open(File.join(RAILS_ROOT, 'public','images','tirerack',File.basename(iuri.path)), 'wb') do | f |
                  f << iuri.read 
                end  
              rescue Timeout::Error
                puts "timed out trying to download #{File.basename(iuri.path)}"
              end
            else
              puts "Skipping download of already downloaded file #{base}\n"
            end  
          end
          
          # Next... Important Link: specs, setup the specifications structure
          spec_page = tires.link_with(:href => /Spec\.jsp/).click
          specifications = parse_specifications_document(spec_page)
          
          # once we have the spec page, we want to create a nice data structure we can re-use for the size/price scrape 
          # performance category will be assigned to the Tire itself via a property of the tire. 
          performance = spec_page.search("//comment()['Beginning of persistent tire nav']//following-sibling::table")[2].search("td")[1].search("a").first.content
          
          # now we can scrape the Sizes and Prices as usual. 
          tire_list = tires.link_with(:href => /Sizes\.jsp/).click
          
          # parse tire_list for the tables containing the info we want.
          size_pricing = []
          tire_list.search('//table[@cellpadding="3" and @style="border: 1px solid #ccc; border-collapse: collapse; margin-bottom: 4px;"]').each do |tire|
            size_pricing << tire.content.gsub(/\s/," ").squeeze(" ").strip()
          end
          
          # send the tire size and price listing and specifications to a parser.
          unless models.has_key?(tire_model)
            models[tire_model] = {
              :description => description,
              :images => images,
              :performance => performance,
              :variants => parse_size_pricing(size_pricing, specifications)
            }
          end
       end
       # save each Manufacturer, indexing on the model, ie) each tire model has an array of available sizes
        YAML.dump(models, out)
        out.close
     end
  end
end

namespace :ct do
  desc "Login to Direct Performance and Scrape Wheels"
  task :get_wheels => "clicktire:get_wheels"
  desc "Login to the Tire Rack and scrape data"
  task :scrape_tirerack => "clicktire:scrape_tirerack"
end

# helper functions for the rake tasks. Eventually make this some sort of Class based system
private

# if source contains only one entry, it is the only possible match, ie) size == size and that's it
# if source :details is an array > 1, we need to try and match the source data to the best one and return that one
# best match is both load_factor and speed_rating match
def self.find_matching_specification(source, match_source)
  matched = false
  source.each do |obj|
    if obj[:load_index] == match_source[:load_index] && obj[:speed_rating] == match_source[:speed_rating]
      source.merge!(match_source)
      matched = true
      break source
    elsif obj[:load_index] == match_source[:load_index] || obj[:speed_rating] == match_source[:speed_rating]
      source.merge!(match_source)
      matched = true
      break source
    end
  end
  source.merge!(match_source) unless matched
  return source
  # if we get here... then nothing to do... so return the merged results
end                                                       


# given a table in this data, extract the product code, the logo and the image name we need and it's download URL
def self.get_product_data(data)
  doc = Nokogiri.HTML(data.to_s)
  table1 = doc.search("table")[1]
  table2 = doc.search("table")[2]
  unless table1.nil? 
    unless table1.search("a").first.attributes['onclick'].nil?
      {
        :model => doc.search('table').first.search("td")[3].search("table").first.search('tr')[1].search('td').first.content.squeeze(" ").strip,
        :description => doc.search('table').first.search("td")[3].search("table").first.search('tr')[2].search('td').first.content.squeeze(" ").strip,
        :product_code => /[0-9]+/.match(table1.search("a").first.attributes['onclick'].value)[0],
        :image => table1.search("img").first.attributes['src'].value.gsub(/\.th\./,'.large.'),
        :logo => table2.search('img').first.attributes['src'].value     
      }
    end
  end
end

def open_file(prefix, mfg)
  if defined?(RAILS_ROOT)
    out = File.open(File.join(RAILS_ROOT, 'db',prefix,"#{mfg}.yml"),'w')
  else
    # we are not in a rails program so try writing out to the current directory
    out = File.open(File.join(__DIR__,prefix,"#{mfg}.yml"),'w')
  end
end 

def correct_details(details)
  description = details[:description].split(" ")
    if description.first.to_i > 0 
      digit = " " + description.shift
      details[:description] = description.join(" ")
      details[:model] += digit.to_s
      puts "had to correct details #{details}\n"
    end
  details
end

def parse_specifications_document(doc)
  # now we can steal specs and store them in a nice structure
  specifications = {}
  # this constant is based on a visual exam of the spec table, unlikely to change but you never know
  # we had to do this crazy row/column thing as the XPath was unable to parse the <tr> elements surrounding table rows.
  
  # not sure why we had trouble getting at the <tr> elements here, so we made up a row/col based management system
  data = doc.search('//table[@class="ruler"]/tbody/td')
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
    unless specifications.has_key?(size)
      specifications[size] = {
        :tire_details => []
      }
    end
    specifications[size][:tire_details] << {
      # utqg has a span element with hover text we want to remove, we already calculated that
      :utqg => data[UTQG+(r*COLUMNS)].search("a").first.content.gsub(hover_text,''),
      # weight is easy, just take the integer of whatever is in the fifth column
      :weight => data[WEIGHT+(r*COLUMNS)].content.to_i,
      :load_index => load_index,
      :speed_rating => speed_rating,
      :load_factor => load_factor
    }
  end
  specifications
end

def parse_size_pricing(list, specifications)
  variants = []
  list.each do |line|
    puts "#{line}\n"
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
    price = /(?:Price:\s?)\$([0-9]+\,?[0-9]+?\.[\d]{2})\s\(each\)(\$?([0-9]+\.[\d]{2})|Special|Closeout)?/.match(line)

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
      :size => size[1],
      :sidewall => size[2],
      :load_index => load_index,
      :speed_rating => speed_rating,
      :load_range => load_range,
      :price => price[2].nil? ? price[1].gsub(/,/,'').to_f : price[2].gsub(/,/,'').to_f,
      :availability => status,
      :level => level
    }
    
    # merge this result with the one from @specifications matching on size key

    if(specifications.has_key?(result[:size]))
      specs = specifications[result[:size]][:tire_details]
      # don't bother doing anything but a merge if only one exists
      if specs.length == 1 
        result.merge!(specs.first)
      else
        # try and find a match. first with multiple keys
        result.merge!(find_with_multiple_keys(result, specs)) 
      end
    end
    # push a new tire object onto the stack and do another...
    variants << result
  end
  variants
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
         puts "merged on both load_index and speed_rating"
         break match
     end
  end
  match
end
