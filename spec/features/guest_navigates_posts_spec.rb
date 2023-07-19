require "rails_helper"

RSpec.feature "Guest navigates posts from the footer" do
  context "from the first post" do
    describe "the footer contains" do
      it "the last post and the next post" do
        create_posts

        visit post_path(@post_one)

        expect(footer_section).to have_text "Post 2"
        expect(footer_section).to have_text "Post 4"
      end
    end
  end

  context "from the last post" do
    describe "the footer contains" do
      it "the previous post and the first post" do
        create_posts

        visit post_path(@post_four)

        expect(footer_section).to have_text "Post 3"
        expect(footer_section).to have_text "Post 1"
      end
    end
  end


  context "from the first post" do
    describe "the next button" do
      it "goes to the next post" do
        create_posts

        visit post_path(@post_one)

        within ".case-study-footer" do
          click_link "Post 2"
        end

        expect(post_title_section).to have_text "Post 2"
      end
    end

    describe "the previous button" do
      it "goes to the last post" do
        create_posts

        visit post_path(@post_one)

        within ".case-study-footer" do
          click_link "Post 4"
        end

        expect(post_title_section).to have_text "Post 4"
      end
    end
  end

  context "from the last post" do
    describe "the next button" do
      it "goes to the fist post" do
        create_posts

        visit post_path(@post_four)

        within ".case-study-footer" do
          click_link "Post 1"
        end

        expect(post_title_section).to have_text "Post 1"
      end
    end

    describe "the previous button" do
      it "goes to the previous post" do
        create_posts

        visit post_path(@post_four)

        within ".case-study-footer" do
          click_link "Post 3"
        end

        expect(post_title_section).to have_text "Post 3"
      end
    end
  end

  private

  def create_posts
    @post_one = post(1);
    @post_two = post(2)
    @post_three = post(3)
    @post_four = post(4)
  end

  def post(number)
    create(:post,
      title: "Post #{number}",
      summary: "This is the summary for post #{number}",
      published: true,
      published_date: Date.today - number.day
    )
  end

  def post_title_section
    find(:css, ".page > .content > .post-title")
  end

  def footer_section
    find(:css, ".case-study-footer")
  end
end
