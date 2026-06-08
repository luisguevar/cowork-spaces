-- =============================================
-- CoWork Spaces Booking System
-- Procedures: Bookings
-- Author: Luis Guevara A.
-- Date: 09/06/2026
-- =============================================

USE CoWorkSpaces;
GO

-- =============================================
-- sp_GetBookings
-- =============================================
CREATE OR ALTER PROCEDURE sp_GetBookings
    @SpaceId    INT             = NULL,
    @UserId     INT             = NULL,
    @Status     NVARCHAR(20)    = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        b.Id,
        b.SpaceId,
        s.Name          AS SpaceName,
        b.UserId,
        u.Name          AS UserName,
        b.StartTime,
        b.EndTime,
        b.Status,
        b.FinalPrice,
        b.RefundAmount,
        b.CreatedAt,
        b.UpdatedAt
    FROM Bookings b
    INNER JOIN Spaces s ON s.Id = b.SpaceId
    INNER JOIN Users  u ON u.Id = b.UserId
    WHERE
        (@SpaceId   IS NULL OR b.SpaceId    = @SpaceId)
        AND (@UserId IS NULL OR b.UserId    = @UserId)
        AND (@Status IS NULL OR b.Status    = @Status)
    ORDER BY b.StartTime DESC;
END
GO

-- =============================================
-- sp_GetBookingById
-- =============================================
CREATE OR ALTER PROCEDURE sp_GetBookingById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        b.Id,
        b.SpaceId,
        s.Name          AS SpaceName,
        b.UserId,
        u.Name          AS UserName,
        b.StartTime,
        b.EndTime,
        b.Status,
        b.FinalPrice,
        b.RefundAmount,
        b.CreatedAt,
        b.UpdatedAt
    FROM Bookings b
    INNER JOIN Spaces s ON s.Id = b.SpaceId
    INNER JOIN Users  u ON u.Id = b.UserId
    WHERE b.Id = @Id;
END
GO

-- =============================================
-- sp_CreateBooking (CRITICO - Concurrencia)
-- =============================================
CREATE OR ALTER PROCEDURE sp_CreateBooking
    @SpaceId    INT,
    @UserId     INT,
    @StartTime  DATETIME2,
    @EndTime    DATETIME2,
    @FinalPrice DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;

    BEGIN TRY
        -- Adquirir lock pesimista sobre el espacio
        -- Bloquea el registro hasta que la transaccion termine
        SELECT Id
        FROM Spaces WITH (UPDLOCK, ROWLOCK)
        WHERE Id = @SpaceId;

        -- Verificar solapamiento dentro de la transaccion
        -- StartTime < @EndTime AND EndTime > @StartTime cubre todos los casos de solapamiento parcial
        IF EXISTS (
            SELECT 1
            FROM Bookings
            WHERE SpaceId   = @SpaceId
            AND   Status    NOT IN ('Cancelled')
            AND   StartTime < @EndTime
            AND   EndTime   > @StartTime
        )
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR('BOOKING_CONFLICT', 16, 1);
            RETURN;
        END

        -- Insertar la reserva
        INSERT INTO Bookings (SpaceId, UserId, StartTime, EndTime, Status, FinalPrice, RefundAmount)
        VALUES (@SpaceId, @UserId, @StartTime, @EndTime, 'Pending', @FinalPrice, 0);

        COMMIT TRANSACTION;

        -- Retornar la reserva creada
        SELECT
            b.Id,
            b.SpaceId,
            s.Name          AS SpaceName,
            b.UserId,
            u.Name          AS UserName,
            b.StartTime,
            b.EndTime,
            b.Status,
            b.FinalPrice,
            b.RefundAmount,
            b.CreatedAt,
            b.UpdatedAt
        FROM Bookings b
        INNER JOIN Spaces s ON s.Id = b.SpaceId
        INNER JOIN Users  u ON u.Id = b.UserId
        WHERE b.Id = SCOPE_IDENTITY();

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- =============================================
-- sp_CancelBooking
-- =============================================
CREATE OR ALTER PROCEDURE sp_CancelBooking
    @Id             INT,
    @RefundAmount   DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Bookings WHERE Id = @Id)
    BEGIN
        RAISERROR('BOOKING_NOT_FOUND', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM Bookings WHERE Id = @Id AND Status = 'Completed')
    BEGIN
        RAISERROR('BOOKING_ALREADY_COMPLETED', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM Bookings WHERE Id = @Id AND Status = 'Cancelled')
    BEGIN
        RAISERROR('BOOKING_ALREADY_CANCELLED', 16, 1);
        RETURN;
    END

    UPDATE Bookings
    SET
        Status          = 'Cancelled',
        RefundAmount    = @RefundAmount,
        UpdatedAt       = GETDATE()
    WHERE Id = @Id;

    SELECT
        b.Id,
        b.SpaceId,
        s.Name          AS SpaceName,
        b.UserId,
        u.Name          AS UserName,
        b.StartTime,
        b.EndTime,
        b.Status,
        b.FinalPrice,
        b.RefundAmount,
        b.CreatedAt,
        b.UpdatedAt
    FROM Bookings b
    INNER JOIN Spaces s ON s.Id = b.SpaceId
    INNER JOIN Users  u ON u.Id = b.UserId
    WHERE b.Id = @Id;
END
GO