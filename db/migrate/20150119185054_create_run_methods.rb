class CreateRunMethods < ActiveRecord::Migration
  def change
    create_table :run_methods do |t|
      t.string :name
      t.string :run_command
      t.text :description
      t.belongs_to :test_case, index: true

      t.timestamps
    end
  end
end
