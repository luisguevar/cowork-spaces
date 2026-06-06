using CoWork.Domain.Entities;
using CoWork.Domain.Interfaces;
using CoWork.Infrastructure.Data;
using Dapper;
using System;
using System.Collections.Generic;
using System.Data;
using System.Text;

namespace CoWork.Infrastructure.Repositories;

public class UserRepository : IUserRepository
{
    private readonly IDbConnectionFactory _connectionFactory;

    public UserRepository(IDbConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }
    public async Task<IEnumerable<User>> GetAllAsync()
    {
        using var conn = _connectionFactory.Create();
        return await conn.QueryAsync<User>(
            "sp_GetUsers",
            commandType: CommandType.StoredProcedure);
    }
}
