class CreateMakes < ActiveRecord::Migration
  def change
    create_table :makes do |t|
      t.string :name
      t.belongs_to :test_case
      t.text :data

      t.timestamps
    end
  end
end
