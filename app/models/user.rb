class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(address) { address.strip.downcase }

  validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validate :only_user, on: :create

  private

  def only_user
    errors.add(:base, "A user already exists") if User.exists?
  end
end
