using CoWork.Domain.Entities;

namespace CoWork.Domain.Interfaces;

public interface IAuthRepository
{
    Task<User?> GetByEmailAsync(string email);
}