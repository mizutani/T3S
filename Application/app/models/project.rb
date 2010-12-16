class Project < ActiveRecord::Base
  has_many :tweets
  has_many :groups
  has_many :tickets
  has_many :users, :through => :groups
end
