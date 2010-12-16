class CreateTweets < ActiveRecord::Migration
  def self.up
    create_table :tweets do |t|
      #t.integer :tweet_log_id
      #t.string :tweet_log_type
      t.integer :user_id, :null => false
      t.integer :project_id
      t.integer :ticket_id
      t.integer :cmd_id, :null => false
      t.string :url, :null => false
      t.datetime :time, :null => false
      t.string :comment
      t.timestamps
    end
    add_index(:tweets, :url, :unique => true)
  end

  def self.down
    drop_table :tweets
  end
end
