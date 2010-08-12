# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include ExceptionNotification::Notifiable
  include Userstamp
  
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
    
    def ensure_creator_or_admin
      changed_object =
        if    @allele           then @allele
        elsif @targeting_vector then @targeting_vector
        elsif @es_cell          then @es_cell
        elsif @genbank_file     then @genbank_file
        else
          raise "Expecting one of the following objects: @allele, @targeting_vector, @es_cell or @genbank_file"
        end
      
      if @current_user.id == changed_object.created_by or @current_user.is_admin
        # All is fine - move along...
      else
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
    
    # Helper function that search against the SolR index according to the given solr_args 
    def search_solr( solr_args )
      raise "solr_args should at least contain a ':q' key" unless solr_args.has_key? :q
      
      unless defined? @solr
        @solr = RSolr.connect :url => 'http://www.sanger.ac.uk/mouseportal/solr'
      end
      
      @solr.select( solr_args )
    end
    
    # Helper function to slurp in all of the ES Cell QC descriptors
    def get_qc_field_descriptions
      @qc_field_descs = {}
      QcFieldDescription.all.each do |desc|
        @qc_field_descs[ desc.qc_field.to_sym ] = desc
      end
    end
end