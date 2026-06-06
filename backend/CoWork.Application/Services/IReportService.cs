using CoWork.Domain.DTOs;

namespace CoWork.Application.Services;

public interface IReportService
{
    Task<ReportResult> GetReportAsync(DateTime fromDate, DateTime toDate);
}