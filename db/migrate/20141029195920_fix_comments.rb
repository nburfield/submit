class FixComments < ActiveRecord::Migration
  def change
    rename_column :comments, :submission_id, :upload_datum_id
  end
end
