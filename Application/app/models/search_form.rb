class SearchForm
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  
  attr_accessor :x
  def initialize params, key
    self.x = params[key] if params
  end
  
  def persisted?
    false
  end
end
