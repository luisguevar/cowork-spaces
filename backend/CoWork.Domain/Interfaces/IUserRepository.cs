using CoWork.Domain.Entities;

namespace CoWork.Domain.Interfaces;

public interface IUserRepository
{
    Task<IEnumerable<User>> GetAllAsync();
   
}