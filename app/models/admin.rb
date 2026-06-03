class Admin < ActiveRecord::Base
  devise :database_authenticatable, :rememberable, :registerable, :validatable
end
