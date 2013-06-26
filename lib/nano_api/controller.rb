module NanoApi
  module Controller
    extend ActiveSupport::Concern

    module ClassMethods
      def nano_extend
        include NanoApi::Controller::Apiable
        include NanoApi::Controller::Locatable
        include NanoApi::Controller::Markerable
      end
    end

  end
end