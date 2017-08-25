class AddSubmitKey < ActiveRecord::Migration
  def change
    add_column :submissions, :submit, :boolean
  end
end
