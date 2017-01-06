class CreateCompileSaves < ActiveRecord::Migration
  def change
    create_table :compile_saves do |t|
    	t.references :submission, index: true
      

      
      t.text :output
      t.string :run_method_name

     
    end
  end
end
