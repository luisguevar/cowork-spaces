using System.Data;
using CoWork.Domain.Entities;
using CoWork.Domain.Exceptions;
using CoWork.Domain.Interfaces;
using CoWork.Infrastructure.Data;
using Dapper;
using Microsoft.Data.SqlClient;

namespace CoWork.Infrastructure.Repositories;

public class BookingRepository : IBookingRepository
{
    private readonly IDbConnectionFactory _connectionFactory;

    public BookingRepository(IDbConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<IEnumerable<Booking>> GetAllAsync(int? spaceId, int? userId, string? status)
    {
        using var conn = _connectionFactory.Create();
        return await conn.QueryAsync<Booking>(
            "sp_GetBookings",
            new { SpaceId = spaceId, UserId = userId, Status = status },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<Booking?> GetByIdAsync(int id)
    {
        using var conn = _connectionFactory.Create();
        return await conn.QuerySingleOrDefaultAsync<Booking>(
            "sp_GetBookingById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<Booking> CreateAsync(Booking booking, decimal finalPrice)
    {
        using var conn = _connectionFactory.Create();
        try
        {
            return await conn.QuerySingleAsync<Booking>(
                "sp_CreateBooking",
                new
                {
                    booking.SpaceId,
                    booking.UserId,
                    booking.StartTime,
                    booking.EndTime,
                    FinalPrice = finalPrice
                },
                commandType: CommandType.StoredProcedure);
        }
        catch (SqlException ex) when (ex.Message.Contains("BOOKING_CONFLICT"))
        {
            throw new BookingConflictException();
        }
    }

    public async Task<Booking> CancelAsync(int id, decimal refundAmount)
    {
        using var conn = _connectionFactory.Create();
        try
        {
            return await conn.QuerySingleAsync<Booking>(
                "sp_CancelBooking",
                new { Id = id, RefundAmount = refundAmount },
                commandType: CommandType.StoredProcedure);
        }
        catch (SqlException ex) when (ex.Message.Contains("BOOKING_NOT_FOUND"))
        {
            throw new NotFoundException("Booking", id);
        }
        catch (SqlException ex) when (ex.Message.Contains("BOOKING_ALREADY_COMPLETED"))
        {
            throw new BookingNotCancellableException();
        }
        catch (SqlException ex) when (ex.Message.Contains("BOOKING_ALREADY_CANCELLED"))
        {
            throw new DomainException("Booking is already cancelled.");
        }
    }
}