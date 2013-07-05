require 'active_support/core_ext/hash'
require 'json'
require 'digest/md5'

Dir[NanoApi::Engine.root.join(*%w(lib nano_api client *.rb))].each { |f| require f }

module NanoApi
  class Client
    AFFILIATE_MARKER_PATTERN = /\A(\d{5})/
    MAPPING = { :'zh-CN' => :cn, :'en-GB' => :'en_GB', :'en-AU' => :'en_AU' }

    include NanoApi::Client::Search
    include NanoApi::Client::Click
    include NanoApi::Client::Places
    include NanoApi::Client::MinimalPrices
    include NanoApi::Client::Airlines
    include NanoApi::Client::Overmind
    include NanoApi::Client::Affiliate
    include NanoApi::Client::WhiteLabel

    attr_reader :controller
    delegate :request, :session, :marker, to: :controller, allow_nil: true
    delegate :site, :signature, to: 'self.class'

    def initialize controller = nil
      @controller = controller
    end

    def affilate?
      self.class.affiliate_marker? marker
    end
    alias affiliate? affilate?

    def self.site(host = false)
      unless host.is_a?(String)
        host = if host || !NanoApi.config.nano_server
          NanoApi.config.search_server
        else
          NanoApi.config.nano_server
        end
      end
      (@site ||= {})[host] ||= RestClient::Resource.new(host)
    end

    def self.affiliate_marker? marker
      !!(marker.to_s =~ AFFILIATE_MARKER_PATTERN)
    end

    def self.extract_marker marker
      marker.try(:gsub, AFFILIATE_MARKER_PATTERN).try(:first)
    end

    def self.signature marker, *params
      Digest::MD5.hexdigest([
        NanoApi.config.api_token,
        marker,
        *Array.wrap(params).flatten
      ].join(?:))
    end

  protected

    def get *args
      JSON.parse perform(:get, *args)
    end

    def post *args
      JSON.parse perform(:post, *args)
    end

    def get_raw *args
      perform(:get, *args)
    end

    def post_raw *args
      perform(:post, *args)
    end

    def perform method, path, params = {}, options = {}
      headers = {}
      if request
        params.reverse_merge!(user_ip: request.remote_ip) if request.remote_ip.present?
        headers[:accept_language] = request.env['HTTP_ACCEPT_LANGUAGE']
      end

      params.reverse_merge!(locale: MAPPING[I18n.locale] || I18n.locale)
      params[:signature] = signature(params[:marker], options[:signature]) if options[:signature]

      path += '.json'

      if method == :get
        path = [path, params.to_query].delete_if(&:blank?).join('?')
        site(options[:host])[path].send(method, headers)
      else
        site(options[:host])[path].send(method, params, headers)
      end
    end
  end
end
