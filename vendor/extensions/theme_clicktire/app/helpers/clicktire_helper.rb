module ClicktireHelper

  # feed me a Tire and I will give you the property you asked for
  def tire_properties(product, property)
    p = Property.find_by_name(property)
    result = ''
    product.product_properties.each do |pp|
      if pp.property_id == p.id
        result = pp.value
      end
    end
    result
  end 
  
  # given an array of options, send back a string for a tooltip
  def tire_options(list)
    result = '' 
    list.each do |option|
      
    end
  end
  
end
