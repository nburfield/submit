class UploadDataContentsSize < ActiveRecord::Migration
  def change
    change_column :upload_data, :contents, :binary, :limit => 10.megabyte
  end
end
