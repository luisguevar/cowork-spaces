namespace CoWork.Domain.Exceptions;

public class BookingConflictException : DomainException
{
    public BookingConflictException()
        : base("El espacio se encuentra reservado para el horario seleccionado.") { }
}