public class OpenMeteoService {
    private static final String BASE_URL = 'https://api.open-meteo.com/v1/forecast';
    
    @InvocableMethod(label='Get Weather Forecast' description='Get weather forecast from Open-Meteo API')
    public static List<WeatherResult> getWeatherForecast(List<WeatherRequest> requests) {
        List<WeatherResult> results = new List<WeatherResult>();
        
        for (WeatherRequest req : requests) {
            WeatherResult result = new WeatherResult();
            
            try {
                // Build the API endpoint URL
                String endpoint = buildEndpointURL(req);
                
                // Make the callout
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint(endpoint);
                request.setMethod('GET');
                request.setTimeout(120000);
                
                HttpResponse response = http.send(request);
                
                if (response.getStatusCode() == 200) {
                    result.success = true;
                    result.responseBody = response.getBody();
                    result.parsedForecast = JSON.serialize(parseWeatherResponse(response.getBody()));
                } else {
                    result.success = false;
                    result.errorMessage = 'API Error: ' + response.getStatusCode() + ' ' + response.getStatus();
                }
            } catch (Exception e) {
                result.success = false;
                result.errorMessage = 'Exception: ' + e.getMessage();
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    private static String buildEndpointURL(WeatherRequest req) {
        String formattedStartDate = formatDate(req.startDate);
        String formattedEndDate = formatDate(req.endDate != null ? req.endDate : req.startDate.addDays(7));
        
        return BASE_URL + 
            '?latitude=' + req.latitude + 
            '&longitude=' + req.longitude +
            '&temperature_unit=fahrenheit&wind_speed_unit=mph&precipitation_unit=inch' +
            '&hourly=temperature_2m,relativehumidity_2m,precipitation,precipitation_probability,windspeed_10m,windgusts_10m,weathercode,soil_moisture_0_1cm' +
            '&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,windspeed_10m_max,windgusts_10m_max,weathercode' +
            '&timeformat=unixtime' +
            '&timezone=auto' +
            '&start_date=' + formattedStartDate +
            '&end_date=' + formattedEndDate;
    }
    
    private static String formatDate(Date d) {
        return d.year() + '-' + 
               String.valueOf(d.month()).leftPad(2, '0') + '-' + 
               String.valueOf(d.day()).leftPad(2, '0');
    }
    
    private static Map<String, Object> parseWeatherResponse(String jsonResponse) {
        return (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
    }
    
    // Weather request class for the invocable method
    public class WeatherRequest {
        @InvocableVariable(required=true label='Latitude')
        public Decimal latitude;
        
        @InvocableVariable(required=true label='Longitude')
        public Decimal longitude;
        
        @InvocableVariable(required=true label='Start Date')
        public Date startDate;
        
        @InvocableVariable(label='End Date')
        public Date endDate;
    }
    
    // Weather result class for the invocable method
    public class WeatherResult {
        @InvocableVariable
        public Boolean success;
        
        @InvocableVariable
        public String responseBody;
        
        @InvocableVariable
        public String errorMessage;
        
        @InvocableVariable
        public String parsedForecast; // Changed to String to store serialized JSON
    }
}