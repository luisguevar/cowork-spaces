-- =============================================
-- CoWork Spaces Booking System
-- Seed: datos iniciales
-- Author: Luis Guevara A.
-- Date: 09/06/2026
-- =============================================

USE CoWorkSpaces;
GO

-- =============================================
-- Limpiar datos en orden por FK
-- =============================================
DELETE FROM Bookings;
DELETE FROM Spaces;
DELETE FROM Users;

-- Reiniciar identidades
DBCC CHECKIDENT ('Bookings', RESEED, 1);
DBCC CHECKIDENT ('Spaces',   RESEED, 1);
DBCC CHECKIDENT ('Users',    RESEED, 1);
GO

-- =============================================
-- Users
-- =============================================
INSERT INTO Users (Name, Email, PasswordHash) VALUES
('John Smith',    'john.smith@email.com',    '$2a$11$msOTeYBOpJ2EtaRQ76tQA.YsEdpGk8zlpe84Q/0QqdLIqdArVYMru'),
('Maria Garcia',  'maria.garcia@email.com',  '$2a$11$msOTeYBOpJ2EtaRQ76tQA.YsEdpGk8zlpe84Q/0QqdLIqdArVYMru'),
('Carlos Lopez',  'carlos.lopez@email.com',  '$2a$11$msOTeYBOpJ2EtaRQ76tQA.YsEdpGk8zlpe84Q/0QqdLIqdArVYMru'),
('Ana Martinez',  'ana.martinez@email.com',  '$2a$11$msOTeYBOpJ2EtaRQ76tQA.YsEdpGk8zlpe84Q/0QqdLIqdArVYMru'),
('Peter Johnson', 'peter.johnson@email.com', '$2a$11$msOTeYBOpJ2EtaRQ76tQA.YsEdpGk8zlpe84Q/0QqdLIqdArVYMru');
GO

-- =============================================
-- Spaces
-- =============================================
INSERT INTO Spaces (Name, Capacity, HourlyRate, OpeningTime, ClosingTime, Status) VALUES
('Sala Reunión A',    10,  80.00,  '08:00', '20:00', 'active'),
('Sala Reunión B',     6,  50.00,  '08:00', '18:00', 'active'),
('Centro Creativo A',  8,  65.00,  '09:00', '21:00', 'active'),
('Centro Creativo B',  2,  30.00,  '07:00', '22:00', 'active'),
('Auditorio General', 30, 150.00,  '08:00', '20:00', 'maintenance');
GO

-- =============================================
-- Bookings
-- =============================================
DECLARE @U1 INT = (SELECT Id FROM Users WHERE Email = 'john.smith@email.com');
DECLARE @U2 INT = (SELECT Id FROM Users WHERE Email = 'maria.garcia@email.com');
DECLARE @U3 INT = (SELECT Id FROM Users WHERE Email = 'carlos.lopez@email.com');
DECLARE @U4 INT = (SELECT Id FROM Users WHERE Email = 'ana.martinez@email.com');
DECLARE @U5 INT = (SELECT Id FROM Users WHERE Email = 'peter.johnson@email.com');

DECLARE @S1 INT = (SELECT Id FROM Spaces WHERE Name = 'Sala Reunión A');
DECLARE @S2 INT = (SELECT Id FROM Spaces WHERE Name = 'Sala Reunión B');
DECLARE @S3 INT = (SELECT Id FROM Spaces WHERE Name = 'Centro Creativo A');
DECLARE @S4 INT = (SELECT Id FROM Spaces WHERE Name = 'Centro Creativo B');

-- Reserva confirmada normal
INSERT INTO Bookings (SpaceId, UserId, StartTime, EndTime, Status, FinalPrice, RefundAmount)
VALUES (@S1, @U1,
    DATEADD(HOUR, 9,  DATEADD(DAY, 1,  CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
    DATEADD(HOUR, 11, DATEADD(DAY, 1,  CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
    'Confirmed', 200.00, 0);

-- Reserva confirmada fin de semana
INSERT INTO Bookings (SpaceId, UserId, StartTime, EndTime, Status, FinalPrice, RefundAmount)
VALUES (@S2, @U2,
    DATEADD(HOUR, 10, DATEADD(DAY, 3,  CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
    DATEADD(HOUR, 14, DATEADD(DAY, 3,  CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
    'Confirmed', 230.00, 0);

-- Reserva pendiente con anticipacion
INSERT INTO Bookings (SpaceId, UserId, StartTime, EndTime, Status, FinalPrice, RefundAmount)
VALUES (@S3, @U3,
    DATEADD(HOUR, 14, DATEADD(DAY, 10, CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
    DATEADD(HOUR, 18, DATEADD(DAY, 10, CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
    'Pending', 222.00, 0);

-- Reserva cancelada con reembolso 100%
INSERT INTO Bookings (SpaceId, UserId, StartTime, EndTime, Status, FinalPrice, RefundAmount)
VALUES (@S4, @U4,
    DATEADD(HOUR, 8,  DATEADD(DAY, 5,  CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
    DATEADD(HOUR, 10, DATEADD(DAY, 5,  CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
    'Cancelled', 60.00, 60.00);

-- Reserva completada
INSERT INTO Bookings (SpaceId, UserId, StartTime, EndTime, Status, FinalPrice, RefundAmount)
VALUES (@S1, @U5,
    DATEADD(HOUR, 9,  DATEADD(DAY, -2, CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
    DATEADD(HOUR, 13, DATEADD(DAY, -2, CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
    'Completed', 360.00, 0);

-- Reserva confirmada contigua (edge case)
INSERT INTO Bookings (SpaceId, UserId, StartTime, EndTime, Status, FinalPrice, RefundAmount)
VALUES (@S1, @U2,
    DATEADD(HOUR, 11, DATEADD(DAY, 1,  CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
    DATEADD(HOUR, 13, DATEADD(DAY, 1,  CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
    'Confirmed', 160.00, 0);

-- Reserva cancelada con reembolso 50%
INSERT INTO Bookings (SpaceId, UserId, StartTime, EndTime, Status, FinalPrice, RefundAmount)
VALUES (@S2, @U1,
    DATEADD(HOUR, 15, DATEADD(DAY, 2,  CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
    DATEADD(HOUR, 17, DATEADD(DAY, 2,  CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
    'Cancelled', 100.00, 50.00);
GO

-- =============================================
-- Verificacion
-- =============================================
SELECT 'Users'    AS [Table], COUNT(*) AS [Records] FROM Users
UNION ALL
SELECT 'Spaces'   AS [Table], COUNT(*) AS [Records] FROM Spaces
UNION ALL
SELECT 'Bookings' AS [Table], COUNT(*) AS [Records] FROM Bookings;
GO