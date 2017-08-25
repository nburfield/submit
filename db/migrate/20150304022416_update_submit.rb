class UpdateSubmit < ActiveRecord::Migration
  def change
    change_column :submissions, :submit, :boolean, :default => false
  end
end
