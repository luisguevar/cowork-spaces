using CoWork.Application.DTOs;

namespace CoWork.Application.Services;

public interface IAuthService
{
    Task<LoginResponse> LoginAsync(LoginRequest request);
}