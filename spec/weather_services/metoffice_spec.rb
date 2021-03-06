require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
include Barometer

describe "Metoffice" do

  before(:each) do
    @accepted_formats = [:coordinates]
    @base_uri = "http://partner.metoffice.gov.uk"
    @api_key = "1ab12345-1a12-12a1-12a1-123456789123"
    @coordinates = "53.432996,-3.078296"
    Barometer.config = {1 => [{:metoffice => {:keys => {:api_key => METOFFICE_KEY}}}]}
  end

  describe "class methods" do

    it "defines accepted_formats" do
      WeatherService::Metoffice._accepted_formats.should == @accepted_formats
    end

    it "defines source_name" do
      WeatherService::Metoffice._source_name.should == :metoffice
    end

    it "defines base_uri" do
      WeatherService::Metoffice.base_uri.should == @base_uri
    end

    it "requires keys" do
      WeatherService::Metoffice._requires_keys?.should be_true
    end

    it "sets the configured api key on measure" do
      WeatherService::Metoffice.stub(:measure) { stub("success?" => true) }
      Barometer.new(@coordinates).measure
      WeatherService::Metoffice.api_key.should == METOFFICE_KEY
    end

    it "defines _fetch" do
      WeatherService::Metoffice.respond_to?("_fetch").should be_true
    end

    describe "keys=" do

      it "should raise an ArgumentError when not provided with a hash" do
        lambda { WeatherService::Metoffice.keys="test" }.should raise_error(ArgumentError)
      end

      it "should raise an ArgumentError if api key is not a String" do
        lambda { WeatherService::Metoffice.keys={:api_key => Object} }.should raise_error(ArgumentError, "Mettoffice API key should be String")
      end


      it "should set the api key when the correct hash is passed through" do
        WeatherService::Metoffice.keys={:api_key => METOFFICE_KEY}
        WeatherService::Metoffice.api_key=METOFFICE_KEY
      end


    end

    describe "_has_keys?" do

      it "should return true when a key is configured" do
        WeatherService::Metoffice.api_key = METOFFICE_KEY
        WeatherService::Metoffice._has_keys?.should be_true
      end

      it "should return false when no key is configured" do
        WeatherService::Metoffice.api_key = nil
        WeatherService::Metoffice._has_keys?.should be_false
      end

    end


    describe "_fetch", :vcr => {:cassette_name => "metoffice_service", :record => :new_episodes} do

      before(:all) do
        @coordinates = "53.432996,-3.078296"
        @query = Barometer::Query.new(@coordinates)
        @expected_url = "http://partner.metoffice.gov.uk/public/val/wxfcs/all/xml/nearestlatlon?res=3hourly&lat=53.432996&lon=-3.078296&key=#{METOFFICE_KEY}"
        WeatherService::Metoffice.api_key = METOFFICE_KEY
      end

      it "makes a request to the metoffice data point service" do
        WeatherService::Metoffice.should_receive(:get).with(@expected_url).and_return({"SiteRep" => {"DV" => {}}})
        WeatherService::Metoffice._fetch(@query)
      end

      it "returns a hash" do
        WeatherService::Metoffice._fetch(@query).class.should == Hash
      end

      it "contains a location hash" do
        WeatherService::Metoffice._fetch(@query)["Location"].class.should == Hash
      end
    end

    describe "_supports_country?", :vcr do

      before do
        @uk_query = Barometer::Query.new("53.432996,-3.078296")
        @india_query = Barometer::Query.new("27.17461,78.0447")
      end

      it "geocodes the location when coordinates query" do
        WebService::Geocode.should_receive(:fetch).and_return(stub(:country_code => "GB"))
        WeatherService::Metoffice._supports_country?(@uk_query)
      end

      it "should return true for UK" do
        WeatherService::Metoffice::_supports_country?(@uk_query).should be_true
      end

      it "should return false for non UK country" do
        WeatherService::Metoffice::_supports_country?(@india_query).should be_false
      end

    end

    describe "weather_type" do

      before(:all) do
        @weather_types_path = File.expand_path( File.join(File.dirname(__FILE__), '..', '..','lib','barometer','translations', 'metoffice_weather_types.yml'))
        YAML.should_receive(:load_file).with(@weather_types_path).and_return({"NA"=>"Not available", 0=>"Clear sky", 1=>"Sunny"})
        @weather_types = WeatherService::Metoffice.send(:weather_type)
      end

      it "should return a hash" do
        @weather_types.should  be_an_instance_of Hash
      end

      it "should have access to the metoffice_weather_types.yml file" do
        File.exist?(@weather_types_path).should be_true
      end

      it "should return 'Sunny' key value 1" do
        @weather_types[1].should == "Sunny"
      end

      it "should not reload the yml file a second time" do
        YAML.should_not_receive(:load_file)
        WeatherService::Metoffice.send(:weather_type)
      end

    end

    describe "_current_result" do

      let(:result_set) do
        YAML.load_file( File.expand_path( File.join( File.dirname(__FILE__), '../','fixtures','services', 'metoffice', 'sample_result.yaml') ) )
      end

      it "should return the very first rep values" do
        WeatherService::Metoffice._current_result(result_set).should == { "__content__"=>"1080", "U"=>"1", "W"=>"1",
                                                                          "V"=>"GO", "T"=>"16", "S"=>"14", "Pp"=>"5",
                                                                          "H"=>"95", "G"=>"23", "F"=>"14", "D"=>"WNW"}
      end


    end

    describe "_build_current", :vcr => {:cassette_name => "metoffice_service", :record => :new_episodes} do

      context "method setup" do

        it "defines the build method" do
          WeatherService::Metoffice.respond_to?("_build_current").should be_true
        end

        it "accepts a hash" do
          lambda { WeatherService::Metoffice._build_current({}) }.should_not raise_error(ArgumentError)
        end

        it "raises an ArgumentError when a Hash is not provided" do
          lambda { WeatherService::Metoffice._build_current }.should raise_error(ArgumentError)
        end

        it "creates a Measurement::Result object passing it a metric value" do
          @metric_value = true
          Measurement::Result.should_receive(:new).with(@metric_value)
          WeatherService::Metoffice._build_current({}, @metric_value)
        end

        it "returns a Measurement::Result object" do
          WeatherService::Metoffice._build_current({}).should be_an_instance_of Measurement::Result
        end

        it "creates a metric Measurement::Result by default" do
          WeatherService::Metoffice._build_current({}).metric.should be_true
        end


      end

      context "method return" do

        before(:all) do
          WeatherService::Metoffice.stub(:weather_type).and_return({"NA"=>"Not available", 0 =>"Clear sky", 1 =>"Sunny", 15 => "Heavy rain"})
          @current_hash = {"__content__" => "1080", "U" => "1", "W" => "15", "V" => "GO", "T" => "16", "S" => "7", "Pp" => "95", "H" => "94", "G" => "14", "F" => "15", "D" => "SSE"}
          @current_conditions = WeatherService::Metoffice._build_current(@current_hash)
        end
        
        it "should return 'Heavy rain' for condition" do
          @current_conditions.condition.should == 'Heavy rain'
        end

        it "should return 16 for temperature in Celsius" do
          @current_conditions.temperature.c.should == 16
        end

        it "should return 60.8 for temperature in Fahrenheit" do
          @current_conditions.temperature.f(false).should == 60.8
        end 

        it "should return 94 for humidity" do 
          @current_conditions.humidity.should == 94
        end

        it "should return 1 for uv index" do
          @current_conditions.uv_index.should == 1
        end

        it "should return 15 for visibility in kilometers" do
          @current_conditions.visibility.km.should == 15
        end

        it "should return 9.33 for visibility in miles" do
          @current_conditions.visibility.m.should == 9
        end

        it "should return 7 for wind speed in mph" do
          @current_conditions.wind.mph.should == 7
        end

        it "should return 11.263 for wind speed in kph" do
          @current_conditions.wind.kph.should == 11
        end

        it "should return SSE for wind direction" do
          @current_conditions.wind.direction.should == "SSE"
        end

        it "should return 95 for pop" do
          @current_conditions.pop.should == 95
        end

        it "should return 14 for wind_gust in mph" do
          @current_conditions.wind_gust.mph.should == 14
        end

        it "should return 22 for wind_gust in kph" do
          @current_conditions.wind_gust.kph.should == 22
        end

        it "should return 15 for wind wind_chill in Celsius" do
          @current_conditions.wind_chill.c.should == 15

        end

        it "should return 59 for wind_chill in Fahrenheit" do
          @current_conditions.wind_chill.f.should == 59
        end

      end


    end

    describe "_forecast_result" do

      before(:each) do
        result_set = YAML.load_file( File.expand_path( File.join( File.dirname(__FILE__), '../','fixtures','services', 'metoffice', 'sample_result.yaml') ) )
        @forecast_result = WeatherService::Metoffice._forecast_result(result_set)
      end

      it "should return 6 periods" do
        @forecast_result["Location"]["Period"].size.should == 6
      end

      it "should return 41 rep periods" do
        @forecast_result["Location"]["Period"].collect do | period |
          period["Rep"]
        end.flatten.size.should == 41
      end

    end

    describe "_build_forecast" do

      before(:each) do
        @forecast_result_data = YAML.load_file( File.expand_path( File.join( File.dirname(__FILE__), '../','fixtures','services', 'metoffice', 'sample_result.yaml') ) )
        @forecast = WeatherService::Metoffice._build_forecast(@forecast_result_data)
      end

      it "builds 41 forecast measurements" do
        @forecast.size.should == 41
      end

      describe "forcast at on 31/07/12 at 330am" do

        before(:each) do
          @target_measurement = @forecast.for(Data::LocalDateTime.new(2012,07,31,03,30,00))
        end

        it "should return 8 mph for the wind speed" do
          @target_measurement.wind.mph.should == 8
        end

        it "should return SE for wind direction" do
          @target_measurement.wind.direction.should == "SE"
        end

        it "should reutrn Medium-level cloud for condition" do
          @target_measurement.condition.should == "Medium-level cloud"
        end

      end

    end

  end


  describe "building the forecast data" do

    it "defines the build method" do
      pending
      WeatherService::Metoffice.respond_to?("_build_forecast").should be_true
    end

    it "requires Hash input" do
      pending
      lambda { WeatherService::Metoffice._build_forecast }.should raise_error(ArgumentError)
      lambda { WeatherService::Metoffice._build_forecast({}) }.should_not raise_error(ArgumentError)
    end

    it "returns Array object" do
      pending
      current = WeatherService::Metoffice._build_forecast({})
      current.is_a?(Measurement::ResultArray).should be_true
    end

  end

  describe "building the location data" do

    it "defines the build method" do
      pending
      WeatherService::Metoffice.respond_to?("_build_location").should be_true
    end

    it "requires Barometer::Geo input" do
      pending
      geo = Data::Geo.new({})
      lambda { WeatherService::Metoffice._build_location(nil, {}) }.should raise_error(ArgumentError)
      lambda { WeatherService::Metoffice._build_location(nil, geo) }.should_not raise_error(ArgumentError)
    end

    it "returns Barometer::Location object" do
      pending
      geo = Data::Geo.new({})
      location = WeatherService::Metoffice._build_location(nil, geo)
      location.is_a?(Data::Location).should be_true
    end

  end

  # describe "building the timezone" do
  #
  #   it "defines the build method" do
  #     Barometer::Metoffice.respond_to?("build_timezone").should be_true
  #   end
  #
  #   it "requires Hash input" do
  #     lambda { Barometer::Metoffice.build_timezone }.should raise_error(ArgumentError)
  #     lambda { Barometer::Metoffice.build_timezone({}) }.should_not raise_error(ArgumentError)
  #   end
  #
  # end

  describe "when measuring" do

    before(:each) do
      @query = Barometer::Query.new("Calgary,AB")
      @measurement = Barometer::Measurement.new
    end

    describe "all" do

      it "responds to _measure" do
        pending
        Barometer::WeatherService::Metoffice.respond_to?("_measure").should be_true
      end

      it "requires a Barometer::Measurement object" do
        pending
        lambda { Barometer::WeatherService::Metoffice._measure(nil, @query) }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService::Metoffice._measure("invalid", @query) }.should raise_error(ArgumentError)

        lambda { Barometer::WeatherService::Metoffice._measure(@measurement, @query) }.should_not raise_error(ArgumentError)
      end

      it "requires a Barometer::Query query" do
        pending
        lambda { Barometer::WeatherService::Metoffice._measure }.should raise_error(ArgumentError)
        lambda { Barometer::WeatherService::Metoffice._measure(@measurement, 1) }.should raise_error(ArgumentError)

        lambda { Barometer::WeatherService::Metoffice._measure(@measurement, @query) }.should_not raise_error(ArgumentError)
      end

      it "returns a Barometer::Measurement object" do
        pending
        result = Barometer::WeatherService::Metoffice._measure(@measurement, @query)
        result.is_a?(Barometer::Measurement).should be_true
        result.current.is_a?(Measurement::Result).should be_true
        result.forecast.is_a?(Measurement::ResultArray).should be_true
      end

    end

  end

  # describe "overall data correctness" do
  #
  #   before(:each) do
  #     @query = Barometer::Query.new("Calgary,AB")
  #     @query.preferred = "Calgary,AB"
  #     @measurement = Barometer::Measurement.new
  #
  #     FakeWeb.register_uri(:get,
  #       "http://api.wunderground.com/auto/wui/geo/WXCurrentObXML/index.xml?query=#{CGI.escape(@query.preferred)}",
  #       :body => File.read(File.join(File.dirname(__FILE__),
  #         'fixtures',
  #         'current_calgary_ab.xml')
  #       )
  #     )
  #     FakeWeb.register_uri(:get,
  #       "http://api.wunderground.com/auto/wui/geo/ForecastXML/index.xml?query=#{CGI.escape(@query.preferred)}",
  #       :body => File.read(File.join(File.dirname(__FILE__),
  #         'fixtures',
  #         'forecast_calgary_ab.xml')
  #       )
  #     )
  #   end
  #
  #  # TODO: complete this
  #  it "should correctly build the data" do
  #     result = Barometer::Wunderground._measure(@measurement, @query)
  #
  #     # build timezone
  #     @measurement.timezone.timezone.should == "America/Edmonton"
  #
  #     time = Time.local(2009, 4, 23, 18, 00, 0)
  #     rise = Time.local(time.year, time.month, time.day, 6, 23)
  #     set = Time.local(time.year, time.month, time.day, 20, 45)
  #     sun_rise = @measurement.timezone.tz.local_to_utc(rise)
  #     sun_set = @measurement.timezone.tz.local_to_utc(set)
  #
  #     # build current
  #     @measurement.current.sun.rise.should == sun_rise
  #     @measurement.current.sun.set.should == sun_set
  #   end
  #
  # end

end
