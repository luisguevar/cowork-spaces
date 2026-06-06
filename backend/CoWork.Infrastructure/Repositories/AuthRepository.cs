using System.Data;
using CoWork.Domain.Entities;
using CoWork.Domain.Interfaces;
using CoWork.Infrastructure.Data;
using Dapper;

namespace CoWork.Infrastructure.Repositories;

public class AuthRepository : IAuthRepository
{
    private readonly IDbConnectionFactory _connectionFactory;

    public AuthRepository(IDbConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<User?> GetByEmailAsync(string email)
    {
        using var conn = _connectionFactory.Create();
        return await conn.QuerySingleOrDefaultAsync<User>(
            "sp_Login",
            new { Email = email },
            commandType: CommandType.StoredProcedure);
    }
}