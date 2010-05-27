# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # See ActionController::RequestForgeryProtection for details
  protect_from_forgery
  
  before_filter :require_user
  before_filter :current_user
  
  helper :all # include all helpers, all the time
  helper_method :current_user_session, :current_user
  
  # Scrub sensitive parameters from your log
  filter_parameter_logging :password, :password_confirmation
  
  # Scrub genbank files from log as it is huge
  filter_parameter_logging :genbank_file
  
  protected
    def current_user_session
      return @current_user_session if defined?(@current_user_session)
      @current_user_session = UserSession.find
    end
    
    def current_user
      return @current_user if defined?(@current_user)
      @current_user = current_user_session && current_user_session.user
    end
    
    def require_user
      unless current_user
        store_location
        respond_to do |format|
          format.html {
            flash[:notice] = "You must be logged in to access this page"
            redirect_to new_user_session_url
          }
          # Send back a 401 unauthorized if requesting for JSON or XML.
          format.all {
            headers['WWW-Authenticate'] = 'Basic realm="IKMC Targeting Repository"'
            head :unauthorized
          }
        end
      end
    end
    
    def require_no_user
      if current_user
        store_location
        flash[:notice] = "You must be logged out to access this page"
        redirect_to root_url
        return false
      end
    end
    
    def store_location
      session[:return_to] = request.request_uri
    end
    
    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end
    
    def require_admin
      require_user
      
      if @current_user and !@current_user.is_admin
        flash[:error] = "You are not allowed to access this page."
        redirect_to root_url
      end
    end
    
    def ensure_permission
      changed_object =
        if @molecular_structure then @molecular_structure
        elsif @targeting_vector then @targeting_vector
        elsif @es_cell          then @es_cell
        elsif @genbank_file     then @genbank_file
        else
          raise "Expecting one of the following objects: @molecular_structure, @targeting_vector, @es_cell or @genbank_file"
        end
      
      if not changed_object.has_attribute? 'created_by'
        raise "Expecting the object to have a 'created_by' attribute."
      end
      
      if current_user != changed_object.created_by and !@current_user.is_admin
        error_msg = "You are not allowed to perform this action"
        
        respond_to do |format|
          format.html {
            flash[:error] = error_msg
            redirect_to root_url
          }
          format.xml  { render :xml   => error_msg, :status => :forbidden }
          format.json { render :json  => error_msg, :status => :forbidden }
        end
      end
    end
  
  private
    def set_created_by
      controller_name = params['controller'][0..-2] # remove the ending 's'
      params[controller_name].update({ :created_by => current_user })
    end
    
    def set_updated_by
      controller_name = params['controller'][0..-2] # remove the ending 's'
      params[controller_name].update({ :updated_by => current_user })
    end
end