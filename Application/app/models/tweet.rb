class Tweet < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  belongs_to :cmd
  belongs_to :ticket
  scope :user_and_ticket, lambda {|x, y|
    joins(:user, :ticket).
    where(:user_id => x, :ticket_id => y).
    order(:time)
  }
  scope :today_join_ticket, lambda {|x, y|
    joins(:ticket).
    time_between(x, y).
    select('distinct ticket_id')
   
  }
  scope :today_join_project, lambda {|x, y|
    joins(:project).
    time_between(x, y)
    select('distinct project_id')
  }
  scope :users, lambda {|x|
    joins(:user).
    where(:users => {:id => x})
  }
  scope :project, lambda {
    joins(:project).
    where(:projects => {:name => y}).
    order(:time)
  }
  scope :work_time, lambda {
    joins(:cmd).
    where(:cmd_id => 1..4)
  }
  scope :time_between, lambda {|x, y|
    where(:time => x..y).
    order(:time)
  }
end
