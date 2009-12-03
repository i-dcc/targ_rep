class User < ActiveRecord::Base

  # === List of columns ===
  #   id                : integer 
  #   username          : string 
  #   email             : string 
  #   crypted_password  : string 
  #   password_salt     : string 
  #   persistence_token : string 
  #   last_login_at     : datetime 
  #   is_admin          : boolean 
  #   created_at        : datetime 
  #   updated_at        : datetime 
  # =======================

  acts_as_authentic
  
  User.include_root_in_json = false
  
  public
    def to_json( options = {} )
      super(:only => [:id, :username])
    end
    
    def to_xml( options = {} )
      super(:only => [:id, :username])
    end
end
