require 'active_support/core_ext/hash'
require 'json'
require 'digest/md5'

Dir[NanoApi::Engine.root.join(*%w(lib nano_api client *.rb))].each { |f| require f }

module NanoApi
  class Client
    class RequestError < StandardError; end

    AFFILIATE_MARKER_PATTERN = /\A(\d{5})/
    MAPPING = {
      :'zh-CN' => :cn,
      :'en-GB' => :en_GB,
      :'en-IE' => :en_GB,
      :'en-AU' => :en_AU,
      :'en-NZ' => :en_AU,
      :'en-IN' => :en,
      :'en-SG' => :en,
      :'en-CA' => :en
    }
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

    def self.site host = false, host_key = nil
      unless host.is_a?(String)
        host = if host || !NanoApi.config.nano_server
          NanoApi.config.search_server
        else
          host_key ||= DEFAULT_HOST_KEY

          NanoApi.config.send(host_key) || NanoApi.config.send(DEFAULT_HOST_KEY)
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
        params.reverse_merge!(user_ip: request.try(:remote_ip))
        headers[:accept_language] = request.env['HTTP_ACCEPT_LANGUAGE']
        headers[:user_agent] = request.env['HTTP_USER_AGENT']
        headers[:cookie] = request.env.fetch('HTTP_COOKIE', '')
        headers['X-Real-Ip'] = request.remote_ip || ''
        headers['X-Search-Host'] = request.host || ''
        if request.methods.include?(:url)
          headers['X-Search-Url'] = request.url || ''
        end
        headers['X-Referer'] = request.referer || ''

        if session[:current_referer]
          headers[:referer] = session[:current_referer][:referer]
          headers[:x_landing_page] = session[:current_referer][:landing_page]
          headers[:x_search_count] = session[:current_referer][:search_count]
        end
      end

      params.reverse_merge!(locale: MAPPING[I18n.locale] || I18n.locale)
      params[:signature] = signature(params[:marker], options[:signature]) if options[:signature]

      path += '.json'

      if method == :get
        path = [path, params.to_query].delete_if(&:blank?).join('?')
        site(options[:host], options[:host_key])[path].send(method, headers)
      else
        site(options[:host], options[:host_key])[path].send(method, params, headers)
      end
    end
  end
end
