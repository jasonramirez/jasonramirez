require "rails_helper"

RSpec.describe ChatUser, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    
    describe "email format validation" do
      it "validates email format" do
        user = ChatUser.new(name: "Test", email: "invalid-email", password: "password123")
        expect(user).to_not be_valid
        expect(user.errors[:email]).to include("is invalid")
      end
      
      it "accepts valid email format" do
        user = ChatUser.new(name: "Test", email: "test@example.com", password: "password123")
        user.valid?
        expect(user.errors[:email]).to be_empty
      end
    end
    
    describe "password validation" do
      it "validates password presence on create" do
        user = ChatUser.new(name: "Test", email: "test@example.com")
        expect(user).to_not be_valid
        expect(user.errors[:password]).to include("can't be blank")
      end
      
      it "validates password minimum length" do
        user = ChatUser.new(name: "Test", email: "test@example.com", password: "123")
        expect(user).to_not be_valid
        expect(user.errors[:password]).to include("is too short (minimum is 6 characters)")
      end
    end
  end

  describe "associations" do
    it { should have_many(:chat_messages).dependent(:destroy) }
  end

  describe "authentication" do
    let!(:user) { create(:chat_user, email: "test@example.com", password: "password123", login_expires_at: nil) }
    
    describe ".authenticate" do
      context "with valid credentials and approved user" do
        it "returns the user" do
          authenticated_user = ChatUser.authenticate("test@example.com", "password123")
          expect(authenticated_user).to eq(user)
        end
        
        it "sets login expiration on first login" do
          expect(user.login_expires_at).to be_nil
          ChatUser.authenticate("test@example.com", "password123")
          user.reload
          expect(user.login_expires_at).to be_within(1.minute).of(48.hours.from_now)
        end
      end
      
      context "with invalid credentials" do
        it "returns nil for wrong password" do
          authenticated_user = ChatUser.authenticate("test@example.com", "wrongpassword")
          expect(authenticated_user).to be_nil
        end
        
        it "returns nil for wrong email" do
          authenticated_user = ChatUser.authenticate("wrong@example.com", "password123")
          expect(authenticated_user).to be_nil
        end
      end
      
      context "with unapproved user" do
        let(:unapproved_user) { create(:chat_user, email: "unapproved@example.com", password: "password123", approved: false) }
        
        it "returns nil" do
          authenticated_user = ChatUser.authenticate("unapproved@example.com", "password123")
          expect(authenticated_user).to be_nil
        end
      end
    end
  end

  describe "approval methods" do
    let(:user) { create(:chat_user, email: "test@example.com", password: "password123", approved: false) }
    
    describe "#approved?" do
      it "returns false for unapproved user" do
        expect(user.approved?).to be false
      end
      
      it "returns true for approved user" do
        user.update!(approved: true)
        expect(user.approved?).to be true
      end
    end
    
    describe "#approve!" do
      it "sets approved to true" do
        user.approve!
        expect(user.approved?).to be true
      end
    end
  end

  describe "access management" do
    let(:user) { create(:chat_user, email: "test@example.com", password: "password123") }
    
    describe "#can_login?" do
      context "when approved and not expired" do
        before { user.update!(login_expires_at: 1.hour.from_now) }
        
        it "returns true" do
          expect(user.can_login?).to be true
        end
      end
      
      context "when approved but expired" do
        before { user.update!(login_expires_at: 1.hour.ago) }
        
        it "returns false" do
          expect(user.can_login?).to be false
        end
      end
      
      context "when not approved" do
        before { user.update!(approved: false) }
        
        it "returns false" do
          expect(user.can_login?).to be false
        end
      end
      
      context "when approved with unlimited access" do
        before { user.update!(login_expires_at: nil) }
        
        it "returns true" do
          expect(user.can_login?).to be true
        end
      end
    end
    
    describe "#expired?" do
      it "returns true when login_expires_at is in the past" do
        user.update!(login_expires_at: 1.hour.ago)
        expect(user.expired?).to be true
      end
      
      it "returns false when login_expires_at is in the future" do
        user.update!(login_expires_at: 1.hour.from_now)
        expect(user.expired?).to be false
      end
      
      it "returns false when login_expires_at is nil (unlimited)" do
        user.update!(login_expires_at: nil)
        expect(user.expired?).to be false
      end
    end
    
    describe "#extend_access_by_days" do
      context "when user has existing expiration" do
        before { user.update!(login_expires_at: 1.hour.from_now) }
        
        it "extends access from the later of current expiration or now" do
          original_expiration = user.login_expires_at
          user.extend_access_by_days(2)
          expect(user.login_expires_at).to be_within(1.minute).of(original_expiration + 2.days)
        end
      end
      
      context "when user has no expiration" do
        before { user.update!(login_expires_at: nil) }
        
        it "sets expiration to specified days from now" do
          user.extend_access_by_days(2)
          expect(user.login_expires_at).to be_within(1.minute).of(2.days.from_now)
        end
      end
      
      context "when user is expired" do
        before { user.update!(login_expires_at: 1.hour.ago) }
        
        it "extends access from current time" do
          user.extend_access_by_days(2)
          expect(user.login_expires_at).to be_within(1.minute).of(2.days.from_now)
        end
      end
    end
    
    describe "#set_unlimited_access" do
      before { user.update!(login_expires_at: 1.hour.from_now) }
      
      it "removes expiration" do
        user.set_unlimited_access
        expect(user.login_expires_at).to be_nil
      end
    end
    
    describe "#access_status" do
      context "when not approved" do
        before { user.update!(approved: false) }
        
        it "returns 'pending'" do
          expect(user.access_status).to eq("pending")
        end
      end
      
      context "when approved with unlimited access" do
        before { user.update!(login_expires_at: nil) }
        
        it "returns 'unlimited'" do
          expect(user.access_status).to eq("unlimited")
        end
      end
      
      context "when approved and expired" do
        before { user.update!(login_expires_at: 1.hour.ago) }
        
        it "returns 'expired'" do
          expect(user.access_status).to eq("expired")
        end
      end
      
      context "when approved and active" do
        before { user.update!(login_expires_at: 1.hour.from_now) }
        
        it "returns 'active'" do
          expect(user.access_status).to eq("active")
        end
      end
    end
    
    describe "#current_access_type" do
      context "when not approved" do
        before { user.update!(approved: false) }
        
        it "returns nil" do
          expect(user.current_access_type).to be_nil
        end
      end
      
      context "when approved with unlimited access" do
        before { user.update!(login_expires_at: nil) }
        
        it "returns 'unlimited'" do
          expect(user.current_access_type).to eq("unlimited")
        end
      end
      
      context "when approved with time-limited access" do
        before { user.update!(login_expires_at: 1.hour.from_now) }
        
        it "returns '48_hours'" do
          expect(user.current_access_type).to eq("48_hours")
        end
      end
    end
  end
end
