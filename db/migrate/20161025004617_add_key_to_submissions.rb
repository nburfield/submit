class AddKeyToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :key, :string
  end
end
