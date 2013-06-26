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

    # attr_accessible :answers, :success, :rating, :gate_id, :search_id

    validates :search_id, presence: true
    validates :gate_id, presence: true, numericality: {only_integer: true}
    validates :rating, inclusion: rating_values, numericality: {only_integer: true}, allow_blank: true

    def request= request
      self.host = request.host
      self.user_ip = request.remote_ip
      self.user_agent = request.user_agent
    end

    def save
      NanoApi.client.send :post_raw, 'user_feedback_reports', :user_feedback_report => existing_attributes
    rescue RestClient::UnprocessableEntity
      false
    ensure
      true
    end
  end
end
