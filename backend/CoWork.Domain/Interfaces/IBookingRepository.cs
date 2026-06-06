using CoWork.Domain.Entities;

namespace CoWork.Domain.Interfaces;

public interface IBookingRepository
{
    Task<IEnumerable<Booking>> GetAllAsync(int? spaceId, int? userId, string? status);
    Task<Booking?> GetByIdAsync(int id);
    Task<Booking> CreateAsync(Booking booking, decimal finalPrice);
    Task<Booking> CancelAsync(int id, decimal refundAmount);
}