module NanoApi
  class SearchId
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

    TO_TYPE_MAP = {'A' => 'airport', 'C' => 'city'}
    FROM_TYPE_MAP = TO_TYPE_MAP.invert
    MIN_TIMEZONE = '-12:00'

    class << self
      def parse(search_id)
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
              type: type && TO_TYPE_MAP[type.upcase],
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

      def compose search
        search = NanoApi::Search.new(search) unless search.is_a?(NanoApi::Search)
        data = {
          trip_class: search.trip_class == 1 ? 'b' : nil,
          passengers: %w(adults children infants).map { |key| search.passengers.send(key).to_s }.join.sub(/0+$/, ''),
        }
        segments = search.segments
        data[:segments] = segments.map.with_index do |segment, index|
          result = []
          origin_place_text = place_text(segment.origin)
          if index == 0
            result.push(origin_place_text)
          elsif place_text(segments[index - 1].destination) != origin_place_text
            result.push('-', origin_place_text)
          end
          result.push(segment.date.strftime('%d%m'))
          destination_place_text = place_text(segment.destination)
          if index < segments.length - 1 || destination_place_text != place_text(segments[0].origin)
            result.push(destination_place_text)
          end
          result.join
        end.join
        data.values_at(:segments, :trip_class, :passengers).join
      end

    private
      def place_text place
        FROM_TYPE_MAP[place.type] + place.iata
      end
    end
  end
end
