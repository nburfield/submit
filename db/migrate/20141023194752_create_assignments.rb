class CreateAssignments < ActiveRecord::Migration
  def change
    create_table :assignments do |t|
      t.boolean :lock
      t.datetime :due_date
      t.datetime :start_date
      t.text :description
      t.belongs_to :course, index: true

      t.timestamps
    end
  end
end
