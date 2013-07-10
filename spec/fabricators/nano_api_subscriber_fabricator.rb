Fabricator :nano_api_subscriber, :from => 'nano_api/subscriber' do
  email { Forgery::Internet.email_address }
  recieve_news true
  fare_alerts(count: 1, fabricator: :nano_api_fare_alert)
end
