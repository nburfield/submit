class AddTestCaseIdToCompileSaves < ActiveRecord::Migration
  def change
    add_column :compile_saves, :test_case_id, :integer
  end
end
