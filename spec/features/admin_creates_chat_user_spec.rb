require "rails_helper"

RSpec.feature "Admin creates chat user", type: :feature do
  let(:admin) { create(:admin) }
  
  before do
    sign_in_admin admin
  end

  scenario "Admin successfully creates a new chat user" do
    visit new_admins_chat_user_path
    
    fill_in "Name", with: "Test User"
    fill_in "Email", with: "test@example.com"
    fill_in "Password", with: "password123"
    check "Approved", allow_label_click: true
    
    click_button "Create User"
    
    expect(page).to have_content("Chat user 'test user' created successfully")
    expect(page).to have_current_path(admins_chat_users_path)
    
    # Verify the user was created in the database
    chat_user = ChatUser.find_by(email: "test@example.com")
    expect(chat_user).to be_present
    expect(chat_user.name).to eq("test user") # downcased
    expect(chat_user.approved).to be true
  end

  scenario "Admin creates an unapproved chat user" do
    visit new_admins_chat_user_path
    
    fill_in "Name", with: "Pending User"
    fill_in "Email", with: "pending@example.com"
    fill_in "Password", with: "password123"
    # Don't check the approved checkbox
    
    click_button "Create User"
    
    expect(page).to have_content("Chat user 'pending user' created successfully")
    expect(page).to have_current_path(admins_chat_users_path)
    
    # Verify the user was created but not approved
    chat_user = ChatUser.find_by(email: "pending@example.com")
    expect(chat_user).to be_present
    expect(chat_user.approved).to be false
  end

  scenario "Admin sees validation errors for invalid input" do
    visit new_admins_chat_user_path
    
    fill_in "Name", with: ""
    fill_in "Email", with: "invalid-email"
    fill_in "Password", with: "123"
    
    click_button "Create User"
    
    # Should stay on the new form when validation fails  
    expect(page).to have_current_path(new_admins_chat_user_path) # Should show new form again
    expect(page).to have_content("New Chat User") # Should show the form again
    
    # Verify no user was created with invalid data
    expect(ChatUser.where(email: "invalid-email")).to be_empty
  end

  scenario "Admin can cancel creating a chat user" do
    visit new_admins_chat_user_path
    
    click_link "Cancel"
    
    expect(page).to have_current_path(admins_chat_users_path)
  end

  scenario "Admin can view the chat users index" do
    chat_user1 = create(:chat_user, name: "User 1", email: "user1@example.com")
    chat_user2 = create(:chat_user, name: "User 2", email: "user2@example.com")
    
    visit admins_chat_users_path
    
    expect(page).to have_content("user1@example.com")
    expect(page).to have_content("user2@example.com")
  end

  scenario "Admin can view a specific chat user" do
    chat_user = create(:chat_user, name: "Test User", email: "test@example.com")
    create(:chat_message, chat_user: chat_user, content: "Hello world")
    
    visit admins_chat_user_path(chat_user)
    
    expect(page).to have_content("test user")
    expect(page).to have_content("test@example.com")
    expect(page).to have_content("Hello world")
  end

  scenario "Admin can edit a chat user" do
    chat_user = create(:chat_user, name: "Original Name", email: "original@example.com")
    
    visit edit_admins_chat_user_path(chat_user)
    
    fill_in "Name", with: "Updated Name"
    fill_in "Email", with: "updated@example.com"
    
    click_button "Update User"
    
    expect(page).to have_content("Jason AI user updated successfully")
    
    chat_user.reload
    expect(chat_user.name).to eq("updated name") # downcased
    expect(chat_user.email).to eq("updated@example.com")
  end

  scenario "Admin can approve a chat user" do
    chat_user = create(:chat_user, approved: false)
    
    visit admins_chat_users_path
    
    accept_confirm do
      find("form[action*='approve'] button").click
    end
    
    expect(page).to have_content("Account approved for #{chat_user.name}")
    
    chat_user.reload
    expect(chat_user.approved?).to be true
  end
end
