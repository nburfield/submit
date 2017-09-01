class CreateRunSaves < ActiveRecord::Migration
  def change
    create_table :run_saves do |t|
      t.references :submission, index: true

      t.text :difference
      t.boolean :pass
      t.text :output
      t.string :input_name

      t.timestamps
    end
  end
end
