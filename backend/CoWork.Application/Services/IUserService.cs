using CoWork.Application.DTOs;
using System;
using System.Collections.Generic;
using System.Text;

namespace CoWork.Application.Services
{
    public interface IUserService
    {
        Task<IEnumerable<UserResponse>> GetAllAsync();
    }
}
