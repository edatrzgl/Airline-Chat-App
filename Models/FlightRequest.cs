namespace GatewayApi.Models
{
    public class FlightRequest
    {
        public string FlightNumber { get; set; }
        public string AirportFrom { get; set; }
        public string AirportTo { get; set; }
        public DateTime Date { get; set; }
        public string[] PassengerNames { get; set; }
    }
}