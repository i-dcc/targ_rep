class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string    :username, :null => false
      t.string    :email
      t.string    :crypted_password
      t.string    :password_salt
      t.string    :persistence_token
      t.datetime  :last_login_at
      t.boolean   :is_admin, :null => false, :default => 0 # User has special permissions
      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
