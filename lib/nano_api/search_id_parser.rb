module NanoApi
  class SearchIdParser
    TYPE_PATTERN = '[ac]'
    CODE_PATTERN = '[a-z]{3}'
    DAY_PATTERN = '\d{2}'
    MONTH_PATTERN = '\d{2}'

    PATH_PART_PATTERN = /
      (#{TYPE_PATTERN})?(#{CODE_PATTERN})(?:
        (#{DAY_PATTERN})(#{MONTH_PATTERN})|
        (?:
          (?<=#{DAY_PATTERN}#{MONTH_PATTERN}#{TYPE_PATTERN}#{CODE_PATTERN})|
          (?<=#{DAY_PATTERN}#{MONTH_PATTERN}#{CODE_PATTERN})
        )-?
      )
    /ix

    REGEX = /(?<match> # For routing constraints compatibility
      (?<path_parts>#{PATH_PART_PATTERN}{2,})
      (?<range>f)?
      (?<trip_class>b)?
      (?<adults>\d)
      (?<children>\d)?
      (?<infants>\d)?
    )/ix

    TYPE_MAP = {a: 'airport', c: 'city'}
    MIN_TIMEZONE = '-12:00'

    def self.parse(search_id)
      if match = search_id.match(/^#{REGEX}$/)
        search = NanoApi::Search.new(
          range: match[:range].present?,
          trip_class: match[:trip_class].present? ? 1 : 0,
          passengers: %w(adults children infants).each_with_object({}) { |key, obj| obj[key] = match[key] if match[key] },
          segments: [],
          with_request: true
        )

        min_date = Time.now.getlocal(MIN_TIMEZONE).to_date
        year = min_date.year

        path_parts = match[:path_parts].scan(PATH_PART_PATTERN).map do |type, code, day, month|
          begin
            date = day && month && Date.new(year, month.to_i, day.to_i)
          rescue ArgumentError
            return nil
          end
          date += 1.year if date && date < min_date
          {
            code: code.upcase,
            type: type && TYPE_MAP[type.downcase.to_sym],
            date: date
          }
        end

        path_parts.push(path_parts.first).each_cons(2) do |origin, destination|
          if origin[:date]
            search.segments << NanoApi::Segment.new(
              origin: {iata: origin[:code], type: origin[:type]},
              destination: {iata: destination[:code], type: destination[:type]},
              date: origin[:date]
            )
          end
        end

        search
      end
    end
  end
end
