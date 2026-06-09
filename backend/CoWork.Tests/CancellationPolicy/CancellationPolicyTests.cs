using CoWork.Domain.Services;

namespace CoWork.Tests.CancellationPolicy;

public class CancellationPolicyTests
{
    private readonly Domain.Services.CancellationPolicy _policy = new();

    // =============================================
    // Test 1: Cancelacion con mas de 48h → 100%
    // =============================================
    [Fact]
    public void CalculateRefund_MoreThan48Hours_Returns100PercentRefund()
    {
        var startTime = DateTime.UtcNow.AddHours(72);
        var now = DateTime.UtcNow;

        var result = _policy.CalculateRefund(200m, startTime, now);

        Assert.Equal(100m, result.RefundPercentage);
        Assert.Equal(200m, result.RefundAmount);
    }

    // =============================================
    // Test 2: Cancelacion exactamente en 48h → 100%
    // =============================================
    [Fact]
    public void CalculateRefund_Exactly48Hours_Returns100PercentRefund()
    {
        var now = DateTime.UtcNow;
        var startTime = now.AddHours(48);

        var result = _policy.CalculateRefund(200m, startTime, now);

        Assert.Equal(100m, result.RefundPercentage);
        Assert.Equal(200m, result.RefundAmount);
    }

    // =============================================
    // Test 3: Cancelacion entre 24h y 48h → 50%
    // =============================================
    [Fact]
    public void CalculateRefund_Between24And48Hours_Returns50PercentRefund()
    {
        var startTime = DateTime.UtcNow.AddHours(36);
        var now = DateTime.UtcNow;

        var result = _policy.CalculateRefund(200m, startTime, now);

        Assert.Equal(50m, result.RefundPercentage);
        Assert.Equal(100m, result.RefundAmount);
    }

    // =============================================
    // Test 4: Cancelacion exactamente en 24h → 50%
    // =============================================
    [Fact]
    public void CalculateRefund_Exactly24Hours_Returns50PercentRefund()
    {
        var now = DateTime.UtcNow;
        var startTime = now.AddHours(24);

        var result = _policy.CalculateRefund(200m, startTime, now);

        Assert.Equal(50m, result.RefundPercentage);
        Assert.Equal(100m, result.RefundAmount);
    }

    // =============================================
    // Test 5: Cancelacion con menos de 24h → 0%
    // =============================================
    [Fact]
    public void CalculateRefund_LessThan24Hours_Returns0PercentRefund()
    {
        var startTime = DateTime.UtcNow.AddHours(12);
        var now = DateTime.UtcNow;

        var result = _policy.CalculateRefund(200m, startTime, now);

        Assert.Equal(0m, result.RefundPercentage);
        Assert.Equal(0m, result.RefundAmount);
    }

    // =============================================
    // Test 6: Cancelacion con menos de 1h → 0%
    // =============================================
    [Fact]
    public void CalculateRefund_LessThan1Hour_Returns0PercentRefund()
    {
        var startTime = DateTime.UtcNow.AddMinutes(30);
        var now = DateTime.UtcNow;

        var result = _policy.CalculateRefund(200m, startTime, now);

        Assert.Equal(0m, result.RefundPercentage);
        Assert.Equal(0m, result.RefundAmount);
    }

    // =============================================
    // Test 7: Reembolso se calcula correctamente sobre el precio final
    // =============================================
    [Fact]
    public void CalculateRefund_50Percent_CalculatesCorrectAmount()
    {
        var startTime = DateTime.UtcNow.AddHours(36);
        var now = DateTime.UtcNow;

        var result = _policy.CalculateRefund(350m, startTime, now);

        Assert.Equal(50m, result.RefundPercentage);
        Assert.Equal(175m, result.RefundAmount);
    }

    // =============================================
    // Test 8: Descripcion correcta por tramo
    // =============================================
    [Fact]
    public void CalculateRefund_EachTier_ReturnsCorrectDescription()
    {
        var now = DateTime.UtcNow;

        var full = _policy.CalculateRefund(100m, now.AddHours(72), now);
        var partial = _policy.CalculateRefund(100m, now.AddHours(36), now);
        var none = _policy.CalculateRefund(100m, now.AddHours(12), now);

        Assert.Contains("Reembolso completo", full.Description);
        Assert.Contains("50%", partial.Description);
        Assert.Contains("Sin reembolso", none.Description);
    }

    [Fact]
    public void CalculateRefund_47Hours55Minutes_Returns50PercentRefund()
    {
        var now = DateTime.UtcNow;
        var startTime = now.AddHours(47).AddMinutes(55);

        var result = _policy.CalculateRefund(200m, startTime, now);

        Assert.Equal(50m, result.RefundPercentage);
        Assert.Equal(100m, result.RefundAmount);
    }

    [Fact]
    public void CalculateRefund_48Hours5Minutes_Returns100PercentRefund()
    {
        var now = DateTime.UtcNow;
        var startTime = now.AddHours(48).AddMinutes(5);

        var result = _policy.CalculateRefund(200m, startTime, now);

        Assert.Equal(100m, result.RefundPercentage);
        Assert.Equal(200m, result.RefundAmount);
    }
}