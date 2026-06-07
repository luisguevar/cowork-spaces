using CoWork.Domain.Services;

namespace CoWork.Tests.PricingEngine;

public class PricingEngineTests
{
    private readonly Domain.Services.PricingEngine _engine = new();

    private static readonly DateTime CreatedToday = new(2026, 6, 8, 0, 0, 0);

    // =============================================
    // Test 1: Precio base sin modificadores
    // =============================================
    [Fact]
    public void Calculate_NoModifiers_ReturnsBasePrice()
    {
        // Lunes 14:00 - 16:00 (2 horas, sin hora pico, sin fin de semana)
        var start = new DateTime(2026, 6, 8, 14, 0, 0);
        var end = new DateTime(2026, 6, 8, 16, 0, 0);

        var result = _engine.Calculate(100m, start, end, CreatedToday);

        Assert.Equal(200m, result.BasePrice);
        Assert.Equal(0m, result.PeakHourAdjustment);
        Assert.Equal(0m, result.WeekendAdjustment);
        Assert.Equal(0m, result.LongBookingDiscount);
        Assert.Equal(0m, result.EarlyBookingDiscount);
        Assert.Equal(200m, result.FinalPrice);
    }

    // =============================================
    // Test 2: Hora pico manana (09:00 - 11:00)
    // =============================================
    [Fact]
    public void Calculate_PeakHourMorning_Applies25PercentSurcharge()
    {
        // Lunes 09:00 - 10:00 (1 hora, hora pico manana)
        var start = new DateTime(2026, 6, 8, 9, 0, 0);
        var end = new DateTime(2026, 6, 8, 10, 0, 0);

        var result = _engine.Calculate(100m, start, end, CreatedToday);

        Assert.Equal(100m, result.BasePrice);
        Assert.Equal(25m, result.PeakHourAdjustment);
        Assert.Equal(125m, result.FinalPrice);
    }

    // =============================================
    // Test 3: Hora pico tarde (17:00 - 19:00)
    // =============================================
    [Fact]
    public void Calculate_PeakHourAfternoon_Applies25PercentSurcharge()
    {
        // Lunes 17:00 - 18:00 (1 hora, hora pico tarde)
        var start = new DateTime(2026, 6, 8, 17, 0, 0);
        var end = new DateTime(2026, 6, 8, 18, 0, 0);

        var result = _engine.Calculate(100m, start, end, CreatedToday);

        Assert.Equal(100m, result.BasePrice);
        Assert.Equal(25m, result.PeakHourAdjustment);
        Assert.Equal(125m, result.FinalPrice);
    }

    // =============================================
    // Test 4: Fin de semana
    // =============================================
    [Fact]
    public void Calculate_Weekend_Applies15PercentSurcharge()
    {
        // Sabado 14:00 - 16:00 (2 horas, fin de semana, sin hora pico)
        var start = new DateTime(2026, 6, 13, 14, 0, 0);
        var end = new DateTime(2026, 6, 13, 16, 0, 0);

        var result = _engine.Calculate(100m, start, end, CreatedToday);

        Assert.Equal(200m, result.BasePrice);
        Assert.Equal(30m, result.WeekendAdjustment);
        Assert.Equal(230m, result.FinalPrice);
    }

    // =============================================
    // Test 5: Reserva larga (exactamente 4 horas)
    // =============================================
    [Fact]
    public void Calculate_LongBooking_Applies10PercentDiscount()
    {
        // Lunes 14:00 - 18:00 (exactamente 4 horas, sin otros modificadores)
        var start = new DateTime(2026, 6, 8, 14, 0, 0);
        var end = new DateTime(2026, 6, 8, 18, 0, 0);

        var result = _engine.Calculate(100m, start, end, CreatedToday);

        Assert.Equal(400m, result.BasePrice);
        Assert.Equal(40m, result.LongBookingDiscount);
        Assert.Equal(360m, result.FinalPrice);
    }

    // =============================================
    // Test 6: Anticipacion (exactamente 7 dias)
    // =============================================
    [Fact]
    public void Calculate_EarlyBooking_Applies5PercentDiscount()
    {
        // Lunes 14:00 - 16:00, creada exactamente 7 dias antes
        var start = new DateTime(2026, 6, 15, 14, 0, 0);
        var end = new DateTime(2026, 6, 15, 16, 0, 0);
        var createdAt = new DateTime(2026, 6, 8, 0, 0, 0);

        var result = _engine.Calculate(100m, start, end, createdAt);

        Assert.Equal(200m, result.BasePrice);
        Assert.Equal(10m, result.EarlyBookingDiscount);
        Assert.Equal(190m, result.FinalPrice);
    }

    // =============================================
    // Test 7: Hora pico + fin de semana combinados
    // =============================================
    [Fact]
    public void Calculate_PeakHourAndWeekend_AppliesBothSurcharges()
    {
        // Sabado 09:00 - 10:00 (hora pico manana + fin de semana)
        var start = new DateTime(2026, 6, 13, 9, 0, 0);
        var end = new DateTime(2026, 6, 13, 10, 0, 0);

        var result = _engine.Calculate(100m, start, end, CreatedToday);

        // Paso 1: 100 * 1 hora = 100
        // Paso 2: 100 + 25% = 125
        // Paso 3: 125 + 15% = 143.75
        Assert.Equal(100m, result.BasePrice);
        Assert.Equal(25m, result.PeakHourAdjustment);
        Assert.Equal(18.75m, result.WeekendAdjustment);
        Assert.Equal(143.75m, result.FinalPrice);
    }

    // =============================================
    // Test 8: Todos los modificadores activos
    // =============================================
    [Fact]
    public void Calculate_AllModifiers_AppliesInCorrectOrder()
    {
        // Sabado 09:00 - 13:00 (4 horas, hora pico, fin de semana, reserva larga)
        // Creada 10 dias antes (anticipacion)
        var start = new DateTime(2026, 6, 13, 9, 0, 0);
        var end = new DateTime(2026, 6, 13, 13, 0, 0);
        var createdAt = new DateTime(2026, 6, 3, 0, 0, 0);

        var result = _engine.Calculate(100m, start, end, createdAt);

        // Paso 1: 100 * 4 horas = 400
        // Paso 2: 400 + 25%     = 500
        // Paso 3: 500 + 15%     = 575
        // Paso 4: 575 - 10%     = 517.50
        // Paso 5: 517.50 - 5%   = 491.63
        Assert.Equal(400m, result.BasePrice);
        Assert.Equal(100m, result.PeakHourAdjustment);
        Assert.Equal(75m, result.WeekendAdjustment);
        Assert.Equal(57.50m, result.LongBookingDiscount);
        Assert.Equal(25.875m, result.EarlyBookingDiscount);  // valor real sin redondear
        Assert.Equal(491.62m, result.FinalPrice);           // solo FinalPrice se redondea
    }

    // =============================================
    // Test 9: Reserva de menos de 4 horas no aplica descuento largo
    // =============================================
    [Fact]
    public void Calculate_BookingUnder4Hours_NoLongBookingDiscount()
    {
        // Lunes 14:00 - 17:30 (3.5 horas)
        var start = new DateTime(2026, 6, 8, 14, 0, 0);
        var end = new DateTime(2026, 6, 8, 17, 30, 0);

        var result = _engine.Calculate(100m, start, end, CreatedToday);

        Assert.Equal(0m, result.LongBookingDiscount);
    }

    // =============================================
    // Test 10: Reserva creada con menos de 7 dias no aplica anticipacion
    // =============================================
    [Fact]
    public void Calculate_BookingUnder7DaysInAdvance_NoEarlyDiscount()
    {
        // Lunes 14:00 - 16:00, creada 6 dias antes
        var start = new DateTime(2026, 6, 14, 14, 0, 0);
        var end = new DateTime(2026, 6, 14, 16, 0, 0);
        var createdAt = new DateTime(2026, 6, 8, 0, 0, 0);

        var result = _engine.Calculate(100m, start, end, createdAt);

        Assert.Equal(0m, result.EarlyBookingDiscount);
    }
}