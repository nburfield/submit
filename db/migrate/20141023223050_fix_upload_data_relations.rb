class FixUploadDataRelations < ActiveRecord::Migration
  def change
    remove_column :upload_data, :assignment_id, :belongs_to
    add_column :upload_data, :submission_id, :integer
    add_index :upload_data, :submission_id
    add_column :upload_data, :test_case_id, :integer
    add_index :upload_data, :test_case_id
  end
end
