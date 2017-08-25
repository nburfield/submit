class AddFileType < ActiveRecord::Migration
  def change
  	add_column :upload_data, :file_type, :string
  end
end
