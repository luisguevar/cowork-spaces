using System.Data;
using CoWork.Domain.DTOs;
using CoWork.Domain.Interfaces;
using CoWork.Infrastructure.Data;
using Dapper;

namespace CoWork.Infrastructure.Repositories;

public class ReportRepository : IReportRepository
{
    private readonly IDbConnectionFactory _connectionFactory;

    public ReportRepository(IDbConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<ReportResult> GetReportAsync(DateTime fromDate, DateTime toDate)
    {
        using var conn = _connectionFactory.Create();

        using var multi = await conn.QueryMultipleAsync(
            "sp_GetReports",
            new { FromDate = fromDate, ToDate = toDate },
            commandType: CommandType.StoredProcedure);

        var spaceOccupancies = await multi.ReadAsync<SpaceOccupancy>();
        var peakHour = await multi.ReadSingleOrDefaultAsync<PeakHour>();
        var totalRevenue = await multi.ReadSingleAsync<decimal>();

        return new ReportResult
        {
            SpaceOccupancies = spaceOccupancies,
            PeakHour = peakHour,
            TotalRevenue = totalRevenue
        };
    }
}