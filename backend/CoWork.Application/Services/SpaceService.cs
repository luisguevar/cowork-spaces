using CoWork.Application.DTOs;
using CoWork.Domain.Entities;
using CoWork.Domain.Exceptions;
using CoWork.Domain.Interfaces;

namespace CoWork.Application.Services;

public class SpaceService : ISpaceService
{
    private readonly ISpaceRepository _spaceRepository;

    public SpaceService(ISpaceRepository spaceRepository)
    {
        _spaceRepository = spaceRepository;
    }

    public async Task<IEnumerable<SpaceResponse>> GetAllAsync(string? status)
    {
        var spaces = await _spaceRepository.GetAllAsync(status);
        return spaces.Select(MapToResponse);
    }

    public async Task<SpaceResponse> GetByIdAsync(int id)
    {
        var space = await _spaceRepository.GetByIdAsync(id)
            ?? throw new NotFoundException("Space", id);
        return MapToResponse(space);
    }

    public async Task<SpaceResponse> CreateAsync(CreateSpaceRequest request)
    {
        var space = new Space
        {
            Name = request.Name,
            Capacity = request.Capacity,
            HourlyRate = request.HourlyRate,
            OpeningTime = request.OpeningTime,
            ClosingTime = request.ClosingTime
        };

        var created = await _spaceRepository.CreateAsync(space);
        return MapToResponse(created);
    }

    public async Task<SpaceResponse> UpdateAsync(int id, UpdateSpaceRequest request)
    {
        var space = new Space
        {
            Id = id,
            Name = request.Name,
            Capacity = request.Capacity,
            HourlyRate = request.HourlyRate,
            OpeningTime = request.OpeningTime,
            ClosingTime = request.ClosingTime,
            Status = request.Status
        };

        var updated = await _spaceRepository.UpdateAsync(space);
        return MapToResponse(updated);
    }

    public async Task<SpaceResponse> DeactivateAsync(int id)
    {
        var deactivated = await _spaceRepository.DeactivateAsync(id);
        return MapToResponse(deactivated);
    }

    private static SpaceResponse MapToResponse(Space space) => new()
    {
        Id = space.Id,
        Name = space.Name,
        Capacity = space.Capacity,
        HourlyRate = space.HourlyRate,
        OpeningTime = space.OpeningTime,
        ClosingTime = space.ClosingTime,
        Status = space.Status,
        CreatedAt = space.CreatedAt,
        UpdatedAt = space.UpdatedAt
    };
}