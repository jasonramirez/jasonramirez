class MailchimpSubscriptionService
  def initialize(email:)
    @email = email
    @gibbon = Gibbon::Request.new(api_key: mailchimp_api_key)
  end

  def create
    MailchimpSubscription.new(body: member_create)
  end

  private

  attr_reader :email, :gibbon

  def mailchimp_api_key
    ENV.fetch("MAILCHIMP_API_KEY")
  end

  def mailchimp_list_id
    ENV.fetch("MAILCHIMP_LIST_ID")
  end

  def member_create
    begin
      gibbon.lists(mailchimp_list_id).members.create(body: subscribe_params).body
    rescue Gibbon::MailChimpError => error
      error.body
    end
  end

  def subscribe_params
    { "email_address": email, "status": "subscribed" }
  end
end
