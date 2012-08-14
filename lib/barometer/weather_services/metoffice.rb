require "active_support"

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

      def _current_result(data=nil)
        data["Location"]["Period"].first["Rep"].first
      end

      def _forecast_result(data=nil)
        data
      end

      def _build_forecast(data=nil, metric=true)
        forecasts = Measurement::ResultArray.new

        data["Location"]["Period"].each do | period |
          period_day = Data::LocalDateTime.parse(period["val"]).to_dt

          period["Rep"].each do | forecast |
            forecast_measurement = Measurement::Result.new(metric)

            forecast_start=period_day+(forecast["__content__"].to_i / (24 * 60.0))
            forecast_end=forecast_start+(180 / (24 * 60.0))

            forecast_measurement.valid_start_date=Data::LocalDateTime.parse(forecast_start)
            forecast_measurement.valid_end_date=Data::LocalDateTime.parse(forecast_end)

            forecasts << populate_measurement(forecast_measurement,forecast,metric)

          end

        end

        forecasts
      end

      def _build_current(data, metric=true)
        raise ArgumentError unless data.is_a?(Hash)
        current = Measurement::Result.new(metric)
        unless data.blank?
          current.uv_index=data["U"].to_i
          current.condition = weather_type[data["W"].to_i] unless data["W"].blank?
          current.temperature=Data::Temperature.new(metric)
          current.temperature.c=data["T"].to_i
          current.humidity=data["H"].to_i
          current.visibility = Data::Distance.new(metric)
          current.visibility.km=visibility[data['V']]
          current.wind = Data::Speed.new(metric)
          current.wind.mph=data['S'].to_i
          current.wind.direction=data['D']
          current.pop=data['Pp'].to_i
          current.wind_gust = Data::Speed.new(metric)
          current.wind_gust.mph=data['G'].to_i
          current.wind_chill=Data::Temperature.new(metric)
          current.wind_chill.c=data["F"].to_i
        end
        current
      end

      private

      def populate_measurement(measurement,data, metric)
        raise ArgumentError unless data.is_a?(Hash)
        unless data.blank?
          measurement.uv_index=data["U"].to_i
          measurement.condition = weather_type[data["W"].to_i] unless data["W"].blank?
          measurement.temperature=Data::Temperature.new(metric)
          measurement.temperature.c=data["T"].to_i
          measurement.humidity=data["H"].to_i
          measurement.visibility = Data::Distance.new(metric)
          measurement.visibility.km=visibility[data['V']]
          measurement.wind = Data::Speed.new(metric)
          measurement.wind.mph=data['S'].to_i
          measurement.wind.direction=data['D']
          measurement.pop=data['Pp'].to_i
          measurement.wind_gust = Data::Speed.new(metric)
          measurement.wind_gust.mph=data['G'].to_i
          measurement.wind_chill=Data::Temperature.new(metric)
          measurement.wind_chill.c=data["F"].to_i
        end
        measurement
      end

      def weather_type
        @weather_type ||= YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__), '..', 'translations', 'metoffice_weather_types.yml')))
      end

      def visibility
        @visibility ||= YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__), '..', 'translations', 'metoffice_visibility.yml')))
      end

    end

  end

end
