using CoWork.Application.DTOs;

namespace CoWork.Application.Services;

public interface IBookingService
{
    Task<IEnumerable<BookingResponse>> GetAllAsync(int? spaceId, int? userId, string? status);
    Task<BookingResponse> GetByIdAsync(int id);
    Task<BookingResponse> CreateAsync(CreateBookingRequest request);
    Task<PricePreviewResponse> GetPricePreviewAsync(PricePreviewRequest request);
    Task<CancelBookingResponse> CancelAsync(int id);
}