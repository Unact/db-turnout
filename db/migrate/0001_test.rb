class Test < ActiveRecord::Migration
  def change
    create_table :test_table do |t|
      t.string :name
      t.index :name, unique: true
      
      t.integer :val
    end
  end
end
