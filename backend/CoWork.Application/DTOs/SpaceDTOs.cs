namespace CoWork.Application.DTOs;

public class CreateSpaceRequest
{
    public string Name { get; set; } = string.Empty;
    public int Capacity { get; set; }
    public decimal HourlyRate { get; set; }
    public TimeOnly OpeningTime { get; set; }
    public TimeOnly ClosingTime { get; set; }
}

public class UpdateSpaceRequest
{
    public string Name { get; set; } = string.Empty;
    public int Capacity { get; set; }
    public decimal HourlyRate { get; set; }
    public TimeOnly OpeningTime { get; set; }
    public TimeOnly ClosingTime { get; set; }
    public string Status { get; set; } = string.Empty;
}

public class SpaceResponse
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int Capacity { get; set; }
    public decimal HourlyRate { get; set; }
    public TimeOnly OpeningTime { get; set; }
    public TimeOnly ClosingTime { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}