using Microsoft.AspNetCore.Mvc;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using GatewayApi.Models;

namespace GatewayApi.Controllers
{
    [Route("api/gateway")]
    [ApiController]
    public class GatewayController : ControllerBase
    {
        private readonly IHttpClientFactory _httpClientFactory;

        public GatewayController(IHttpClientFactory httpClientFactory)
        {
            _httpClientFactory = httpClientFactory;
        }

        private async Task<string> GetToken()
        {
            var client = _httpClientFactory.CreateClient();
            var content = new StringContent(JsonSerializer.Serialize(new { username = "admin", password = "admin123" }), Encoding.UTF8, "application/json");
            var response = await client.PostAsync("http://localhost:5205/api/v1/auth/login", content);
            if (!response.IsSuccessStatusCode)
            {
                var errorDetails = await response.Content.ReadAsStringAsync();
                throw new Exception($"Failed to get token: {response.StatusCode} - {errorDetails}");
            }
            var result = await response.Content.ReadAsStringAsync();
            using var jsonDocument = JsonDocument.Parse(result);
            var root = jsonDocument.RootElement;
            if (root.ValueKind == JsonValueKind.Object)
            {
                if (root.TryGetProperty("Token", out var tokenElement) && tokenElement.ValueKind == JsonValueKind.String)
                {
                    return "Bearer " + tokenElement.GetString();
                }
                if (root.TryGetProperty("token", out tokenElement) && tokenElement.ValueKind == JsonValueKind.String)
                {
                    return "Bearer " + tokenElement.GetString();
                }
                if (root.TryGetProperty("data", out var dataElement) && dataElement.ValueKind == JsonValueKind.Object)
                {
                    if (dataElement.TryGetProperty("token", out tokenElement) && tokenElement.ValueKind == JsonValueKind.String)
                    {
                        return "Bearer " + tokenElement.GetString();
                    }
                }
            }
            throw new Exception("Token not found in response: " + result);
        }

        [HttpPost("query-flight")]
        public async Task<IActionResult> QueryFlight([FromBody] FlightRequest request)
        {
            try
            {
                if (string.IsNullOrEmpty(request.FlightNumber))
                {
                    return BadRequest("FlightNumber is required");
                }
                if (string.IsNullOrEmpty(request.AirportFrom))
                {
                    return BadRequest("AirportFrom is required");
                }
                if (string.IsNullOrEmpty(request.AirportTo))
                {
                    return BadRequest("AirportTo is required");
                }
                var client = _httpClientFactory.CreateClient();
                var token = await GetToken();
                client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token.Replace("Bearer ", ""));
                var queryParams = $"?flightNumber={Uri.EscapeDataString(request.FlightNumber)}&airportFrom={Uri.EscapeDataString(request.AirportFrom)}&airportTo={Uri.EscapeDataString(request.AirportTo)}";
                var response = await client.GetAsync($"http://localhost:5205/api/v1/flights{queryParams}");
                if (!response.IsSuccessStatusCode)
                {
                    return StatusCode((int)response.StatusCode, await response.Content.ReadAsStringAsync());
                }
                var result = await response.Content.ReadAsStringAsync();
                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        [HttpPost("buy-ticket")]
        public async Task<IActionResult> BuyTicket([FromBody] FlightRequest request)
        {
            try
            {
                if (string.IsNullOrEmpty(request.FlightNumber))
                {
                    return BadRequest("FlightNumber is required");
                }

                if (request.Date == default)
                {
                    return BadRequest("Date is required");
                }
                if (request.PassengerNames == null || request.PassengerNames.Length == 0)
                {
                    return BadRequest("PassengerNames is required");
                }
                var client = _httpClientFactory.CreateClient();
                var token = await GetToken();
                var content = new StringContent(JsonSerializer.Serialize(new
                {
                    flightNumber = request.FlightNumber,
                    airportFrom = request.AirportFrom,
                    airportTo = request.AirportTo,
                    date = request.Date,
                    passengerNames = request.PassengerNames
                }), Encoding.UTF8, "application/json");
                client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token.Replace("Bearer ", ""));
                var response = await client.PostAsync("http://localhost:5205/api/v1/tickets", content);
                if (!response.IsSuccessStatusCode)
                {
                    return StatusCode((int)response.StatusCode, await response.Content.ReadAsStringAsync());
                }
                var result = await response.Content.ReadAsStringAsync();
                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        [HttpPost("check-in")]
        public async Task<IActionResult> CheckIn([FromBody] CheckInRequest request)
        {
            try
            {
                if (string.IsNullOrEmpty(request.FlightNumber))
                {
                    return BadRequest("FlightNumber is required");
                }

                if (string.IsNullOrEmpty(request.PassengerName))
                {
                    return BadRequest("PassengerName is required");
                }
                if (request.Date == default)
                {
                    return BadRequest("Date is required");
                }
                var client = _httpClientFactory.CreateClient();
                var token = await GetToken();
                var content = new StringContent(JsonSerializer.Serialize(new
                {
                    flightNumber = request.FlightNumber,
                    airportFrom = request.AirportFrom,
                    airportTo = request.AirportTo,
                    date = request.Date,
                    passengerName = request.PassengerName
                }), Encoding.UTF8, "application/json");
                client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token.Replace("Bearer ", ""));
                var response = await client.PostAsync("http://localhost:5205/api/v1/checkin", content);
                if (!response.IsSuccessStatusCode)
                {
                    return StatusCode((int)response.StatusCode, await response.Content.ReadAsStringAsync());
                }
                var result = await response.Content.ReadAsStringAsync();
                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }
    }

public class CheckInRequest
    {
        public string FlightNumber { get; set; }
        public string AirportFrom { get; set; }
        public string AirportTo { get; set; }
        public string PassengerName { get; set; }
        public DateTime Date { get; set; }
    }
}