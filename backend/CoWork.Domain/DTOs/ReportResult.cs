namespace CoWork.Domain.DTOs;

public class SpaceOccupancy
{
    public int SpaceId { get; set; }
    public string SpaceName { get; set; } = string.Empty;
    public decimal HourlyRate { get; set; }
    public int TotalBookings { get; set; }
    public decimal BookedHours { get; set; }
    public decimal OccupancyRate { get; set; }
    public decimal TotalRevenue { get; set; }
}

public class PeakHour
{
    public int Hour { get; set; }
    public int BookingCount { get; set; }
}

public class ReportResult
{
    public IEnumerable<SpaceOccupancy> SpaceOccupancies { get; set; } = [];
    public PeakHour? PeakHour { get; set; }
    public decimal TotalRevenue { get; set; }
}