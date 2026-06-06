namespace CoWork.Application.DTOs;

public class CreateBookingRequest
{
    public int SpaceId { get; set; }
    public int UserId { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
}

public class BookingResponse
{
    public int Id { get; set; }
    public int SpaceId { get; set; }
    public string SpaceName { get; set; } = string.Empty;
    public int UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public string Status { get; set; } = string.Empty;
    public decimal FinalPrice { get; set; }
    public decimal RefundAmount { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class PricePreviewResponse
{
    public decimal BasePrice { get; set; }
    public decimal PeakHourAdjustment { get; set; }
    public decimal WeekendAdjustment { get; set; }
    public decimal LongBookingDiscount { get; set; }
    public decimal EarlyBookingDiscount { get; set; }
    public decimal FinalPrice { get; set; }
}

public class CancelBookingResponse
{
    public int Id { get; set; }
    public string Status { get; set; } = string.Empty;
    public decimal FinalPrice { get; set; }
    public decimal RefundAmount { get; set; }
    public string RefundDescription { get; set; } = string.Empty;
}

public class PricePreviewRequest
{
    public int SpaceId { get; set; }
    public int UserId { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
}