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
end
