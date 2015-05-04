class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.text :contents
      t.integer :line
      t.belongs_to :submission, index: true

      t.timestamps
    end
  end
end
