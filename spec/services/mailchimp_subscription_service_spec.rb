require 'rails_helper'

RSpec.describe MailchimpSubscriptionService do
  let(:email) { 'test@example.com' }
  let(:service) { described_class.new(email: email) }

  before do
    ENV['MAILCHIMP_API_KEY'] = 'test_key'
    ENV['MAILCHIMP_LIST_ID'] = 'test_list'
  end

  describe '#initialize' do
    it 'sets the email' do
      expect(service.instance_variable_get(:@email)).to eq(email)
    end

    it 'initializes Gibbon with API key' do
      expect(service.instance_variable_get(:@gibbon)).to be_a(Gibbon::Request)
    end
  end

  describe '#create' do
    let(:mock_gibbon) { double('Gibbon::Request') }
    let(:mock_lists) { double('Lists') }
    let(:mock_members) { double('Members') }
    let(:mock_response) { double('Response', body: { 'id' => '123', 'email_address' => email }) }

    before do
      allow(service).to receive(:gibbon).and_return(mock_gibbon)
      allow(mock_gibbon).to receive(:lists).and_return(mock_lists)
      allow(mock_lists).to receive(:members).and_return(mock_members)
    end

    context 'when subscription is successful' do
      before do
        allow(mock_members).to receive(:create).and_return(mock_response)
      end

      it 'creates a MailchimpSubscription with response body' do
        result = service.create
        expect(result).to be_a(MailchimpSubscription)
        expect(result.body).to eq({ 'id' => '123', 'email_address' => email })
      end
    end

    context 'when Mailchimp returns an error' do
      let(:error_response) { double('ErrorResponse', body: { 'title' => 'Member Exists' }) }

      before do
        allow(mock_members).to receive(:create).and_raise(Gibbon::MailChimpError.new(error_response))
      end

      it 'creates a MailchimpSubscription with error body' do
        result = service.create
        expect(result).to be_a(MailchimpSubscription)
        expect(result.body).to eq({ 'title' => 'Member Exists' })
      end
    end
  end

  describe 'private methods' do
    describe '#mailchimp_api_key' do
      it 'returns the API key from environment' do
        expect(service.send(:mailchimp_api_key)).to eq('test_key')
      end
    end

    describe '#mailchimp_list_id' do
      it 'returns the list ID from environment' do
        expect(service.send(:mailchimp_list_id)).to eq('test_list')
      end
    end

    describe '#subscribe_params' do
      it 'returns correct subscription parameters' do
        expected_params = { 'email_address' => email, 'status' => 'subscribed' }
        expect(service.send(:subscribe_params)).to eq(expected_params)
      end
    end
  end
end
