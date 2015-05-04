class AddAssignmentName < ActiveRecord::Migration
  def change
    add_column :assignments, :name, :string
  end
end
