require "rails_helper"

RSpec.describe Admins::ChatUsersController, type: :controller do
  let(:admin) { create(:admin) }
  
  before do
    sign_in admin, scope: :admin
  end

  describe "GET #new" do
    it "returns a successful response" do
      get :new
      expect(response).to be_successful
    end

    it "assigns a new chat user" do
      get :new
      expect(assigns(:chat_user)).to be_a_new(ChatUser)
    end
  end

  describe "POST #create" do
    let(:valid_attributes) do
      {
        name: "Test User",
        email: "test@example.com",
        password: "password123",
        approved: true
      }
    end

    let(:invalid_attributes) do
      {
        name: "",
        email: "invalid-email",
        password: "123",
        approved: false
      }
    end

    context "with valid parameters" do
      it "creates a new chat user" do
        expect {
          post :create, params: { chat_user: valid_attributes }
        }.to change(ChatUser, :count).by(1)
      end

      it "redirects to the chat users index" do
        post :create, params: { chat_user: valid_attributes }
        expect(response).to redirect_to(admins_chat_users_path)
      end

      it "sets a success flash message" do
        post :create, params: { chat_user: valid_attributes }
        expect(flash[:notice]).to include("created successfully")
      end

      it "assigns the correct attributes to the chat user" do
        post :create, params: { chat_user: valid_attributes }
        chat_user = ChatUser.last
        expect(chat_user.name).to eq("test user") # downcased
        expect(chat_user.email).to eq("test@example.com")
        expect(chat_user.approved).to be true
      end
    end

    context "with invalid parameters" do
      it "does not create a new chat user" do
        expect {
          post :create, params: { chat_user: invalid_attributes }
        }.not_to change(ChatUser, :count)
      end

      it "renders the new template" do
        post :create, params: { chat_user: invalid_attributes }
        expect(response).to render_template(:new)
      end

      it "assigns the chat user with errors" do
        post :create, params: { chat_user: invalid_attributes }
        expect(assigns(:chat_user).errors).not_to be_empty
      end
    end

    context "with Turbo Stream format" do
      it "handles Turbo Stream requests for validation errors" do
        post :create, params: { chat_user: invalid_attributes }, format: :turbo_stream
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end
    end
  end

  describe "GET #index" do
    let!(:chat_user1) { create(:chat_user, name: "User 1") }
    let!(:chat_user2) { create(:chat_user, name: "User 2") }


  end

  describe "GET #show" do
    let(:chat_user) { create(:chat_user) }

    it "returns a successful response" do
      get :show, params: { id: chat_user.id }
      expect(response).to be_successful
    end

    it "assigns the requested chat user" do
      get :show, params: { id: chat_user.id }
      expect(assigns(:chat_user)).to eq(chat_user)
    end

    it "assigns the chat user's messages" do
      get :show, params: { id: chat_user.id }
      expect(assigns(:chat_messages)).to eq(chat_user.chat_messages.ordered)
    end
  end

  describe "GET #edit" do
    let(:chat_user) { create(:chat_user) }

    it "returns a successful response" do
      get :edit, params: { id: chat_user.id }
      expect(response).to be_successful
    end

    it "assigns the requested chat user" do
      get :edit, params: { id: chat_user.id }
      expect(assigns(:chat_user)).to eq(chat_user)
    end
  end

  describe "PATCH #update" do
    let(:chat_user) { create(:chat_user, name: "Original Name") }
    let(:valid_attributes) { { name: "Updated Name" } }
    let(:invalid_attributes) { { name: "" } }

    context "with valid parameters" do
      it "updates the chat user" do
        patch :update, params: { id: chat_user.id, chat_user: valid_attributes }
        chat_user.reload
        expect(chat_user.name).to eq("updated name") # downcased
      end

      it "redirects to the edit page" do
        patch :update, params: { id: chat_user.id, chat_user: valid_attributes }
        expect(response).to redirect_to(edit_admins_chat_user_path(chat_user))
      end

      it "sets a success flash message" do
        patch :update, params: { id: chat_user.id, chat_user: valid_attributes }
        expect(flash[:notice]).to include("updated successfully")
      end
    end

    context "with invalid parameters" do
      it "does not update the chat user" do
        patch :update, params: { id: chat_user.id, chat_user: invalid_attributes }
        chat_user.reload
        expect(chat_user.name).to eq("original name")
      end

      it "renders the edit template" do
        patch :update, params: { id: chat_user.id, chat_user: invalid_attributes }
        expect(response).to render_template(:edit)
      end
    end

    context "with access_type parameter" do
      it "handles 48_hours access type" do
        patch :update, params: { 
          id: chat_user.id, 
          chat_user: { name: "Updated", access_type: "48_hours" } 
        }
        chat_user.reload
        expect(chat_user.login_expires_at).to be_within(1.minute).of(48.hours.from_now)
      end

      it "handles unlimited access type" do
        chat_user.update!(login_expires_at: 1.hour.from_now)
        patch :update, params: { 
          id: chat_user.id, 
          chat_user: { name: "Updated", access_type: "unlimited" } 
        }
        chat_user.reload
        expect(chat_user.login_expires_at).to be_nil
      end
    end
  end
end
