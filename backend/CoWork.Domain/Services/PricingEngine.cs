namespace CoWork.Domain.Services;

public class PricingResult
{
    public decimal BasePrice { get; set; }
    public decimal PeakHourAdjustment { get; set; }
    public decimal WeekendAdjustment { get; set; }
    public decimal LongBookingDiscount { get; set; }
    public decimal EarlyBookingDiscount { get; set; }
    public decimal FinalPrice { get; set; }
}

public class PricingEngine
{
    // Paso 1 - Precio base
    // Paso 2 - +25% hora pico (09:00-11:00 o 17:00-19:00)
    // Paso 3 - +15% fin de semana
    // Paso 4 - -10% reserva larga (>= 4 horas)
    // Paso 5 - -5% anticipacion (>= 7 dias)

    private const decimal PeakHourRate = 0.25m;
    private const decimal WeekendRate = 0.15m;
    private const decimal LongBookingRate = 0.10m;
    private const decimal EarlyBookingRate = 0.05m;

    public PricingResult Calculate(
        decimal hourlyRate,
        DateTime startTime,
        DateTime endTime,
        DateTime createdAt)
    {
        var result = new PricingResult();
        var durationHours = (decimal)(endTime - startTime).TotalHours;

        // Paso 1 - Precio base
        result.BasePrice = hourlyRate * durationHours;
        var subtotal = result.BasePrice;

        // Paso 2 - Hora pico
        var hour = startTime.Hour;
        var isPeakHour = (hour >= 9 && hour < 11) || (hour >= 17 && hour < 19);
        if (isPeakHour)
        {
            result.PeakHourAdjustment = subtotal * PeakHourRate;
            subtotal += result.PeakHourAdjustment;
        }

        // Paso 3 - Fin de semana
        var isWeekend = startTime.DayOfWeek == DayOfWeek.Saturday
                     || startTime.DayOfWeek == DayOfWeek.Sunday;
        if (isWeekend)
        {
            result.WeekendAdjustment = subtotal * WeekendRate;
            subtotal += result.WeekendAdjustment;
        }

        // Paso 4 - Reserva larga
        if (durationHours >= 4)
        {
            result.LongBookingDiscount = subtotal * LongBookingRate;
            subtotal -= result.LongBookingDiscount;
        }

        // Paso 5 - Anticipacion
        var daysInAdvance = (startTime.Date - createdAt.Date).TotalDays;
        if (daysInAdvance >= 7)
        {
            result.EarlyBookingDiscount = subtotal * EarlyBookingRate;
            subtotal -= result.EarlyBookingDiscount;
        }

        result.FinalPrice = Math.Round(subtotal, 2);
        return result;
    }
}