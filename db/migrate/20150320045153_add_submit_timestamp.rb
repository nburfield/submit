class AddSubmitTimestamp < ActiveRecord::Migration
  def change
    add_column :submissions, :submit_time, :datetime
  end
end
