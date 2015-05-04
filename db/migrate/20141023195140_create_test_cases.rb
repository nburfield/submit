class CreateTestCases < ActiveRecord::Migration
  def change
    create_table :test_cases do |t|
      t.belongs_to :assignment, index: true

      t.timestamps
    end
  end
end
