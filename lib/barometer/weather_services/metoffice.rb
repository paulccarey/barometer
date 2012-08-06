module Barometer
  #
  # = Met office Data Point
  # http://www.metoffice.gov.uk
  #
  # - usage restrictions: no use from countries which are subject to Foreign and Commonwealth Office sanctions, acceptance
  #      of privavy policy and a far use policy
  # - key required: YES
  # - registration required: YES
  # - supported countries: UK
  #
  # === performs geo coding
  # No
  #
  # == resources
  # - API: ?
  #
  # === Possible queries:
  # - http://partner.metoffice.gov.uk/public/val/wxfcs/all/xml/3772?res=3hourly&key=[APIKEY]

  class WeatherService::Metoffice < WeatherService


    class << self

      attr_accessor :api_key

      def _source_name
        :metoffice
      end

      def _accepted_formats
        [:coordinates]
      end

      def _requires_keys?
        true
      end
      
      def _supports_country?(query=nil)
        query = WebService::Geocode.fetch(query) if query.format == :coordinates
        query.country_code == "GB"
      end

      def keys=(keys)
        raise ArgumentError unless keys.is_a?(Hash)
        raise(ArgumentError, "Mettoffice API key should be String") unless keys[:api_key].is_a?(String)
        @api_key=keys[:api_key]
      end

      def _has_keys?
        true unless api_key.nil?
      end

      def base_uri
        "http://partner.metoffice.gov.uk"
      end

      def _fetch(query, metric=true)
        return unless query
        latitude = Barometer::Query::Format::Coordinates.parse_latitude(query.q)
        longitude = Barometer::Query::Format::Coordinates.parse_longitude(query.q)
        get("#{base_uri}/public/val/wxfcs/all/xml/nearestlatlon?res=3hourly&lat=#{latitude}&lon=#{longitude}&key=#{api_key}")["SiteRep"]["DV"]
      end

      def _build_current(data,metric=true)
        raise ArgumentError unless data.is_a?(Hash)
        current = Measurement::Result.new(metric)
        unless data.blank?
          current.uv_index=data["U"].to_i
          current.condition = weather_type[data["W"].to_i] unless data["W"].blank?
          current.temperature=Data::Temperature.new(metric)
          current.temperature.c=data["T"].to_i
          current.humidity=data["H"].to_i
          current.visibility = Data::Distance.new(metric)
          current.visibility << data['V']
        end
        current
      end

      private

      def weather_type
        @weather_type ||= YAML.load_file( File.expand_path( File.join(File.dirname(__FILE__), '..','translations', 'metoffice_weather_types.yml')) )
      end

      def visibility
        @visibility ||= YAML.load_file( File.expand_path( File.join(File.dirname(__FILE__), '..','translations', 'metoffice_visibility.yml')) )
      end

    end

  end

end
