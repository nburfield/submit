class AddTotalGrade < ActiveRecord::Migration
  def change
    add_column :assignments, :total_grade, :float
  end
end
