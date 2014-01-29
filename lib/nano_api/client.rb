require 'active_support/core_ext/hash'
require 'json'
require 'digest/md5'

Dir[NanoApi::Engine.root.join(*%w(lib nano_api client *.rb))].each { |f| require f }

module NanoApi
  class Client
    class RequestError < StandardError; end

    AFFILIATE_MARKER_PATTERN = /\A(\d{5})/

    DEFAULT_HOST_KEY = :nano_server

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

    def self.site host = nil
      unless host.is_a?(String)
        host = host && NanoApi.config.send(host) || NanoApi.config.nano_server || NanoApi.config.search_server
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
      params[:signature] = signature(params[:marker], options[:signature]) if options[:signature]

      headers = if request
        Rack::Proxy.extract_http_request_headers(request.env).except('HOST').merge(
          x_referer: request.referer || '',
          x_search_host: request.host || '',
          x_search_url: request.url || '',
          x_real_ip: request.ip || ''
        )
      else
        {}
      end

      headers[:content_type] = :json

      if method == :get
        path = [path, params.to_query].delete_if(&:blank?).join('?')
        site(options[:host])[path].send(method, headers)
      else
        site(options[:host])[path].send(method, params.to_json, headers)
      end
    end
  end
end
