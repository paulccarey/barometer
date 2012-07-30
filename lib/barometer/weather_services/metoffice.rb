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

      def keys=(keys)
        raise ArgumentError unless keys.is_a?(Hash)
        raise(ArgumentError, "Mettoffice API key should be String") unless keys[:api_key].is_a?(String)
        api_key = keys[:api_key]
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

    end

  end

end
