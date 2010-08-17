# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def print_dash_on_empty( arg )
    if [nil,''].include?(arg)
      return '-'
    else
      return arg
    end
  end
  
  def javascript(*files)
    content_for(:head) { javascript_include_tag(*files) }
  end
  
  def stylesheet(*files)
    content_for(:head) { stylesheet_link_tag(*files) }
  end
  
end
