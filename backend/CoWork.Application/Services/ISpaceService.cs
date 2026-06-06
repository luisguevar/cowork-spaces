using CoWork.Application.DTOs;

namespace CoWork.Application.Services;

public interface ISpaceService
{
    Task<IEnumerable<SpaceResponse>> GetAllAsync(string? status);
    Task<SpaceResponse> GetByIdAsync(int id);
    Task<SpaceResponse> CreateAsync(CreateSpaceRequest request);
    Task<SpaceResponse> UpdateAsync(int id, UpdateSpaceRequest request);
    Task<SpaceResponse> DeactivateAsync(int id);
}