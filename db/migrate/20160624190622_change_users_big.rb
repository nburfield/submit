class ChangeUsersBig < ActiveRecord::Migration
  def change
    add_column :users, :first_name, :string, :default => ""
    add_column :users, :last_name, :string, :default => ""
    add_column :users, :netid, :string, :default => ""
    remove_column :users, :name, :string
    remove_column :users, :crypted_password, :string
    remove_column :users, :password_salt, :string
  end
end
