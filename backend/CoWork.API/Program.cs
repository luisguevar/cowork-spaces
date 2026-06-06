using CoWork.Application.Services;
using CoWork.Application.Validators;
using CoWork.Domain.Interfaces;
using CoWork.Infrastructure.Data;
using CoWork.Infrastructure.Repositories;
using FluentValidation;
using FluentValidation.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

// =============================================
// Servicios
// =============================================
// Dapper type handlers
Dapper.SqlMapper.AddTypeHandler(new CoWork.Infrastructure.Data.TimeOnlyTypeHandler());
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

// Swagger
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new()
    {
        Title = "CoWork Spaces API",
        Version = "v1",
        Description = "API for managing coworking space reservations"
    });
});

// FluentValidation
builder.Services.AddFluentValidationAutoValidation();
builder.Services.AddValidatorsFromAssemblyContaining<CreateSpaceValidator>();

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAngular", policy =>
    {
        policy.WithOrigins(
            "http://localhost:4200",
            "https://localhost:4200")
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// Connection Factory
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");

builder.Services.AddSingleton<IDbConnectionFactory>(
    new SqlConnectionFactory(connectionString));

// Repositorios
builder.Services.AddScoped<ISpaceRepository, SpaceRepository>();
builder.Services.AddScoped<IBookingRepository, BookingRepository>();
builder.Services.AddScoped<IReportRepository, ReportRepository>();
builder.Services.AddScoped<IUserRepository, UserRepository>();

// Servicios
builder.Services.AddScoped<ISpaceService, SpaceService>();
builder.Services.AddScoped<IBookingService, BookingService>();
builder.Services.AddScoped<IReportService, ReportService>();
builder.Services.AddScoped<IUserService, UserService>();

var app = builder.Build();

// =============================================
// Middleware pipeline
// =============================================

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "CoWork Spaces API v1");
        c.RoutePrefix = string.Empty;
    });
}
app.UseMiddleware<CoWork.API.Middlewares.ExceptionMiddleware>();
app.UseCors("AllowAngular");
//app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();

public partial class Program { }