require "rails_helper"

RSpec.feature "Guest navigates posts from the footer" do
  context "from the first post" do
    describe "the footer contains" do
      it "the last post and the next post" do
        create_posts

        visit post_path(@post_one)

        expect(footer_section).to have_text "Post Two"
        expect(footer_section).to have_text "Post Four"
      end
    end
  end

  context "from the last post" do
    describe "the footer contains" do
      it "the previous post and the first post" do
        create_posts

        visit post_path(@post_four)

        expect(footer_section).to have_text "Post Two"
        expect(footer_section).to have_text "Post One"
      end
    end
  end


  context "from the first post" do
    describe "the next button" do
      it "goes to the next post" do
        create_posts

        visit post_path(@post_one)

        within ".case-study-footer" do
          click_link "Next"
        end

        expect(post_title_section).to have_text "Post Two"
      end
    end

    describe "the previous button" do
      it "goes to the last post" do
        create_posts

        visit post_path(@post_one)

        within ".case-study-footer" do
          click_link "Previous"
        end

        expect(post_title_section).to have_text "Post Four"
      end
    end
  end

  context "from the last post" do
    describe "the next button" do
      it "goes to the fist post" do
        create_posts

        visit post_path(@post_four)

        within ".case-study-footer" do
          click_link "Next"
        end

        expect(post_title_section).to have_text "Post One"
      end
    end

    describe "the previous button" do
      it "goes to the previous post" do
        create_posts

        visit post_path(@post_four)

        within ".case-study-footer" do
          click_link "Previous"
        end

        expect(post_title_section).to have_text "Post Two"
      end
    end
  end

  private

  def create_posts
    @post_one = create(:post, title: "Post One", published: true, published_date: Date.today)
    @post_two = create(:post, title: "Post Two", published: true, published_date: Date.today - 1.day)
    @post_three = create(:post, title: "Post Three", published: false, published_date: Date.today - 2.day)
    @post_four = create(:post, title: "Post Four", published: true, published_date: Date.today - 3.day)
  end

  def post_title_section
    find(:css, ".page > .content > h1")
  end

  def footer_section
    find(:css, ".case-study-footer")
  end
end
