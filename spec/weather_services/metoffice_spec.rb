require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
include Barometer

describe "Metoffice" do
  
  before(:each) do
    @accepted_formats = [:coordinates]
    @base_uri = "http://partner.metoffice.gov.uk"
    @api_key = "1ab12345-1a12-12a1-12a1-123456789123"
    Barometer.config = { 1 => [ {:metoffice => {:keys => {:api_key => METOFFICE_KEY } }}] }
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
     
     it "returns the configured api key" do
       pending
       #WeatherService::Metoffice.api_key.should == METOFFICE_KEY
     end
    
    it "defines _fetch" do
      WeatherService::Metoffice.respond_to?("_fetch").should be_true
    end

    describe "keys=" do

      it "should raise an ArgumentError when not provided with a hash" do
        lambda { WeatherService::Metoffice.keys="test" }.should raise_error(ArgumentError)
      end

      it "should raise an ArgumentError if api key is not a String" do
        lambda { WeatherService::Metoffice.keys={ :api_key => Object } }.should raise_error(ArgumentError, "Mettoffice API key should be String")
      end


      it "should set the api key when the correct hash is passed through" do
        WeatherService::Metoffice.keys={ :api_key => METOFFICE_KEY }
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
    

    describe "_fetch", :vcr do

      before(:all) do
        @query = Barometer::Query.new("53.432996,-3.078296")
        @expected_url = "http://partner.metoffice.gov.uk/public/val/wxfcs/all/xml/nearestlatlon?res=3hourly&lat=53.432996&lon=-3.078296&key=#{METOFFICE_KEY}"
        WeatherService::Metoffice.api_key = METOFFICE_KEY
      end

      it "makes a request to the metoffice data point service" do
        WeatherService::Metoffice.should_receive(:get).with(@expected_url).and_return( {"SiteRep"=>{"DV"=>{}}} )
        WeatherService::Metoffice._fetch(@query)
      end

      it "returns a hash" do
        WeatherService::Metoffice._fetch(@query).class.should == Hash
      end

      it "contains a location hash" do
        WeatherService::Metoffice._fetch(@query)["Location"].class.should == Hash
      end
    end

    describe "_supports_country?" do

      it "should return true for UK" do
        pending
      end

      it "should return false for non UK country" do
        pending
      end

    end

  end
  
  describe "building the current data" do
    
    it "defines the build method" do
      pending
      WeatherService::Metoffice.respond_to?("_build_current").should be_true
    end
    
    it "requires Hash input" do
      pending
      lambda { WeatherService::Metoffice._build_current }.should raise_error(ArgumentError)
      lambda { WeatherService::Metoffice._build_current({}) }.should_not raise_error(ArgumentError)
    end
    
    it "returns Measurement::Current object" do
      pending
      current = WeatherService::Metoffice._build_current({})
      current.is_a?(Measurement::Result).should be_true
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
      lambda { WeatherService::Metoffice._build_location(nil,{}) }.should raise_error(ArgumentError)
      lambda { WeatherService::Metoffice._build_location(nil,geo) }.should_not raise_error(ArgumentError)
    end
    
    it "returns Barometer::Location object" do
      pending
      geo = Data::Geo.new({})
      location = WeatherService::Metoffice._build_location(nil,geo)
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
