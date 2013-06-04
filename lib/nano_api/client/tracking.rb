module NanoApi::Client::Tracking

  def track_click id, url
    params = {id: id, url: url, token: NanoApi.config.tracking_token}

    Thread.new do
      RestClient.post('http://tracker.aviasales.ru/track', params) rescue nil
    end

    true
  end

end
