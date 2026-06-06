namespace CoWork.Domain.Exceptions;

public class BookingNotCancellableException : DomainException
{
    public BookingNotCancellableException()
        : base("Una reserva completada no puede ser cancelada.") { }
}