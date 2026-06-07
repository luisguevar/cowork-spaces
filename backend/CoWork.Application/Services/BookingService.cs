using CoWork.Application.DTOs;
using CoWork.Domain.Entities;
using CoWork.Domain.Exceptions;
using CoWork.Domain.Interfaces;
using CoWork.Domain.Services;

namespace CoWork.Application.Services;

public class BookingService : IBookingService
{
    private readonly IBookingRepository _bookingRepository;
    private readonly ISpaceRepository _spaceRepository;
    private readonly PricingEngine _pricingEngine;
    private readonly CancellationPolicy _cancellationPolicy;

    public BookingService(
        IBookingRepository bookingRepository,
        ISpaceRepository spaceRepository)
    {
        _bookingRepository = bookingRepository;
        _spaceRepository = spaceRepository;
        _pricingEngine = new PricingEngine();
        _cancellationPolicy = new CancellationPolicy();
    }

    public async Task<IEnumerable<BookingResponse>> GetAllAsync(
        int? spaceId, int? userId, string? status)
    {
        var bookings = await _bookingRepository.GetAllAsync(spaceId, userId, status);
        return bookings.Select(MapToResponse);
    }

    public async Task<BookingResponse> GetByIdAsync(int id)
    {
        var booking = await _bookingRepository.GetByIdAsync(id)
            ?? throw new NotFoundException("Booking", id);
        return MapToResponse(booking);
    }

    public async Task<PricePreviewResponse> GetPricePreviewAsync(PricePreviewRequest request)
    {
        var space = await _spaceRepository.GetByIdAsync(request.SpaceId)
            ?? throw new NotFoundException("Space", request.SpaceId);

        var pricing = _pricingEngine.Calculate(
            space.HourlyRate,
            request.StartTime,
            request.EndTime,
            DateTime.UtcNow);

        return new PricePreviewResponse
        {
            BasePrice = pricing.BasePrice,
            PeakHourAdjustment = pricing.PeakHourAdjustment,
            WeekendAdjustment = pricing.WeekendAdjustment,
            LongBookingDiscount = pricing.LongBookingDiscount,
            EarlyBookingDiscount = pricing.EarlyBookingDiscount,
            FinalPrice = pricing.FinalPrice
        };
    }

    public async Task<BookingResponse> CreateAsync(CreateBookingRequest request)
    {
        // Validar que el espacio existe y esta activo
        var space = await _spaceRepository.GetByIdAsync(request.SpaceId)
            ?? throw new NotFoundException("Space", request.SpaceId);

        if (!space.IsActive)
            throw new DomainException("Ambiente no disponible para reservas.");

        // Validar horario dentro de apertura y cierre
        var startTimeOnly = TimeOnly.FromDateTime(request.StartTime);
        var endTimeOnly = TimeOnly.FromDateTime(request.EndTime);

        if (startTimeOnly < space.OpeningTime || endTimeOnly > space.ClosingTime)
            throw new DomainException(
                $"La reserva debe estar dentro del horario de apertura del ambiente " +
                $"({space.OpeningTime} - {space.ClosingTime}).");

        // Calcular precio
        var pricing = _pricingEngine.Calculate(
            space.HourlyRate,
            request.StartTime,
            request.EndTime,
            DateTime.UtcNow);

        // Crear reserva
        var booking = new Booking
        {
            SpaceId = request.SpaceId,
            UserId = request.UserId,
            StartTime = request.StartTime,
            EndTime = request.EndTime
        };

        var created = await _bookingRepository.CreateAsync(booking, pricing.FinalPrice);
        return MapToResponse(created);
    }

    public async Task<CancelBookingResponse> CancelAsync(int id)
    {
        var booking = await _bookingRepository.GetByIdAsync(id)
            ?? throw new NotFoundException("Booking", id);

        if (!booking.IsCancellable)
            throw new BookingNotCancellableException();

        var refund = _cancellationPolicy.CalculateRefund(
            booking.FinalPrice,
            booking.StartTime,
            DateTime.UtcNow);

        await _bookingRepository.CancelAsync(id, refund.RefundAmount);

        return new CancelBookingResponse
        {
            Id = booking.Id,
            Status = "Cancelled",
            FinalPrice = booking.FinalPrice,
            RefundAmount = refund.RefundAmount,
            RefundDescription = refund.Description
        };
    }

    public async Task<BookingResponse> UpdateStatusAsync(int id, UpdateBookingStatusRequest request)
    {
        var booking = await _bookingRepository.GetByIdAsync(id)
            ?? throw new NotFoundException("Booking", id);

        if (booking.Status == "Cancelled")
            throw new DomainException("Una reserva cancelada no se puede actualizar.");

        var updated = await _bookingRepository.UpdateStatusAsync(id, request.Status);
        return MapToResponse(updated);
    }

    private static BookingResponse MapToResponse(Booking booking) => new()
    {
        Id = booking.Id,
        SpaceId = booking.SpaceId,
        SpaceName = booking.SpaceName,
        UserId = booking.UserId,
        UserName = booking.UserName,
        StartTime = booking.StartTime,
        EndTime = booking.EndTime,
        Status = booking.Status,
        FinalPrice = booking.FinalPrice,
        RefundAmount = booking.RefundAmount,
        CreatedAt = booking.CreatedAt,
        UpdatedAt = booking.UpdatedAt
    };
}