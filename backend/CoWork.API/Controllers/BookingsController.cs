using CoWork.Application.DTOs;
using CoWork.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace CoWork.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class BookingsController : ControllerBase
{
    private readonly IBookingService _bookingService;

    public BookingsController(IBookingService bookingService)
    {
        _bookingService = bookingService;
    }

    [HttpGet]
    [ProducesResponseType(typeof(IEnumerable<BookingResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAll(
        [FromQuery] int? spaceId,
        [FromQuery] int? userId,
        [FromQuery] string? status)
    {
        var bookings = await _bookingService.GetAllAsync(spaceId, userId, status);
        return Ok(bookings);
    }

    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(BookingResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(int id)
    {
        var booking = await _bookingService.GetByIdAsync(id);
        return Ok(booking);
    }

    [HttpPost]
    [ProducesResponseType(typeof(BookingResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Create([FromBody] CreateBookingRequest request)
    {
        var booking = await _bookingService.CreateAsync(request);
        return CreatedAtAction(nameof(GetById), new { id = booking.Id }, booking);
    }

    [HttpGet("price-preview")]
    [ProducesResponseType(typeof(PricePreviewResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPricePreview([FromQuery] PricePreviewRequest request)
    {
        var preview = await _bookingService.GetPricePreviewAsync(request);
        return Ok(preview);
    }

    [HttpPatch("{id:int}/cancel")]
    [ProducesResponseType(typeof(CancelBookingResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Cancel(int id)
    {
        var result = await _bookingService.CancelAsync(id);
        return Ok(result);
    }
}