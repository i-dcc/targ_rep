class User < ActiveRecord::Base
  acts_as_authentic
  model_stamper
  
  User.include_root_in_json = false
  
  public
    def to_json( options = {} )
      super(:only => [:id, :username])
    end
    
    def to_xml( options = {} )
      super(:only => [:id, :username])
    end
end

# == Schema Information
#
# Table name: users
#
#  id                 :integer(4)      not null, primary key
#  username           :string(255)     not null
#  email              :string(255)
#  crypted_password   :string(255)
#  password_salt      :string(255)
#  persistence_token  :string(255)
#  last_login_at      :datetime
#  is_admin           :boolean(1)      default(FALSE), not null
#  created_at         :datetime
#  updated_at         :datetime
#  login_count        :integer(4)      default(0), not null
#  failed_login_count :integer(4)      default(0), not null
#  last_request_at    :datetime
#  current_login_at   :datetime
#  current_login_ip   :string(255)
#  last_login_ip      :string(255)
#

