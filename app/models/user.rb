class User < ActiveRecord::Base
  has_secure_password

  def self.find_admin
    user = User.first

    if user.nil?
      user = User.new
      user.save(validate: false)
    end

    user
  end

  def has_password?
    password_digest.present?
  end
end
