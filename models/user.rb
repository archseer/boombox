require 'bcrypt'
class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include BCrypt

  validates_uniqueness_of :username

  field :username,      type: String
  field :password_hash, type: String

  def password
    @password ||= Password.new(password_hash)
  end

  def password=(new_password)
    @password = Password.create(new_password)
    self.password_hash = @password
  end

  def authenticate(attempted_password)
    self.password == attempted_password
  end
end
