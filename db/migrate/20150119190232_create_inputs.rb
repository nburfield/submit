class CreateInputs < ActiveRecord::Migration
  def change
    create_table :inputs do |t|
      t.string :name
      t.text :description
      t.text :data
      t.text :output
      t.boolean :student_visible
      t.belongs_to :run_method, index: true

      t.timestamps
    end
  end
end
