namespace CoWork.Domain.Exceptions;

public class NotFoundException : DomainException
{
    public NotFoundException(string entity, int id)
        : base($"{entity} con id {id} no fue encontrado.") { }
}