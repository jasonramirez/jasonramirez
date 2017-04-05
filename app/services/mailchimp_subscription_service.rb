class MailchimpSubscriptionService
  MAILCHIMP_API_KEY = ENV.fetch("MAILCHIMP_API_KEY").freeze
  MAILCHIMP_LIST_ID = ENV.fetch("MAILCHIMP_LIST_ID").freeze

  def initialize(email:)
    @email = email
    @gibbon = Gibbon::Request.new(api_key: MAILCHIMP_API_KEY)
  end

  def create
    MailchimpSubscription.new(body: member_create)
  end

  private

  attr_reader :email, :gibbon

  def member_create
    begin
      gibbon.lists(MAILCHIMP_LIST_ID).members.create(body: subscribe_params).body
    rescue Gibbon::MailChimpError => error
      error.body
    end
  end

  def subscribe_params
    { "email_address": email, "status": "subscribed" }
  end
end
