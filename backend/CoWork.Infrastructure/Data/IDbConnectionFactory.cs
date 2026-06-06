using System.Data;

namespace CoWork.Infrastructure.Data;

public interface IDbConnectionFactory
{
    IDbConnection Create();
}