-- =============================================
-- CoWork Status Booking System
-- Procedures: Status Booking
-- Author: Luis Guevara A.
-- Date: 09/06/2026
-- =============================================

USE CoWorkSpaces;
GO


CREATE OR ALTER PROCEDURE sp_UpdateBookingStatus
    @Id     INT,
    @Status NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Bookings WHERE Id = @Id)
    BEGIN RAISERROR('BOOKING_NOT_FOUND', 16, 1); RETURN; END

    IF EXISTS (SELECT 1 FROM Bookings WHERE Id = @Id AND Status = 'Cancelled')
    BEGIN RAISERROR('BOOKING_ALREADY_CANCELLED', 16, 1); RETURN; END

    IF @Status NOT IN ('Pending', 'Confirmed', 'Completed')
    BEGIN RAISERROR('INVALID_STATUS', 16, 1); RETURN; END

    UPDATE Bookings
    SET Status    = @Status,
        UpdatedAt = GETDATE()
    WHERE Id = @Id;

    SELECT b.Id, b.SpaceId, s.Name AS SpaceName, b.UserId, u.Name AS UserName,
           b.StartTime, b.EndTime, b.Status, b.FinalPrice, b.RefundAmount,
           b.CreatedAt, b.UpdatedAt
    FROM Bookings b
    INNER JOIN Spaces s ON s.Id = b.SpaceId
    INNER JOIN Users  u ON u.Id = b.UserId
    WHERE b.Id = @Id;
END
GO