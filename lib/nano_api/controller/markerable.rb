module NanoApi
  module Controller
    module Markerable
      extend ActiveSupport::Concern

      included do
        helper_method :marker
        prepend_before_filter :handle_marker
        before_filter :redirect_marker
      end

      def marker
        @marker ||= cookies[:tmp_marker] || cookies[:marker]
      end

    private

      def handle_marker
        new_marker = params[:marker].presence || params[:ref].presence
        if new_marker && _new_marker?(new_marker)
          set_marker(new_marker)
        elsif marker.blank?
          set_marker(default_marker)
        end
      end

      def set_marker(new_marker)
        @marker = new_marker

        cookies[:tmp_marker] = {
            :value => new_marker,
            :domain => default_nano_domain,
            :expires => 10.minutes.from_now
        }
      end

      def default_nano_domain
        request.domain unless request.local?
      end

      def default_marker
        'direct'
      end

      def redirect_marker
        if request.get? && params[:marker].present? || params[:ref].present?
          # TODO: Passing just params.except(:ref, :marker) works too, but as of rspec-rails 2.11.0 fails at testing with anonymous controller
          redirect_to([
            request.path_info,
            request.query_parameters.except(:ref, :marker).to_query
          ].delete_if(&:blank?).join('?'), status: 301)
        end
      end

      def _new_marker?(new_marker)
        new_marker.present? && new_marker != marker
      end

      def _affiliate_marker?(marker)
        NanoApi::Client.affiliate_marker?(marker)
      end

      def affiliate
        return @affiliate if instance_variable_defined?(:@affiliate)

        @affiliate = NanoApi::Client.new(self).affiliate.try(:symbolize_keys)
      end

      def affiliate_attribute name, default
        (affiliate.is_a?(Hash) && affiliate.has_key?(name)) ? affiliate[name] : default
      end

    end
  end
end
