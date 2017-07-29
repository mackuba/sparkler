class User < ApplicationRecord
  has_secure_password validations: false

  validates_presence_of :password
  validates_length_of :password,
    minimum: 6, maximum: ActiveModel::SecurePassword::MAX_PASSWORD_LENGTH_ALLOWED, allow_blank: true
  validates_confirmation_of :password, allow_blank: true


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
