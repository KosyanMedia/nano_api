require 'active_support/core_ext/hash'
require 'json'
require 'digest/md5'

module NanoApi
  class Client
    AFFILIATE_MARKER_PATTERN = /\A(\d{5})/
    MAPPING = { :'zh-CN' => :cn, :'en-GB' => :'en_GB', :'en-AU' => :'en_AU' }
    DEFAULT_HOST_KEY = :nano_server

    include NanoApi::Client::Search
    include NanoApi::Client::Click
    include NanoApi::Client::Places
    include NanoApi::Client::MinimalPrices
    include NanoApi::Client::Airlines
    include NanoApi::Client::UiEvents
    include NanoApi::Client::Overmind
    include NanoApi::Client::Affiliate

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

    def self.site search_host = false, host_key = nil
      host = if search_host || !NanoApi.config.nano_server
        NanoApi.config.search_server
      else
        host_key ||= DEFAULT_HOST_KEY

        NanoApi.config.send(host_key) || NanoApi.config.send(DEFAULT_HOST_KEY)
      end

      RestClient::Resource.new(host)
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
      perform :get, *args
    end

    def post *args
      perform :post, *args
    end

    def get_raw path, params = {}, options = {}
      get path, params, options.merge(parse: false)
    end

    def post_raw path, params = {}, options = {}
      post path, params, options.merge(parse: false)
    end

    def perform method, path, params = {}, options = {}
      options.reverse_merge!(parse: true)

      params.reverse_merge!(locale: MAPPING[I18n.locale] || I18n.locale)
      path += '.json'

      headers = {}
      if request
        params.reverse_merge!(user_ip: request.try(:remote_ip))
        headers[:accept_language] = request.env['HTTP_ACCEPT_LANGUAGE']
        headers[:user_agent] = request.env['HTTP_USER_AGENT']
        headers[:cookie] = request.env.fetch('HTTP_COOKIE', '')
        headers['X-Real-Ip'] = request.try(:remote_ip) || ''
        headers['X-Search-Host'] = URI.parse(request.referer).host rescue request.env.fetch('HTTP_HOST', '')
        if session[:current_referer]
          headers[:referer] = session[:current_referer][:referer]
          headers[:x_landing_page] = session[:current_referer][:landing_page]
          headers[:x_search_count] = session[:current_referer][:search_count]
        end
      end

      params[:signature] = signature(params[:marker], options[:signature]) if options[:signature]

      response = if method == :get
        path = [path, params.to_query].delete_if(&:blank?).join('?')
        site(options[:search_host], options[:host_key])[path].send(method, headers)
      else
        site(options[:search_host], options[:host_key])[path].send(method, params, headers)
      end
      options[:parse] ? JSON.parse(response) : response
    end
  end
end
