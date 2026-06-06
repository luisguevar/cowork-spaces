-- =============================================
-- CoWork Spaces Booking System
-- Init: ejecutado automaticamente al arrancar
-- Author: Luis Guevara A.
-- Date: 09/06/2026
-- =============================================

-- Crear base de datos
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'CoWorkSpaces')
BEGIN
    CREATE DATABASE CoWorkSpaces;
END
GO

USE CoWorkSpaces;
GO

-- =============================================
-- Drop indexes
-- =============================================
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Bookings_SpaceId_StartTime_EndTime')
    DROP INDEX IX_Bookings_SpaceId_StartTime_EndTime ON Bookings;
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Bookings_Status')
    DROP INDEX IX_Bookings_Status ON Bookings;
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Spaces_Status')
    DROP INDEX IX_Spaces_Status ON Spaces;
GO

-- =============================================
-- Drop tables
-- =============================================
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Bookings')
    DROP TABLE Bookings;
GO
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Spaces')
    DROP TABLE Spaces;
GO
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Users')
    DROP TABLE Users;
GO

-- =============================================
-- Table: Users
-- =============================================
CREATE TABLE Users (
    Id          INT             NOT NULL IDENTITY(1,1),
    Name        NVARCHAR(100)   NOT NULL,
    Email       NVARCHAR(150)   NOT NULL,
    CreatedAt   DATETIME2       NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt   DATETIME2       NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_Users         PRIMARY KEY (Id),
    CONSTRAINT UQ_Users_Email   UNIQUE (Email)
);
GO

-- =============================================
-- Table: Spaces
-- =============================================
CREATE TABLE Spaces (
    Id              INT             NOT NULL IDENTITY(1,1),
    Name            NVARCHAR(100)   NOT NULL,
    Capacity        INT             NOT NULL,
    HourlyRate      DECIMAL(10,2)   NOT NULL,
    OpeningTime     TIME            NOT NULL,
    ClosingTime     TIME            NOT NULL,
    Status          NVARCHAR(20)    NOT NULL DEFAULT 'active',
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt       DATETIME2       NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_Spaces                PRIMARY KEY (Id),
    CONSTRAINT CK_Spaces_Status         CHECK (Status IN ('active', 'maintenance')),
    CONSTRAINT CK_Spaces_HourlyRate     CHECK (HourlyRate > 0),
    CONSTRAINT CK_Spaces_Capacity       CHECK (Capacity > 0),
    CONSTRAINT CK_Spaces_Schedule       CHECK (ClosingTime > OpeningTime)
);
GO

-- =============================================
-- Table: Bookings
-- =============================================
CREATE TABLE Bookings (
    Id              INT             NOT NULL IDENTITY(1,1),
    SpaceId         INT             NOT NULL,
    UserId          INT             NOT NULL,
    StartTime       DATETIME2       NOT NULL,
    EndTime         DATETIME2       NOT NULL,
    Status          NVARCHAR(20)    NOT NULL DEFAULT 'Pending',
    FinalPrice      DECIMAL(10,2)   NOT NULL,
    RefundAmount    DECIMAL(10,2)   NOT NULL DEFAULT 0,
    CreatedAt       DATETIME2       NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt       DATETIME2       NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT PK_Bookings              PRIMARY KEY (Id),
    CONSTRAINT FK_Bookings_SpaceId      FOREIGN KEY (SpaceId) REFERENCES Spaces(Id),
    CONSTRAINT FK_Bookings_UserId       FOREIGN KEY (UserId)  REFERENCES Users(Id),
    CONSTRAINT CK_Bookings_Status       CHECK (Status IN ('Pending', 'Confirmed', 'Cancelled', 'Completed')),
    CONSTRAINT CK_Bookings_TimeRange    CHECK (EndTime > StartTime),
    CONSTRAINT CK_Bookings_FinalPrice   CHECK (FinalPrice >= 0),
    CONSTRAINT CK_Bookings_RefundAmount CHECK (RefundAmount >= 0)
);
GO

-- =============================================
-- Indexes
-- =============================================
CREATE INDEX IX_Bookings_SpaceId_StartTime_EndTime
    ON Bookings (SpaceId, StartTime, EndTime);
GO
CREATE INDEX IX_Bookings_Status
    ON Bookings (Status);
GO
CREATE INDEX IX_Spaces_Status
    ON Spaces (Status);
GO

-- =============================================
-- Stored Procedures: Spaces
-- =============================================
CREATE OR ALTER PROCEDURE sp_GetSpaces
    @Status NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, Name, Capacity, HourlyRate, OpeningTime, ClosingTime, Status, CreatedAt, UpdatedAt
    FROM Spaces
    WHERE (@Status IS NULL OR Status = @Status)
    ORDER BY Name ASC;
END
GO

CREATE OR ALTER PROCEDURE sp_GetSpaceById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, Name, Capacity, HourlyRate, OpeningTime, ClosingTime, Status, CreatedAt, UpdatedAt
    FROM Spaces
    WHERE Id = @Id;
END
GO

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
    SELECT Id, Name, Capacity, HourlyRate, OpeningTime, ClosingTime, Status, CreatedAt, UpdatedAt
    FROM Spaces WHERE Id = SCOPE_IDENTITY();
END
GO

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
    SET Name = @Name, Capacity = @Capacity, HourlyRate = @HourlyRate,
        OpeningTime = @OpeningTime, ClosingTime = @ClosingTime,
        Status = @Status, UpdatedAt = GETUTCDATE()
    WHERE Id = @Id;
    SELECT Id, Name, Capacity, HourlyRate, OpeningTime, ClosingTime, Status, CreatedAt, UpdatedAt
    FROM Spaces WHERE Id = @Id;
END
GO

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
    UPDATE Spaces SET Status = 'maintenance', UpdatedAt = GETUTCDATE() WHERE Id = @Id;
    SELECT Id, Name, Capacity, HourlyRate, OpeningTime, ClosingTime, Status, CreatedAt, UpdatedAt
    FROM Spaces WHERE Id = @Id;
END
GO

-- =============================================
-- Stored Procedures: Bookings
-- =============================================
CREATE OR ALTER PROCEDURE sp_GetBookings
    @SpaceId    INT             = NULL,
    @UserId     INT             = NULL,
    @Status     NVARCHAR(20)    = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT b.Id, b.SpaceId, s.Name AS SpaceName, b.UserId, u.Name AS UserName,
           b.StartTime, b.EndTime, b.Status, b.FinalPrice, b.RefundAmount, b.CreatedAt, b.UpdatedAt
    FROM Bookings b
    INNER JOIN Spaces s ON s.Id = b.SpaceId
    INNER JOIN Users  u ON u.Id = b.UserId
    WHERE (@SpaceId IS NULL OR b.SpaceId = @SpaceId)
      AND (@UserId  IS NULL OR b.UserId  = @UserId)
      AND (@Status  IS NULL OR b.Status  = @Status)
    ORDER BY b.StartTime DESC;
END
GO

CREATE OR ALTER PROCEDURE sp_GetBookingById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT b.Id, b.SpaceId, s.Name AS SpaceName, b.UserId, u.Name AS UserName,
           b.StartTime, b.EndTime, b.Status, b.FinalPrice, b.RefundAmount, b.CreatedAt, b.UpdatedAt
    FROM Bookings b
    INNER JOIN Spaces s ON s.Id = b.SpaceId
    INNER JOIN Users  u ON u.Id = b.UserId
    WHERE b.Id = @Id;
END
GO

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
        SELECT Id FROM Spaces WITH (UPDLOCK, ROWLOCK) WHERE Id = @SpaceId;
        IF EXISTS (
            SELECT 1 FROM Bookings
            WHERE SpaceId = @SpaceId
              AND Status  NOT IN ('Cancelled')
              AND StartTime < @EndTime
              AND EndTime   > @StartTime
        )
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR('BOOKING_CONFLICT', 16, 1);
            RETURN;
        END
        INSERT INTO Bookings (SpaceId, UserId, StartTime, EndTime, Status, FinalPrice, RefundAmount)
        VALUES (@SpaceId, @UserId, @StartTime, @EndTime, 'Confirmed', @FinalPrice, 0);
        COMMIT TRANSACTION;
        SELECT b.Id, b.SpaceId, s.Name AS SpaceName, b.UserId, u.Name AS UserName,
               b.StartTime, b.EndTime, b.Status, b.FinalPrice, b.RefundAmount, b.CreatedAt, b.UpdatedAt
        FROM Bookings b
        INNER JOIN Spaces s ON s.Id = b.SpaceId
        INNER JOIN Users  u ON u.Id = b.UserId
        WHERE b.Id = SCOPE_IDENTITY();
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE sp_CancelBooking
    @Id             INT,
    @RefundAmount   DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Bookings WHERE Id = @Id)
    BEGIN RAISERROR('BOOKING_NOT_FOUND', 16, 1); RETURN; END
    IF EXISTS (SELECT 1 FROM Bookings WHERE Id = @Id AND Status = 'Completed')
    BEGIN RAISERROR('BOOKING_ALREADY_COMPLETED', 16, 1); RETURN; END
    IF EXISTS (SELECT 1 FROM Bookings WHERE Id = @Id AND Status = 'Cancelled')
    BEGIN RAISERROR('BOOKING_ALREADY_CANCELLED', 16, 1); RETURN; END
    UPDATE Bookings SET Status = 'Cancelled', RefundAmount = @RefundAmount, UpdatedAt = GETUTCDATE()
    WHERE Id = @Id;
    SELECT b.Id, b.SpaceId, s.Name AS SpaceName, b.UserId, u.Name AS UserName,
           b.StartTime, b.EndTime, b.Status, b.FinalPrice, b.RefundAmount, b.CreatedAt, b.UpdatedAt
    FROM Bookings b
    INNER JOIN Spaces s ON s.Id = b.SpaceId
    INNER JOIN Users  u ON u.Id = b.UserId
    WHERE b.Id = @Id;
END
GO

-- =============================================
-- Stored Procedures: Reports
-- =============================================
CREATE OR ALTER PROCEDURE sp_GetReports
    @FromDate   DATETIME2,
    @ToDate     DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TotalHours DECIMAL(10,2);
    SET @TotalHours = DATEDIFF(HOUR, @FromDate, @ToDate);
    SELECT s.Id AS SpaceId, s.Name AS SpaceName, s.HourlyRate,
           COUNT(b.Id) AS TotalBookings,
           ISNULL(SUM(DATEDIFF(MINUTE, b.StartTime, b.EndTime)) / 60.0, 0) AS BookedHours,
           CASE WHEN @TotalHours > 0
                THEN ROUND(ISNULL(SUM(DATEDIFF(MINUTE, b.StartTime, b.EndTime)) / 60.0, 0) / @TotalHours * 100, 2)
                ELSE 0 END AS OccupancyRate,
           ISNULL(SUM(b.FinalPrice), 0) AS TotalRevenue
    FROM Spaces s
    LEFT JOIN Bookings b ON b.SpaceId = s.Id
        AND b.Status NOT IN ('Cancelled')
        AND b.StartTime >= @FromDate
        AND b.EndTime   <= @ToDate
    GROUP BY s.Id, s.Name, s.HourlyRate
    ORDER BY TotalRevenue DESC;

    SELECT TOP 1 DATEPART(HOUR, StartTime) AS PeakHour, COUNT(*) AS BookingCount
    FROM Bookings
    WHERE Status NOT IN ('Cancelled')
      AND StartTime >= @FromDate
      AND StartTime <= @ToDate
    GROUP BY DATEPART(HOUR, StartTime)
    ORDER BY BookingCount DESC;

    SELECT ISNULL(SUM(FinalPrice), 0) AS TotalRevenue
    FROM Bookings
    WHERE Status NOT IN ('Cancelled')
      AND StartTime >= @FromDate
      AND StartTime <= @ToDate;
END
GO

-- =============================================
-- Stored Procedures: Users
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
-- Seed
-- =============================================
DELETE FROM Bookings;
DELETE FROM Spaces;
DELETE FROM Users;

DBCC CHECKIDENT ('Bookings', RESEED, 1);
DBCC CHECKIDENT ('Spaces',   RESEED, 1);
DBCC CHECKIDENT ('Users',    RESEED, 1);
GO

INSERT INTO Users (Name, Email) VALUES
('John Smith',    'john.smith@email.com'),
('Maria Garcia',  'maria.garcia@email.com'),
('Carlos Lopez',  'carlos.lopez@email.com'),
('Ana Martinez',  'ana.martinez@email.com'),
('Peter Johnson', 'peter.johnson@email.com');
GO

INSERT INTO Spaces (Name, Capacity, HourlyRate, OpeningTime, ClosingTime, Status) VALUES
('Board Room A',        10,     80.00,  '08:00', '20:00', 'active'),
('Meeting Room B',      6,      50.00,  '08:00', '18:00', 'active'),
('Creative Studio',     8,      65.00,  '09:00', '21:00', 'active'),
('Focus Room 1',        2,      30.00,  '07:00', '22:00', 'active'),
('Conference Hall',     30,     150.00, '08:00', '20:00', 'maintenance');
GO


-- =============================================
-- Seed Bookings
-- =============================================
DECLARE @U1 INT = (SELECT Id FROM Users WHERE Email = 'john.smith@email.com');
DECLARE @U2 INT = (SELECT Id FROM Users WHERE Email = 'maria.garcia@email.com');
DECLARE @U3 INT = (SELECT Id FROM Users WHERE Email = 'carlos.lopez@email.com');
DECLARE @U4 INT = (SELECT Id FROM Users WHERE Email = 'ana.martinez@email.com');
DECLARE @U5 INT = (SELECT Id FROM Users WHERE Email = 'peter.johnson@email.com');

DECLARE @S1 INT = (SELECT Id FROM Spaces WHERE Name = 'Board Room A');
DECLARE @S2 INT = (SELECT Id FROM Spaces WHERE Name = 'Meeting Room B');
DECLARE @S3 INT = (SELECT Id FROM Spaces WHERE Name = 'Creative Studio');
DECLARE @S4 INT = (SELECT Id FROM Spaces WHERE Name = 'Focus Room 1');

INSERT INTO Bookings (SpaceId, UserId, StartTime, EndTime, Status, FinalPrice, RefundAmount) VALUES
(@S1, @U1, DATEADD(HOUR, 9,  DATEADD(DAY, 1,  CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
           DATEADD(HOUR, 11, DATEADD(DAY, 1,  CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))), 'Confirmed', 200.00, 0),
(@S2, @U2, DATEADD(HOUR, 10, DATEADD(DAY, 3,  CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
           DATEADD(HOUR, 14, DATEADD(DAY, 3,  CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))), 'Confirmed', 230.00, 0),
(@S3, @U3, DATEADD(HOUR, 14, DATEADD(DAY, 10, CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
           DATEADD(HOUR, 18, DATEADD(DAY, 10, CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))), 'Pending',   222.00, 0),
(@S4, @U4, DATEADD(HOUR, 8,  DATEADD(DAY, 5,  CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
           DATEADD(HOUR, 10, DATEADD(DAY, 5,  CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))), 'Cancelled',  60.00, 60.00),
(@S1, @U5, DATEADD(HOUR, 9,  DATEADD(DAY, -2, CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
           DATEADD(HOUR, 13, DATEADD(DAY, -2, CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))), 'Completed', 360.00, 0),
(@S1, @U2, DATEADD(HOUR, 11, DATEADD(DAY, 1,  CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
           DATEADD(HOUR, 13, DATEADD(DAY, 1,  CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))), 'Confirmed', 160.00, 0),
(@S2, @U1, DATEADD(HOUR, 15, DATEADD(DAY, 2,  CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
           DATEADD(HOUR, 17, DATEADD(DAY, 2,  CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))), 'Cancelled', 100.00, 50.00);
GO