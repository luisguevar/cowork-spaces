using System.Net;
using System.Net.Http.Json;
using CoWork.Application.DTOs;
using Microsoft.AspNetCore.Mvc.Testing;

namespace CoWork.Tests.Concurrency;

public class ConcurrencyTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public ConcurrencyTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
    }

    private async Task<string> GetTokenAsync(HttpClient client)
    {
        var loginRequest = new { email = "john.smith@email.com", password = "12345678" };
        var loginResponse = await client.PostAsJsonAsync("/api/auth/login", loginRequest);
        var loginResult = await loginResponse.Content.ReadFromJsonAsync<LoginResult>();
        return loginResult?.Token ?? string.Empty;
    }

    [Fact]
    public async Task CreateBooking_TwoSimultaneousRequests_OnlyOneSucceeds()
    {
        var client = _factory.CreateClient();

        var token = await GetTokenAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);

        var request = new CreateBookingRequest
        {
            SpaceId = 1,
            UserId = 1,
            StartTime = DateTime.UtcNow.AddDays(15).Date.AddHours(14),
            EndTime = DateTime.UtcNow.AddDays(15).Date.AddHours(16)
        };

        var task1 = client.PostAsJsonAsync("/api/bookings", request);
        var task2 = client.PostAsJsonAsync("/api/bookings", request);

        var responses = await Task.WhenAll(task1, task2);

        var statusCodes = responses.Select(r => r.StatusCode).ToList();

        Assert.Contains(HttpStatusCode.Created, statusCodes);
        Assert.Contains(HttpStatusCode.Conflict, statusCodes);
        Assert.Equal(1, statusCodes.Count(s => s == HttpStatusCode.Created));
        Assert.Equal(1, statusCodes.Count(s => s == HttpStatusCode.Conflict));
    }


}

internal class LoginResult
{
    public string Token { get; set; } = string.Empty;
}