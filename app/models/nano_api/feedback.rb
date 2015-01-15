module NanoApi
  class Feedback
    include ActiveData::Model

    attribute :search_id, type: String
    attribute :gate_id, type: Integer
    attribute :success, type: Boolean
    attribute :rating, type: Integer, in: 1..5
    attribute :answers, type: Hash, default: {}
    attribute :host
    attribute :user_ip
    attribute :user_agent
    attribute :auid

    validates :search_id, presence: true
    validates :gate_id, presence: true, numericality: {only_integer: true}

    validates :rating, inclusion: rating_values, numericality: {only_integer: true}, allow_blank: true

    def request= request
      self.auid = request.cookies["auid"]
      self.host = request.host
      self.user_ip = request.remote_ip
      self.user_agent = request.user_agent
    end

    def save
      NanoApi.client.save_feedback :user_feedback_report => existing_attributes
    rescue RestClient::UnprocessableEntity
      false
    ensure
      true
    end

    def existing_attributes
      Hash[attribute_names.map do |name|
        value = send(name)
        [name, value] unless value.respond_to?(:empty?) ? value.empty? : value.nil?
      end]
    end
  end
end
