-- =============================================
-- CoWork Spaces Booking System
-- 001_sp_schema.sql
-- =============================================

-- =============================================
-- CoWork Spaces Booking System
-- Procedures: Spaces
-- Author: Luis Guevara A.
-- Date: 09/06/2026
-- =============================================

USE CoWorkSpaces;
GO

-- =============================================
-- sp_GetSpaces
-- =============================================
CREATE OR ALTER PROCEDURE sp_GetSpaces
    @Status NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id,
        Name,
        Capacity,
        HourlyRate,
        OpeningTime,
        ClosingTime,
        Status,
        CreatedAt,
        UpdatedAt
    FROM Spaces
    WHERE (@Status IS NULL OR Status = @Status)
    ORDER BY Name ASC;
END
GO

-- =============================================
-- sp_GetSpaceById
-- =============================================
CREATE OR ALTER PROCEDURE sp_GetSpaceById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id,
        Name,
        Capacity,
        HourlyRate,
        OpeningTime,
        ClosingTime,
        Status,
        CreatedAt,
        UpdatedAt
    FROM Spaces
    WHERE Id = @Id;
END
GO

-- =============================================
-- sp_CreateSpace
-- =============================================
CREATE OR ALTER PROCEDURE sp_CreateSpace
    @Name           NVARCHAR(100),
    @Capacity       INT,
    @HourlyRate     DECIMAL(10,2),
    @OpeningTime    TIME,
    @ClosingTime    TIME
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Spaces (Name, Capacity, HourlyRate, OpeningTime, ClosingTime, Status)
    VALUES (@Name, @Capacity, @HourlyRate, @OpeningTime, @ClosingTime, 'active');

    SELECT
        Id,
        Name,
        Capacity,
        HourlyRate,
        OpeningTime,
        ClosingTime,
        Status,
        CreatedAt,
        UpdatedAt
    FROM Spaces
    WHERE Id = SCOPE_IDENTITY();
END
GO

-- =============================================
-- sp_UpdateSpace
-- =============================================
CREATE OR ALTER PROCEDURE sp_UpdateSpace
    @Id             INT,
    @Name           NVARCHAR(100),
    @Capacity       INT,
    @HourlyRate     DECIMAL(10,2),
    @OpeningTime    TIME,
    @ClosingTime    TIME,
    @Status         NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Spaces WHERE Id = @Id)
    BEGIN
        RAISERROR('SPACE_NOT_FOUND', 16, 1);
        RETURN;
    END

    UPDATE Spaces
    SET
        Name        = @Name,
        Capacity    = @Capacity,
        HourlyRate  = @HourlyRate,
        OpeningTime = @OpeningTime,
        ClosingTime = @ClosingTime,
        Status      = @Status,
        UpdatedAt   = GETDATE()
    WHERE Id = @Id;

    SELECT
        Id,
        Name,
        Capacity,
        HourlyRate,
        OpeningTime,
        ClosingTime,
        Status,
        CreatedAt,
        UpdatedAt
    FROM Spaces
    WHERE Id = @Id;
END
GO

-- =============================================
-- sp_DeactivateSpace
-- =============================================
CREATE OR ALTER PROCEDURE sp_DeactivateSpace
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Spaces WHERE Id = @Id)
    BEGIN
        RAISERROR('SPACE_NOT_FOUND', 16, 1);
        RETURN;
    END

    UPDATE Spaces
    SET
        Status      = 'maintenance',
        UpdatedAt   = GETDATE()
    WHERE Id = @Id;

    SELECT
        Id,
        Name,
        Capacity,
        HourlyRate,
        OpeningTime,
        ClosingTime,
        Status,
        CreatedAt,
        UpdatedAt
    FROM Spaces
    WHERE Id = @Id;
END
GO

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
    ORDER BY b.CreatedAt DESC;
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

-- =============================================
-- CoWork Spaces Booking System
-- Procedures: Reports
-- Author: Luis Guevara A.
-- Date: 09/06/2026
-- =============================================
USE CoWorkSpaces;
GO

CREATE OR ALTER PROCEDURE sp_GetReports
    @FromDate   DATETIME2,
    @ToDate     DATETIME2
AS
BEGIN
    SET NOCOUNT ON;

    SET @FromDate = CAST(CAST(@FromDate AS DATE) AS DATETIME2);
    SET @ToDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, CAST(CAST(@ToDate AS DATE) AS DATETIME2)));

    -- Calcular dias en el rango
    DECLARE @TotalDays DECIMAL(10,2);
    SET @TotalDays = DATEDIFF(DAY, @FromDate, @ToDate);

    -- Ocupacion e ingresos por espacio
    SELECT
        s.Id                                                        AS SpaceId,
        s.Name                                                      AS SpaceName,
        s.HourlyRate,
        COUNT(b.Id)                                                 AS TotalBookings,
        ISNULL(SUM(DATEDIFF(MINUTE, b.StartTime, b.EndTime)) / 60.0, 0)
                                                                    AS BookedHours,
       CASE
        WHEN @TotalDays > 0 
         AND DATEDIFF(HOUR, s.OpeningTime, s.ClosingTime) > 0
        THEN ROUND(
            ISNULL(SUM(DATEDIFF(MINUTE, b.StartTime, b.EndTime)) / 60.0, 0)
            / NULLIF(
                @TotalDays * DATEDIFF(HOUR, s.OpeningTime, s.ClosingTime),
                0)
            * 100, 2)
        ELSE 0
    END AS OccupancyRate,
        ISNULL(SUM(b.FinalPrice), 0)                                AS TotalRevenue
    FROM Spaces s
    LEFT JOIN Bookings b ON b.SpaceId = s.Id
        AND b.Status    NOT IN ('Cancelled')
        AND b.StartTime >= @FromDate
        AND b.EndTime   <= @ToDate
    GROUP BY s.Id, s.Name, s.HourlyRate, s.OpeningTime, s.ClosingTime
    ORDER BY TotalRevenue DESC;

    -- Horario mas demandado (por hora de inicio)
    SELECT TOP 1
        DATEPART(HOUR, StartTime)   AS Hour,
        COUNT(*)                    AS BookingCount
    FROM Bookings
    WHERE Status    NOT IN ('Cancelled')
    AND   StartTime >= @FromDate
    AND   StartTime <= @ToDate
    GROUP BY DATEPART(HOUR, StartTime)
    ORDER BY BookingCount DESC;

    -- Ingresos totales
    SELECT
        ISNULL(SUM(FinalPrice), 0) AS TotalRevenue
    FROM Bookings
    WHERE Status    NOT IN ('Cancelled')
    AND   StartTime >= @FromDate
    AND   StartTime <= @ToDate;
END
GO

-- =============================================
-- CoWork Users Booking System
-- Procedures: Users
-- Author: Luis Guevara A.
-- Date: 09/06/2026
-- =============================================

USE CoWorkSpaces;
GO

-- =============================================
-- sp_GetUsers
-- =============================================
CREATE OR ALTER PROCEDURE sp_GetUsers
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id,
        Name,
        Email,
        CreatedAt,
        UpdatedAt
    FROM Users
    ORDER BY Name ASC;
END
GO

-- =============================================
-- CoWork Login Users Booking System
-- Procedures: Login
-- Author: Luis Guevara A.
-- Date: 09/06/2026
-- =============================================

USE CoWorkSpaces;
GO

-- =============================================
-- sp_Login
-- =============================================
CREATE OR ALTER PROCEDURE sp_Login
    @Email NVARCHAR(150)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Name, Email, PasswordHash
    FROM Users
    WHERE Email = @Email;
END
GO

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