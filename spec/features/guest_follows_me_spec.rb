require "rails_helper"

feature "Guest follows me" do
  scenario "succesfully" do
    stub_request(:post, mailchimp_url).
      with(body: mailchimp_request_body).
      to_return(status: 200, body: mailchimp_valid_response_body)

    visit new_follower_path
    submit_email_form

    expect(page).to have_content(I18n.t("followers.new.success"))
  end

  scenario "member already exists" do
    stub_request(:post, mailchimp_url).
      with(body: mailchimp_request_body).
      to_return(status: 400, body: mailchimp_member_exists_response_body)

    visit new_follower_path
    submit_email_form

    expect(page).to have_content("Member Exists")
  end

  private

  def mailchimp_url
    mailchimp_list_id = ENV.fetch("MAILCHIMP_LIST_ID").freeze

    "https://us15.api.mailchimp.com/3.0/lists/#{mailchimp_list_id}/members"
  end

  def mailchimp_request_body
    "{\"email_address\":\"#{valid_email}\",\"status\":\"subscribed\"}"
  end

  def mailchimp_valid_response_body
    {
      email_address: valid_email,
      status: "subscribed",
    }.to_json
  end

  def mailchimp_member_exists_response_body
    {
      title: "Member Exists",
      status: 400,
    }.to_json
  end

  def valid_email
    "user@example.com"
  end

  def submit_email_form
    fill_form_and_submit(:follower, :new, {email: valid_email})
  end
end
