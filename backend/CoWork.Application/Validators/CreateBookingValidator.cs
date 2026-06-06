using CoWork.Application.DTOs;
using FluentValidation;

namespace CoWork.Application.Validators;

public class CreateBookingValidator : AbstractValidator<CreateBookingRequest>
{
    private const int MinDurationMinutes = 30;
    private const int MaxDurationHours = 8;

    public CreateBookingValidator()
    {
        RuleFor(x => x.SpaceId)
            .GreaterThan(0).WithMessage("El ID del espacio es requerido.");

        RuleFor(x => x.UserId)
            .GreaterThan(0).WithMessage("El ID del usuario es requerido.");

        RuleFor(x => x.StartTime)
            .GreaterThan(DateTime.Now).WithMessage("La hora de inicio debe estar en el futuro.");

        RuleFor(x => x.EndTime)
            .GreaterThan(x => x.StartTime).WithMessage("La hora de fin debe ser posterior a la hora de inicio.");

        RuleFor(x => x)
            .Must(x => (x.EndTime - x.StartTime).TotalMinutes >= MinDurationMinutes)
            .WithMessage("El tiempo de reserva debe ser de al menos 30 minutos.")
            .Must(x => (x.EndTime - x.StartTime).TotalHours <= MaxDurationHours)
            .WithMessage("El tiempo de reserva no debe exceder las 8 horas.");
    }
}