class ChangeSavedOutputToBlobs < ActiveRecord::Migration
  def up
    change_column :inputs, :output, :binary
    change_column :run_saves, :difference, :binary
    change_column :run_saves, :output, :binary
  end

  def down
    change_column :inputs, :output, :text
    change_column :run_saves, :difference, :text
    change_column :run_saves, :output, :text
  end
end
