# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def print_dash_on_nil_or_empty( arg )
    if [nil,''].include?(arg)
      return '-'
    else
      return arg
    end
  end
  
end
