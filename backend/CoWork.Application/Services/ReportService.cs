using CoWork.Domain.DTOs;
using CoWork.Domain.Interfaces;

namespace CoWork.Application.Services;

public class ReportService : IReportService
{
    private readonly IReportRepository _reportRepository;

    public ReportService(IReportRepository reportRepository)
    {
        _reportRepository = reportRepository;
    }

    public async Task<ReportResult> GetReportAsync(DateTime fromDate, DateTime toDate)
    {
        return await _reportRepository.GetReportAsync(fromDate, toDate);
    }
}