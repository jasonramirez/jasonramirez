class ChatUser < ActiveRecord::Base
  has_many :chat_messages, dependent: :destroy
  
  attr_accessor :password, :access_type
  
  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, on: :create
  
  before_save :encrypt_password
  before_save :downcase_name
  
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
  
  def expired?
    login_expires_at.present? && login_expires_at <= Time.current
  end
  
  def extend_access_by_days(days)
    if login_expires_at.present?
      # If already has expiration, extend from current expiration or now (whichever is later)
      base_time = [login_expires_at, Time.current].max
      update!(login_expires_at: base_time + days.days)
    else
      # If no expiration set, start from now
      update!(login_expires_at: days.days.from_now)
    end
  end
  
  def set_unlimited_access
    update!(login_expires_at: nil)
  end
  
  def access_status
    return "pending" unless approved?
    return "unlimited" if login_expires_at.nil?
    return "expired" if expired?
    "active"
  end
  
  def current_access_type
    return nil unless approved?
    login_expires_at.nil? ? 'unlimited' : '48_hours'
  end
  
  def authenticate_password(password)
    BCrypt::Password.new(password_digest) == password
  end
  
  private
  
  def encrypt_password
    return if password.blank?
    self.password_digest = BCrypt::Password.create(password)
  end
  
  def downcase_name
    self.name = name.downcase if name.present?
  end
end
