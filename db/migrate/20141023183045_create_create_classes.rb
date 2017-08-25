class CreateCreateClasses < ActiveRecord::Migration
  def change
    create_table :create_classes do |t|
      t.string :name
      t.boolean :open
      t.string :semester
      t.text :description
      t.string :join_token

      t.timestamps
    end
  end
end
