using CoWork.Application.Services;
using CoWork.Domain.DTOs;
using Microsoft.AspNetCore.Mvc;

namespace CoWork.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ReportsController : ControllerBase
{
    private readonly IReportService _reportService;

    public ReportsController(IReportService reportService)
    {
        _reportService = reportService;
    }

    [HttpGet]
    [ProducesResponseType(typeof(ReportResult), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> GetReport(
        [FromQuery] DateTime fromDate,
        [FromQuery] DateTime toDate)
    {
        if (toDate <= fromDate)
            return BadRequest("La fecha fin debe ser posterior a la fecha de inicio.");

        var report = await _reportService.GetReportAsync(fromDate, toDate);
        return Ok(report);
    }
}