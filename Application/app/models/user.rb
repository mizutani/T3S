class User < TwitterAuth::GenericUser
  has_many :tweets
  has_many :groups
  has_many :projects, :through => :groups
end
