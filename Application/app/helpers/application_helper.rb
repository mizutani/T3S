module ApplicationHelper
  IMAGE_EXTENSIONS = ["jpg","gif","png","jpeg","png"]
  FILE_EXTENSIONS = ["html","htm","cfm","asp","php","rb","rhtml","txt"]
  REQUEST_TYPES = {
    :image => 1,
    :inline => 2,
    :ajax => 3
  }
  def link_to_ibox(content="",options = {})
    options[:for] ||= ""
    options[:size] ||= :auto
    options[:title] ||= options[:for]
    options[:type] ||= determine_file_type(options[:for])
    
    width, height = options[:size].split("x")[0], options[:size].split("x")[1] unless options[:size].is_a?(Symbol)
    rel = options[:size] == :auto ? "ibox&type=#{REQUEST_TYPES[options[:type]]}" : "ibox&width=#{width}&height=#{height}&type=#{REQUEST_TYPES[options[:type]]}"
    
    keys_to_remove = [:for,:size,:type]
    html_options = {}
    options.each {|key,value| html_options.update(key => value) unless keys_to_remove.include?(key)}
    html_options.update(:rel => rel)
    
    link_to content, (options[:for]), html_options
  end 
  def determine_file_type(type)
    request_type = type.split(".").last
    return :image if IMAGE_EXTENSIONS.include?(request_type)
    return :ajax if FILE_EXTENSIONS.include?(request_type) || type.first != "#"
    return :inline
  end
end
