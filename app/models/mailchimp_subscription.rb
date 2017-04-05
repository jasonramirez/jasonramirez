require "ostruct"

class MailchimpSubscription < OpenStruct
  def initialize(subscription_info ={})
    super subscription_info
  end

  def errors?
    body["status"] != "subscribed"
  end

  def error_message
    body["title"]
  end
end
