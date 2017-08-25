class AddUploadDatumSharedFlag < ActiveRecord::Migration
  def change
    add_column :upload_data, :shared, :boolean
  end
end
