module NanoApi
  class Search
    include ActiveData::Model

    attribute :origin_iata
    attribute :origin_name, &:origin_name_default
    attribute :destination_iata
    attribute :destination_name, &:destination_name_default
    attribute(:depart_date, type: Date){Date.current + 2.weeks}
    attribute(:return_date, type: Date){Date.current + 3.weeks}
    attribute :range, type: Boolean, default: false
    attribute :one_way, type: Boolean, default: false
    attribute :trip_class, type: Integer, in: (0..2), default: 0
    attribute :adults, type: Integer, in: (1..9), default: 1
    attribute :children, type: Integer, in: (0..8), default: 0
    attribute :infants, type: Integer, in: (0..5), default: 0
    attribute :feature
    attribute :host, type: String
    attribute :marker, type: String

    alias_method :oneway=, :one_way=

    def passengers
      [adults, children, infants].sum
    end

    [:origin, :destination].each do |name|
      define_method name do
        {}.tap do |place|
          place.merge!(:name => send("#{name}_name")) if send("#{name}_name").present?
          place.merge!(:iata => send("#{name}_iata")) if send("#{name}_iata").present?
        end
      end

      define_method "#{name}=" do |data|
        if data.is_a?(Hash)
          data.symbolize_keys!
          send "#{name}_name=", data[:name] if !send("#{name}_name?") && data.key?(:name)
          send "#{name}_iata=", data[:iata] if !send("#{name}_iata?") && data.key?(:iata)
        else
          send "#{name}_name=", data
        end
      end

      define_method "#{name}_iata=" do |value|
        variable = "@#{name}_name_default"
        remove_instance_variable variable if instance_variable_defined? variable
        write_attribute "#{name}_iata", value
      end

      define_method "#{name}_name_default" do
        variable = "@#{name}_name_default"
        if instance_variable_defined?(variable)
          instance_variable_get(variable).presence || send("#{name}_iata")
        else
          instance_variable_set(variable,
            JSON.parse(NanoApi.client.place(send("#{name}_iata"))).first.try(:[], 'name'))
          send("#{name}_name_default")
        end
      end
    end

    def return_date_for_search
      return_date unless one_way
    end

    def search options = {}
      NanoApi.client.search(attributes_for_search, options)
    end

    [:search, :cookies].each do |postfix|
      define_method "attributes_for_#{postfix}" do
        Hash[attribute_names.map do |name|
          [name, respond_to?("#{name}_for_#{postfix}") ? send("#{name}_for_#{postfix}") : send(name)]
        end]
      end
    end

    def search_params
      {
        :params_attributes =>
          Hash[['origin', 'destination', 'depart_date', 'return_date',
          'range', 'adults', 'children', 'infants', 'trip_class'].map do |name|
            [name, send(name)]
          end]
      }
    end

    def self.find id
      attributes = NanoApi.client.search_params(id)
      raise NotFound unless attributes
      new(attributes)
    end

  end
end
