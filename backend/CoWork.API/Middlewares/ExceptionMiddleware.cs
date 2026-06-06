using CoWork.Domain.Exceptions;
using Microsoft.AspNetCore.Mvc;
using System.Net;
using System.Text.Json;

namespace CoWork.API.Middlewares;

public class ExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionMiddleware> _logger;

    public ExceptionMiddleware(RequestDelegate next, ILogger<ExceptionMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception: {Message}", ex.Message);
            await HandleExceptionAsync(context, ex);
        }
    }

    private static async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        var (statusCode, title) = exception switch
        {
            BookingConflictException => (HttpStatusCode.Conflict, "Booking Conflict"),
            NotFoundException => (HttpStatusCode.NotFound, "Not Found"),
            BookingNotCancellableException => (HttpStatusCode.BadRequest, "Booking Not Cancellable"),
            DomainException => (HttpStatusCode.BadRequest, "Business Rule Violation"),
            _ => (HttpStatusCode.InternalServerError, "Internal Server Error")
        };

        var problem = new ProblemDetails
        {
            Status = (int)statusCode,
            Title = title,
            Detail = exception is DomainException
                        ? exception.Message
                        : "An unexpected error occurred. Please try again later.",
            Instance = context.Request.Path
        };

        context.Response.ContentType = "application/problem+json";
        context.Response.StatusCode = (int)statusCode;

        await context.Response.WriteAsync(JsonSerializer.Serialize(problem));
    }
}