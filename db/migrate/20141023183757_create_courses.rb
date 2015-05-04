class CreateCourses < ActiveRecord::Migration
  def change
    create_table :courses do |t|
      t.string :name
      t.boolean :open
      t.string :semester
      t.text :description
      t.string :join_token

      t.timestamps
    end

    create_table :courses_users, id: false do |t|
      t.belongs_to :course
      t.belongs_to :user
    end
  end
end
