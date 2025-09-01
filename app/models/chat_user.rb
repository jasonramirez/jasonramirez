class ChatUser < ActiveRecord::Base
  has_many :chat_messages, dependent: :destroy
  
  attr_accessor :password
  
  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, on: :create
  
  before_save :encrypt_password
  
  def self.authenticate(email, password)
    user = find_by(email: email)
    return nil unless user&.approved?
    return nil unless user&.can_login?
    return nil unless user.authenticate_password(password)
    
    # Set login expiration on first login
    user.set_login_expiration_on_first_login
    
    user
  end
  
  def approved?
    approved == true
  end
  
  def can_login?
    approved? && (login_expires_at.nil? || login_expires_at > Time.current)
  end
  
  def approve!
    update!(approved: true)
  end
  
  def set_login_expiration_on_first_login
    return if login_expires_at.present?
    
    update!(login_expires_at: 48.hours.from_now)
  end
  
  def authenticate_password(password)
    BCrypt::Password.new(password_digest) == password
  end
  
  private
  
  def encrypt_password
    return if password.blank?
    self.password_digest = BCrypt::Password.create(password)
  end
end
