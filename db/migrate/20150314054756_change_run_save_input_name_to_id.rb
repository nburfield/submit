class ChangeRunSaveInputNameToId < ActiveRecord::Migration
  def change
    remove_column :run_saves, :input_name
    add_column :run_saves, :input_id, :integer
  end
end
