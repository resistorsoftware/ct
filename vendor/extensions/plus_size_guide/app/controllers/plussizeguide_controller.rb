class PlussizeguideController < ApplicationController  
  
  CREDENTIALS = {
    'userName' => 'urbanauto',
    'password' => 'GVR94Z',
    'licenseKey' => 'R63FS38D77HRV'
  }
  
  def index
    @year = params[:year] ||= ''
    @make = params[:make] ||= ''
    @model = params[:model] ||= ''
    p = params.merge!(CREDENTIALS)
    @res = Net::HTTP.post_form(URI.parse('http://www.plussizingguide.com/xml/plusguidexml.php'), p)
    doc = Nokogiri::XML(@res.body)
    puts "result is #{doc}\n"
    @year = doc.xpath('//year')
    @make = doc.xpath('//make')
    @model = doc.xpath('//model')
    respond_to do |format|
      format.json do
        result = {}       
        if @year.is_a?(Nokogiri::XML::NodeSet)
          result.merge!({:year => @year.map(&:content)})
        end
        if @make.is_a?(Nokogiri::XML::NodeSet)
          result.merge!({:make => @make.map(&:content)})
        end
        if @model.is_a?(Nokogiri::XML::NodeSet)
          @wheel = doc.search('wheel').first
          unless @wheel.nil?
            wheel = {
              :bolt_pattern => @wheel.search("bpmet").first.content,
              :offset => @wheel.search("offsetmm").first.content,
              :hub => @wheel.search("hub").first.content,
              :lug => @wheel.search("lug").first.content
            }
          end
          
          tires = []
          doc.search("tire").each do |tire|
            tires << {
              :inches => "#{tire.search('plus').first.content.gsub(/OE-|PLUS-|\*PLUS-/, '')} inch",
              :oe => tire.search('plus').first.content,#.gsub(/OE/,'Original Equipment'),
              :tiresize => tire.search('size').first.content.gsub(/-\d{0,2}/,'')
              #:tirecount => {:tirecount => doc.search("tirecount").first.content}
            }
          end
          result.merge!({
            :model => @model.map(&:content),
            :wheel => wheel,
            :tires => tires
          })
        end
        
        response.content_type = "application/json"
        render :json => result
      end
       
      format.html {}
    end
      
  end
  
end
