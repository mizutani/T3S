class Ticket < ActiveRecord::Base
  belongs_to :project
  has_many :tweets
end
