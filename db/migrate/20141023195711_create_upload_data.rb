class CreateUploadData < ActiveRecord::Migration
  def change
    create_table :upload_data do |t|
      t.string :name
      t.binary :contents
      t.belongs_to :assignment, index: true

      t.timestamps
    end
  end
end
