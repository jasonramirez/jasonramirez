require "rails_helper"

feature "Guest follows me", js: true do
  scenario "succesfully" do
    # Mock successful subscription
    successful_subscription = MailchimpSubscription.new(body: { "status" => "subscribed" })
    allow_any_instance_of(MailchimpSubscriptionService).to receive(:create).and_return(successful_subscription)

    visit new_follower_path
    submit_email_form

    expect(page).to have_content(I18n.t("followers.new.success"))
  end

  scenario "member already exists" do
    # Mock member exists error
    error_subscription = MailchimpSubscription.new(body: { "status" => "error", "title" => "Member Exists" })
    allow_any_instance_of(MailchimpSubscriptionService).to receive(:create).and_return(error_subscription)

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
