namespace CoWork.Domain.Entities;

public class Booking
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

    public bool IsCancellable => Status != "Completed" && Status != "Cancelled";
    public double DurationInHours => (EndTime - StartTime).TotalHours;
}