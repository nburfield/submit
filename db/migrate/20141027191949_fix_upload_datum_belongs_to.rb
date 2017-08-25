class FixUploadDatumBelongsTo < ActiveRecord::Migration
  def change
    change_column :upload_data, :test_case_id, :integer, :null => true
    change_column :upload_data, :submission_id, :integer, :null => true
  end
end
