class AddKeyToTestCase < ActiveRecord::Migration
  def change
    add_column :test_cases, :key, :string
  end
end
