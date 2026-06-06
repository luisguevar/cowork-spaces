namespace CoWork.Domain.Services;

public class RefundResult
{
    public decimal RefundPercentage { get; set; }
    public decimal RefundAmount { get; set; }
    public string Description { get; set; } = string.Empty;
}

public class CancellationPolicy
{
    public RefundResult CalculateRefund(decimal finalPrice, DateTime startTime, DateTime now)
    {
        var hoursUntilStart = (startTime - now).TotalHours;

        if (hoursUntilStart >= 48)
            return new RefundResult
            {
                RefundPercentage = 100,
                RefundAmount = Math.Round(finalPrice, 2),
                Description = "Reembolso completo — cancelación realizada con más de 48 horas de antelación."
            };

        if (hoursUntilStart >= 24)
            return new RefundResult
            {
                RefundPercentage = 50,
                RefundAmount = Math.Round(finalPrice * 0.5m, 2),
                Description = "Reembolso parcial (50%) — cancelación realizada entre 24 y 48 horas de antelación."
            };

        return new RefundResult
        {
            RefundPercentage = 0,
            RefundAmount = 0,
            Description = "Sin reembolso — cancelación realizada con menos de 24 horas de antelación."
        };
    }
}