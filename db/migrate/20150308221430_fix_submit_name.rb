class FixSubmitName < ActiveRecord::Migration
  def change
    rename_column :submissions, :submit, :submitted
  end
end
