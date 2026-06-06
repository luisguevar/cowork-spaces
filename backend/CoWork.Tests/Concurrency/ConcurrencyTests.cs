using CoWork.Application.DTOs;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.VisualStudio.TestPlatform.TestHost;
using System.Net;
using System.Net.Http.Json;

namespace CoWork.Tests.Concurrency;

public class ConcurrencyTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public ConcurrencyTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task CreateBooking_TwoSimultaneousRequests_OnlyOneSucceeds()
    {
        // Arrange
        var client = _factory.CreateClient();

        var request = new CreateBookingRequest
        {
            SpaceId = 1,
            UserId = 1,
            StartTime = DateTime.UtcNow.AddDays(15).Date.AddHours(14),
            EndTime = DateTime.UtcNow.AddDays(15).Date.AddHours(16)
        };

        // Act — lanzar dos peticiones simultaneas
        var task1 = client.PostAsJsonAsync("/api/bookings", request);
        var task2 = client.PostAsJsonAsync("/api/bookings", request);

        var responses = await Task.WhenAll(task1, task2);

        // Assert
        var statusCodes = responses.Select(r => r.StatusCode).ToList();

        Assert.Contains(HttpStatusCode.Created, statusCodes);
        Assert.Contains(HttpStatusCode.Conflict, statusCodes);
        Assert.Equal(1, statusCodes.Count(s => s == HttpStatusCode.Created));
        Assert.Equal(1, statusCodes.Count(s => s == HttpStatusCode.Conflict));
    }
}