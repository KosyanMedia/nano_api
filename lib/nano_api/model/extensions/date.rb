# encoding: UTF-8
module NanoApi
  module Model
    module Extensions
      module Date
        extend ActiveSupport::Concern

        def demodelize
          to_s
        end

        module ClassMethods
          def modelize value
            smart_parse(value.to_s) rescue nil
          end

          def smart_parse date_or_string, fallback = nil
            fallback_value = fallback.respond_to?(:call) ? fallback.call : fallback

            date = Timeliness.parse(date_or_string, :date).to_date

            date or fallback_value
          end
        end
      end
    end
  end
end

Date.send :include, NanoApi::Model::Extensions::Date
