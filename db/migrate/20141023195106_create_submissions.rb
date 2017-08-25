class CreateSubmissions < ActiveRecord::Migration
  def change
    create_table :submissions do |t|
      t.float :grade
      t.text :note
      t.belongs_to :assignment, index: true
      t.belongs_to :user, index: true

      t.timestamps
    end
  end
end
