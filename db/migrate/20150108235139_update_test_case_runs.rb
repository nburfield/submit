class UpdateTestCaseRuns < ActiveRecord::Migration
  def change
    add_column :test_cases, :cpu_time, :integer, :default => 10
    add_column :test_cases, :core_size, :integer, :default => 0
  end
end
