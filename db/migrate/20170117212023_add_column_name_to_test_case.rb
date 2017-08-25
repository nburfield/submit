class AddColumnNameToTestCase < ActiveRecord::Migration
  def change
    add_column :test_cases, :column_name, :string
  end
end
