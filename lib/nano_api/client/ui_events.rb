module NanoApi
  class Client
    module UiEvents
      def ui_eventsents_mass_create params
        post_raw('/ui_events/mass_create', params)
      rescue RestClient::BadRequest
        nil
      end
    end
  end
end
