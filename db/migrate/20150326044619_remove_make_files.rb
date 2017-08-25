class RemoveMakeFiles < ActiveRecord::Migration
  def change
    drop_table :makes
  end
end
