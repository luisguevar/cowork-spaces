using CoWork.Domain.DTOs;

namespace CoWork.Domain.Interfaces;

public interface IReportRepository
{
    Task<ReportResult> GetReportAsync(DateTime fromDate, DateTime toDate);
}