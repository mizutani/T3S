class Group < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  scope :user_in_projects, lambda {|x|
    joins(:user, :project).
    where(:users => {:login => x})
  }
  scope :project_in_users, lambda {|x|
    joins(:user, :project).
    where(:projects => {:name => x})
  }
  scope :projects, lambda {|x|
    joins(:project).
    where(:user_id => x)
  }
end
