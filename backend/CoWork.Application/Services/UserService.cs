using CoWork.Application.DTOs;
using CoWork.Domain.Entities;
using CoWork.Domain.Interfaces;
using System;
using System.Collections.Generic;
using System.Text;

namespace CoWork.Application.Services
{
    public class UserService : IUserService
    {
        private readonly IUserRepository _userRepository;

        public UserService(IUserRepository userRepository)
        {
            _userRepository = userRepository;
        }

        public async Task<IEnumerable<UserResponse>> GetAllAsync()
        {
            var users = await _userRepository.GetAllAsync();
            return users.Select(MapToResponse);
        }

        private static UserResponse MapToResponse(User user) => new()
        {
            Id = user.Id,
            Name = user.Name,
            CreatedAt = user.CreatedAt,
            UpdatedAt = user.UpdatedAt
        };
    }
}
