require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
include Barometer

describe "WeatherBug" do
  
  before(:each) do
    @accepted_formats = [:short_zipcode, :coordinates]
  end
  
  describe "the class methods" do
    
    it "defines accepted_formats" do
      WeatherService::WeatherBug._accepted_formats.should == @accepted_formats
    end
    
    it "defines source_name" do
      WeatherService::WeatherBug._source_name.should == :weather_bug
    end
    
    it "defines fetch_current" do
      WeatherService::WeatherBug.respond_to?("_fetch_current").should be_true
    end
    
    it "defines fetch_forecast" do
      WeatherService::WeatherBug.respond_to?("_fetch_forecast").should be_true
    end
    
    it "defines _requires_keys?" do
      WeatherService::WeatherBug.respond_to?("_requires_keys?").should be_true
      WeatherService::WeatherBug._requires_keys?.should be_true
    end
    
    it "defines _has_keys?" do
      WeatherService::WeatherBug.respond_to?("_has_keys?").should be_true
      WeatherService::WeatherBug._has_keys?.should be_false
      WeatherService::WeatherBug.keys = { :code => WEATHERBUG_CODE }
      WeatherService::WeatherBug._has_keys?.should be_true
    end

  end
  
  describe "building the current data" do
    
    it "defines the build method" do
      WeatherService::WeatherBug.respond_to?("_build_current").should be_true
    end
    
    it "requires Hash input" do
      lambda { WeatherService::WeatherBug._build_current }.should raise_error(ArgumentError)
      lambda { WeatherService::WeatherBug._build_current({}) }.should_not raise_error(ArgumentError)
    end
    
    it "returns Measurement::Current object" do
      current = WeatherService::WeatherBug._build_current({})
      current.is_a?(Measurement::Result).should be_true
    end
    
  end
  
  describe "building the forecast data" do
    
    it "defines the build method" do
      WeatherService::WeatherBug.respond_to?("_build_forecast").should be_true
    end
    
    it "requires Hash input" do
      lambda { WeatherService::WeatherBug._build_forecast }.should raise_error(ArgumentError)
      lambda { WeatherService::WeatherBug._build_forecast({}) }.should_not raise_error(ArgumentError)
    end
    
    it "returns Array object" do
      current = WeatherService::WeatherBug._build_forecast({})
      current.is_a?(Array).should be_true
    end
    
  end
  
  describe "building the location data" do
    
    it "defines the build method" do
      WeatherService::WeatherBug.respond_to?("_build_location").should be_true
    end
    
    it "requires Hash input" do
      lambda { WeatherService::WeatherBug._build_location }.should raise_error(ArgumentError)
      lambda { WeatherService::WeatherBug._build_location({}) }.should_not raise_error(ArgumentError)
    end
    
    it "requires Barometer::Geo input" do
      geo = Data::Geo.new({})
      lambda { WeatherService::WeatherBug._build_location({}, {}) }.should raise_error(ArgumentError)
      lambda { WeatherService::WeatherBug._build_location({}, geo) }.should_not raise_error(ArgumentError)
    end
    
    it "returns Barometer::Location object" do
      location = WeatherService::WeatherBug._build_location({})
      location.is_a?(Data::Location).should be_true
    end
    
  end
  
  describe "building the sun data" do
    
    it "defines the build method" do
      WeatherService::WeatherBug.respond_to?("_build_sun").should be_true
    end
    
    it "requires Hash input" do
      lambda { WeatherService::WeatherBug._build_sun }.should raise_error(ArgumentError)
      lambda { WeatherService::WeatherBug._build_sun({}) }.should_not raise_error(ArgumentError)
    end
    
    it "returns Barometer::Sun object" do
      sun = WeatherService::WeatherBug._build_sun({})
      sun.is_a?(Data::Sun).should be_true
    end
    
  end
  
  describe "builds other data" do
    
    it "defines _build_extra" do
      WeatherService::WeatherBug.respond_to?("_build_extra").should be_true
    end
    
    it "defines _parse_local_time" do
      WeatherService::WeatherBug.respond_to?("_parse_local_time").should be_true
    end
    
    it "defines _build_timezone" do
      WeatherService::WeatherBug.respond_to?("_build_timezone").should be_true
    end
    
  end

  describe "when measuring" do
  
    before(:each) do
      @query = Barometer::Query.new("90210")
      @measurement = Barometer::Measurement.new
    end
  
    describe "all" do
      
      it "responds to _measure" do
        WeatherService::WeatherBug.respond_to?("_measure").should be_true
      end
      
      it "requires a Barometer::Measurement object" do
        lambda { WeatherService::WeatherBug._measure(nil, @query) }.should raise_error(ArgumentError)
        lambda { WeatherService::WeatherBug._measure("invalid", @query) }.should raise_error(ArgumentError)

        lambda { WeatherService::WeatherBug._measure(@measurement, @query) }.should_not raise_error(ArgumentError)
      end
  
      it "requires a Barometer::Query query" do
        lambda { WeatherService::WeatherBug._measure }.should raise_error(ArgumentError)
        lambda { WeatherService::WeatherBug._measure(@measurement, 1) }.should raise_error(ArgumentError)
        
        lambda { WeatherService::WeatherBug._measure(@measurement, @query) }.should_not raise_error(ArgumentError)
      end
      
      it "returns a Barometer::Measurement object" do
        result = WeatherService::WeatherBug._measure(@measurement, @query)
        result.is_a?(Barometer::Measurement).should be_true
        result.current.is_a?(Measurement::Result).should be_true
        result.forecast.is_a?(Measurement::ResultArray).should be_true
      end
      
    end
  
  end
  
  describe "overall data correctness" do

    before(:each) do
      @query = Barometer::Query.new("90210")
      @measurement = Barometer::Measurement.new
    end

    it "should correctly build the data" do
      result = WeatherService::WeatherBug._measure(@measurement, @query)

      # build current
      @measurement.current.humidity.to_i.should == 79
      @measurement.current.condition.should == "Sunny"
      @measurement.current.icon.should == "7"
      @measurement.current.temperature.to_i.should == 13
      @measurement.current.dew_point.to_i.should == 10
      @measurement.current.wind_chill.to_i.should == 14
      @measurement.current.wind.to_i.should == 0
      @measurement.current.wind.direction.should == "SE"
      @measurement.current.pressure.to_f.should == 1017.61

      # build sun
      @measurement.current.sun.rise.to_s.should == "05:42 am"
      @measurement.current.sun.set.to_s.should == "08:00 pm"
      
      # build station
      @measurement.station.id.should == "LSNGN"
      @measurement.station.name.should == "Alexander Hamilton Senior HS"
      @measurement.station.city.should == "Los Angeles"
      @measurement.station.state_code.should == "CA"
      @measurement.station.country.should == "USA"
      @measurement.station.zip_code.should == "90034"
      @measurement.station.latitude.to_f.should == 34.0336112976074
      @measurement.station.longitude.to_f.should == -118.389999389648
  
      # builds location
      @measurement.location.city.should == "Beverly Hills"
      @measurement.location.state_code.should == "CA"
      @measurement.location.zip_code.should == "90210"

      # builds forecasts
      @measurement.forecast.size.should == 7

      @measurement.forecast[0].date.should == Date.parse("Jun 2 2011")
      @measurement.forecast[0].condition.should == "Sunny"
      @measurement.forecast[0].icon.should == "7"
      @measurement.forecast[0].high.to_i.should == 24
      @measurement.forecast[0].low.to_i.should == 11

      @measurement.forecast[0].sun.rise.to_s.should == "05:42 am"
      @measurement.forecast[0].sun.set.to_s.should == "08:00 pm"
      
      # builds local time
      @measurement.measured_at.to_s.should == "07:01 am"
      @measurement.current.current_at.to_s.should == "07:01 am"
      
      # builds timezone
      @measurement.timezone.code.should == Data::Zone.new("PDT").code
      @measurement.timezone.offset.should == Data::Zone.new("PDT").offset
      @measurement.timezone.today.should == Data::Zone.new("PDT").today
    end

  end
  
end