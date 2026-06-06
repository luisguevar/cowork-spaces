using CoWork.Application.DTOs;
using FluentValidation;

namespace CoWork.Application.Validators;

public class CreateSpaceValidator : AbstractValidator<CreateSpaceRequest>
{
    public CreateSpaceValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Nombre es requerido")
            .MaximumLength(100).WithMessage("El nombre no debe exceder los 100 caracteres.");

        RuleFor(x => x.Capacity)
            .GreaterThan(0).WithMessage("La capacidad debe ser mayor que 0.");

        RuleFor(x => x.HourlyRate)
            .GreaterThan(0).WithMessage("La tarifa por hora debe ser mayor que 0.");

        RuleFor(x => x.ClosingTime)
            .GreaterThan(x => x.OpeningTime)
            .WithMessage("La hora de cierre debe ser después de la hora de apertura.");
    }
}