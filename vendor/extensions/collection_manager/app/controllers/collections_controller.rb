class CollectionsController < ApplicationController 
  #resource_controller
  require 'ap'
   
  def show
    ap params
    @products = retrieve_products
    @variants = retrieve_variants(@products)
    respond_to do |format|
      format.html
      format.js {
        render :update do |page|
          page.replace 'content', :partial => 'collections/results', :locals => {:variants => @variants, :products => @products}
        end
      }
    end
  end
 
  def retrieve_products
      @t = params[:t]
      @option = params[:option]
      @criteria = params[:criteria]
      
      # criteria has to be massaged   '245/45[A-Z]+16' 
      parts = params[:criteria].split('-')
      r = "#{parts.first}[A-Z]+#{parts.last}"
      
      per_page = params[:per_page].to_i
      per_page = per_page > 0 ? per_page : Spree::Config[:products_per_page]
      params[:per_page] = per_page
      params[:page] = 1 if (params[:page].to_i <= 0)
      
      # for brief second here, type will be wheels or tires, and the criteria will be the codeword for the option variant we are looking for.
      # to gather results then, first we get all the products with a variant that matches
      # then we whittle it down to return just the variants that match.. throw out the rest of the results
      
      curr_page = Spree::Config.searcher.manage_pagination ? 1 : params[:page]
      @products = Product.in_taxon(@t).with_option_value_regex(@option.to_s, r).all.paginate({
          :include  => [:images, :master],
          :per_page => per_page,
          :page     => curr_page
      })
      puts "\n\n\nProducts #{@products.inspect}\n\n\n"
      @products
     end
     
     def retrieve_variants(products)
        variants = []
        products.each do |product|
          if product.has_variants?
             product.variants.each do |variant|
               size = variant.find_by_option_type('size')
               # size will now be 255/45NR15 or something like that...
               # we were handed something like 255/45-15 now split in two... 
               # so we would like to map out so that the '-' substitutes for the R15, and we ignore any other letters... how to do that?
               variants << variant if size.gsub(/[A-Z]+/,'-') == @criteria && !variants.include?(variant)
             end
          end
        end
        variants
     end
        
end
