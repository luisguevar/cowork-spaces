using System.Data;
using CoWork.Domain.Entities;
using CoWork.Domain.Exceptions;
using CoWork.Domain.Interfaces;
using CoWork.Infrastructure.Data;
using Dapper;

namespace CoWork.Infrastructure.Repositories;

public class SpaceRepository : ISpaceRepository
{
    private readonly IDbConnectionFactory _connectionFactory;

    public SpaceRepository(IDbConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<IEnumerable<Space>> GetAllAsync(string? status)
    {
        using var conn = _connectionFactory.Create();
        return await conn.QueryAsync<Space>(
            "sp_GetSpaces",
            new { Status = status },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<Space?> GetByIdAsync(int id)
    {
        using var conn = _connectionFactory.Create();
        return await conn.QuerySingleOrDefaultAsync<Space>(
            "sp_GetSpaceById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<Space> CreateAsync(Space space)
    {
        using var conn = _connectionFactory.Create();
        return await conn.QuerySingleAsync<Space>(
            "sp_CreateSpace",
            new
            {
                space.Name,
                space.Capacity,
                space.HourlyRate,
                space.OpeningTime,
                space.ClosingTime
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<Space> UpdateAsync(Space space)
    {
        using var conn = _connectionFactory.Create();
        try
        {
            return await conn.QuerySingleAsync<Space>(
                "sp_UpdateSpace",
                new
                {
                    space.Id,
                    space.Name,
                    space.Capacity,
                    space.HourlyRate,
                    space.OpeningTime,
                    space.ClosingTime,
                    space.Status
                },
                commandType: CommandType.StoredProcedure);
        }
        catch (Exception ex) when (ex.Message.Contains("SPACE_NOT_FOUND"))
        {
            throw new NotFoundException("Space", space.Id);
        }
    }

    public async Task<Space> DeactivateAsync(int id)
    {
        using var conn = _connectionFactory.Create();
        try
        {
            return await conn.QuerySingleAsync<Space>(
                "sp_DeactivateSpace",
                new { Id = id },
                commandType: CommandType.StoredProcedure);
        }
        catch (Exception ex) when (ex.Message.Contains("SPACE_NOT_FOUND"))
        {
            throw new NotFoundException("Space", id);
        }
    }
}