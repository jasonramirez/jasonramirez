require "rails_helper"

RSpec.feature "Guest navigates site" do
  context "from the header navigation" do
    describe "clicking on work" do
      it "takes you to the list of case studies" do
        visit root_path

        within ".site-header" do
          click_link t("navigation.case_studies")
        end

        expect(page).to have_text "Dropbox Activation"
      end
    end

    describe "clicking on posts" do
      it "takes you to the list of posts" do
        post = create(:post, title: "Post One", published: true)
        visit root_path

        within ".site-header" do
          click_link t("navigation.posts")
        end

        expect(page).to have_text post.long_title
      end
    end

    describe "clicking on principles" do
      it "takes you to my design principles" do
        visit root_path

        within ".site-header" do
          click_link t("navigation.principles")
        end

        expect(page).to have_text "My principles influence"
      end
    end

    describe "clicking on values" do
      it "takes you to my design values" do
        visit root_path

        within ".site-header" do
          click_link t("navigation.values")
        end

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
