module ClicktireHelper

  # feed me a Product, and I will provide you with some nice details for your template
  def product_details(product, taxon)
    case taxon
      when 'tire'
        'Tire Details'
      when 'wheel'
        'Wheel Details'
    end
  end
  
  
  
end
