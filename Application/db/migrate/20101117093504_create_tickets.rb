class CreateTickets < ActiveRecord::Migration
  def self.up
    create_table :tickets do |t|
      t.integer :project_id, :null => false
      t.string :name, :null => false
      t.string :outline
      t.timestamps
    end
    add_index(:tickets, :name, :unique => true)
  end

  def self.down
    drop_table :tickets
  end
end
