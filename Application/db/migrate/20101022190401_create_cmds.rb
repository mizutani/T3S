class CreateCmds < ActiveRecord::Migration
  def self.up
    create_table :cmds do |t|
      t.string :cmd, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :cmds
  end
end
