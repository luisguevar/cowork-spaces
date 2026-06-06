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
        UpdatedAt   = GETUTCDATE()
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
        UpdatedAt   = GETUTCDATE()
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