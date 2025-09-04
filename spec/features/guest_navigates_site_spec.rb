require "rails_helper"

RSpec.feature "Guest navigates site" do
  context "from the header navigation" do
    describe "clicking on work" do
      it "takes you to the list of case studies" do
        visit root_path

        within ".site-header" do
          click_link t("navigation.works")
        end

        expect(page).to have_text "Smartifying Activation"
      end
    end

    describe "clicking on posts" do
      it "takes you to the list of posts" do
        post = create(:post, title: "Post One", published: true)
        visit root_path

        within ".site-header" do
          click_link t("navigation.posts")
        end

        expect(page).to have_text post.title
      end
    end

    describe "clicking on philosophy" do
      it "takes you to my design philosophy including principles and values" do
        visit root_path

        within ".site-header" do
          click_link t("navigation.philosophy")
        end

        expect(page).to have_text "Philosophy"
        expect(page).to have_text "My principles influence"
        expect(page).to have_text "I establish values"
      end
    end
  end

  context "from the footer navigation" do
    describe "clicking on follow" do
      it "takes you to the follow page" do
        visit root_path

        within ".site-footer" do
          click_link t("navigation.follow")
        end

        expect(page).to have_text t("followers.new.sign_up")
      end
    end
  end
end
