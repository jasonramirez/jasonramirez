require 'rails_helper'

RSpec.describe Admin, type: :model do
  describe "devise modules" do
    it "includes expected devise modules" do
      expect(Admin.devise_modules).to include(:database_authenticatable)
      expect(Admin.devise_modules).to include(:registerable)
      expect(Admin.devise_modules).to include(:recoverable)
      expect(Admin.devise_modules).to include(:rememberable)
      expect(Admin.devise_modules).to include(:validatable)
    end
  end

  describe "validations" do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:password) }
    it { should validate_length_of(:password).is_at_least(6) }
  end

  describe "database columns" do
    it "has the expected columns" do
      expect(Admin.column_names).to include('id', 'email', 'encrypted_password', 'created_at', 'updated_at')
    end
  end

  describe "authentication" do
    let(:admin) { create(:admin, email: 'admin@example.com', password: 'password123') }

    it "can authenticate with valid credentials" do
      expect(admin.valid_password?('password123')).to be true
    end

    it "cannot authenticate with invalid credentials" do
      expect(admin.valid_password?('wrongpassword')).to be false
    end
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:admin)).to be_valid
    end

    it "creates admin with valid attributes" do
      admin = create(:admin)
      expect(admin.email).to be_present
      expect(admin.encrypted_password).to be_present
    end
  end
end
