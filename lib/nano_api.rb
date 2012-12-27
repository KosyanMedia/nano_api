require 'active_support'
require 'rest_client'
require 'nano_api/version'
require 'nano_api/engine' if defined? Rails
require 'nano_api/global'

# Log full request data
RestClient::Payload::Base.class_eval do
  def short_inspect
    inspect
  end
end

module NanoApi
  extend NanoApi::Global

  module Backends
    extend ::ActiveSupport::Autoload

    autoload_under 'controllers' do
      autoload :SearchesController
      autoload :ClicksController
    end
  end
end
