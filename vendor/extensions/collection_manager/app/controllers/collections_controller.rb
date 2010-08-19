class CollectionsController < ApplicationController 
  #resource_controller
  require 'ap'
   
  def show
    @products = retrieve_products
    ap @products
    render :partial => "results" 
  end
 
  def retrieve_products
    # incoming ...
    @taxon = params[:taxon]
    @option = params[:option]
    @criteria = params[:criteria]
   
    per_page = params[:per_page].to_i
    per_page = per_page > 0 ? per_page : Spree::Config[:products_per_page]
    params[:per_page] = per_page
    params[:page] = 1 if (params[:page].to_i <= 0)
    
    
    # for brief second here, type will be wheels or tires, and the criteria will be the codeword for the option variant we are looking for.
    # to gather results then, first we get all the products with a variant that matches
    # then we whittle it down to return just the variants that match.. throw out the rest of the results
    
    curr_page = Spree::Config.searcher.manage_pagination ? 1 : params[:page]
    ap "Attempting to find the correct matching products"
    products = Product.in_taxon(@taxon).with_option_value_regex(@option.to_s,@criteria.to_s)
    ap products.count
    
    end
    
    @products = Product.in_taxon(@type).with(@criteria).all.paginate({
        :include  => [:images, :master],
        :per_page => per_page,
        :page     => curr_page
      })
    @products_count = @products.count

    return(@products)
  end 
end
