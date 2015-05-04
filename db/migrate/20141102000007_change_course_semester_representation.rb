class ChangeCourseSemesterRepresentation < ActiveRecord::Migration
  def change
    remove_column :courses, :semester, :string
    add_column :courses, :year, :integer
    add_column :courses, :term, :string
  end
end
