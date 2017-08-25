class AddDefaultNameMake < ActiveRecord::Migration
  def change
    change_column :makes, :name, :string, :default => "Makefile"
  end
end
