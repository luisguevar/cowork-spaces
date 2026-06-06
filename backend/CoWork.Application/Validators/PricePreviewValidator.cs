using CoWork.Application.DTOs;
using FluentValidation;

namespace CoWork.Application.Validators;

public class PricePreviewValidator : AbstractValidator<PricePreviewRequest>
{
    public PricePreviewValidator()
    {
        RuleFor(x => x.SpaceId)
            .GreaterThan(0).WithMessage("El ID del espacio es requerido.");

        RuleFor(x => x.EndTime)
            .GreaterThan(x => x.StartTime)
            .WithMessage("La hora de finalización debe ser posterior a la hora de inicio.");

        RuleFor(x => x)
            .Must(x => (x.EndTime - x.StartTime).TotalMinutes >= 30)
            .WithMessage("La duración de la reserva debe ser de al menos 30 minutos.")
            .Must(x => (x.EndTime - x.StartTime).TotalHours <= 8)
            .WithMessage("La duración de la reserva no debe exceder las 8 horas.");
    }
}