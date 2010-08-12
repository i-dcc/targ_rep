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
