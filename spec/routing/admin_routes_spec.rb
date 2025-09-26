require "rails_helper"

RSpec.describe "Admin routes", type: :routing do
  describe "admin main route" do
    it "routes GET /admin to admins/posts#index" do
      expect(get: "/admin").to route_to(controller: "admins/posts", action: "index")
    end
  end

  describe "admin posts routes" do
    it "routes GET /admins/posts to admins/posts#index" do
      expect(get: "/admins/posts").to route_to(controller: "admins/posts", action: "index")
    end

    it "routes GET /admins/posts/new to admins/posts#new" do
      expect(get: "/admins/posts/new").to route_to(controller: "admins/posts", action: "new")
    end

    it "routes POST /admins/posts to admins/posts#create" do
      expect(post: "/admins/posts").to route_to(controller: "admins/posts", action: "create")
    end

    it "routes GET /admins/posts/:id to admins/posts#show" do
      expect(get: "/admins/posts/123").to route_to(controller: "admins/posts", action: "show", id: "123")
    end

    it "routes GET /admins/posts/:id/edit to admins/posts#edit" do
      expect(get: "/admins/posts/123/edit").to route_to(controller: "admins/posts", action: "edit", id: "123")
    end

    it "routes PATCH /admins/posts/:id to admins/posts#update" do
      expect(patch: "/admins/posts/123").to route_to(controller: "admins/posts", action: "update", id: "123")
    end

    it "routes PUT /admins/posts/:id to admins/posts#update" do
      expect(put: "/admins/posts/123").to route_to(controller: "admins/posts", action: "update", id: "123")
    end

    it "routes DELETE /admins/posts/:id to admins/posts#destroy" do
      expect(delete: "/admins/posts/123").to route_to(controller: "admins/posts", action: "destroy", id: "123")
    end
  end

  describe "admin hashtags routes" do
    it "routes GET /admins/hashtags to admins/hashtags#index" do
      expect(get: "/admins/hashtags").to route_to(controller: "admins/hashtags", action: "index")
    end

    it "routes GET /admins/hashtags/new to admins/hashtags#new" do
      expect(get: "/admins/hashtags/new").to route_to(controller: "admins/hashtags", action: "new")
    end

    it "routes POST /admins/hashtags to admins/hashtags#create" do
      expect(post: "/admins/hashtags").to route_to(controller: "admins/hashtags", action: "create")
    end

    it "routes GET /admins/hashtags/:id/edit to admins/hashtags#edit" do
      expect(get: "/admins/hashtags/123/edit").to route_to(controller: "admins/hashtags", action: "edit", id: "123")
    end

    it "routes PATCH /admins/hashtags/:id to admins/hashtags#update" do
      expect(patch: "/admins/hashtags/123").to route_to(controller: "admins/hashtags", action: "update", id: "123")
    end

    it "routes DELETE /admins/hashtags/:id to admins/hashtags#destroy" do
      expect(delete: "/admins/hashtags/123").to route_to(controller: "admins/hashtags", action: "destroy", id: "123")
    end
  end

  describe "admin documents routes" do
    it "routes GET /admins/documents to admins/documents#index" do
      expect(get: "/admins/documents").to route_to(controller: "admins/documents", action: "index")
    end

    it "routes GET /admins/documents/:document to admins/documents#show" do
      expect(get: "/admins/documents/resume").to route_to(
        controller: "admins/documents", 
        action: "show", 
        document: "resume"
      )
    end
  end

  describe "admin chat users routes" do
    it "routes GET /admins/chat_users to admins/chat_users#index" do
      expect(get: "/admins/chat_users").to route_to(controller: "admins/chat_users", action: "index")
    end

    it "routes GET /admins/chat_users/new to admins/chat_users#new" do
      expect(get: "/admins/chat_users/new").to route_to(controller: "admins/chat_users", action: "new")
    end

    it "routes POST /admins/chat_users to admins/chat_users#create" do
      expect(post: "/admins/chat_users").to route_to(controller: "admins/chat_users", action: "create")
    end

    it "routes GET /admins/chat_users/:id to admins/chat_users#show" do
      expect(get: "/admins/chat_users/123").to route_to(controller: "admins/chat_users", action: "show", id: "123")
    end

    it "routes GET /admins/chat_users/:id/edit to admins/chat_users#edit" do
      expect(get: "/admins/chat_users/123/edit").to route_to(controller: "admins/chat_users", action: "edit", id: "123")
    end

    it "routes PATCH /admins/chat_users/:id to admins/chat_users#update" do
      expect(patch: "/admins/chat_users/123").to route_to(controller: "admins/chat_users", action: "update", id: "123")
    end

    it "routes PUT /admins/chat_users/:id to admins/chat_users#update" do
      expect(put: "/admins/chat_users/123").to route_to(controller: "admins/chat_users", action: "update", id: "123")
    end

    it "routes PATCH /admins/chat_users/:id/approve to admins/chat_users#approve" do
      expect(patch: "/admins/chat_users/123/approve").to route_to(controller: "admins/chat_users", action: "approve", id: "123")
    end
  end
end
