class CreateGroups < ActiveRecord::Migration
  def self.up
    create_table :groups do |t|
      t.integer :user_id, :null => false
      t.integer :project_id, :null => false
      t.boolean :master, :default => false, :null => false
      t.boolean :admin, :default => false, :null => false
      
      t.timestamps
    end
  end

  def self.down
    drop_table :groups
  end
end
