using CoWork.Domain.Entities;

namespace CoWork.Domain.Interfaces;

public interface ISpaceRepository
{
    Task<IEnumerable<Space>> GetAllAsync(string? status);
    Task<Space?> GetByIdAsync(int id);
    Task<Space> CreateAsync(Space space);
    Task<Space> UpdateAsync(Space space);
    Task<Space> DeactivateAsync(int id);
}