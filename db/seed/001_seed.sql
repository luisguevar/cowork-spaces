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
DBCC CHECKIDENT ('Bookings', RESEED, 0);
DBCC CHECKIDENT ('Spaces',   RESEED, 0);
DBCC CHECKIDENT ('Users',    RESEED, 0);
GO

-- =============================================
-- Users
-- =============================================
INSERT INTO Users (Name, Email, PasswordHash) VALUES
('John Smith',      'john.smith@email.com' , '$2a$11$msOTeYBOpJ2EtaRQ76tQA.YsEdpGk8zlpe84Q/0QqdLIqdArVYMru'),
('Maria Garcia',    'maria.garcia@email.com', '$2a$11$msOTeYBOpJ2EtaRQ76tQA.YsEdpGk8zlpe84Q/0QqdLIqdArVYMru'),
('Carlos Lopez',    'carlos.lopez@email.com', '$2a$11$msOTeYBOpJ2EtaRQ76tQA.YsEdpGk8zlpe84Q/0QqdLIqdArVYMru'),
('Ana Martinez',    'ana.martinez@email.com', '$2a$11$msOTeYBOpJ2EtaRQ76tQA.YsEdpGk8zlpe84Q/0QqdLIqdArVYMru'),
('Peter Johnson',   'peter.johnson@email.com', '$2a$11$msOTeYBOpJ2EtaRQ76tQA.YsEdpGk8zlpe84Q/0QqdLIqdArVYMru');
GO

-- =============================================
-- Spaces
-- =============================================
INSERT INTO Spaces (Name, Capacity, HourlyRate, OpeningTime, ClosingTime, Status) VALUES
('Sala Reunión A',        10,     80.00,  '08:00', '20:00', 'active'),
('Sala Reunión B',      6,      50.00,  '08:00', '18:00', 'active'),
('Centro Creativo A',     8,      65.00,  '09:00', '21:00', 'active'),
('Centro Creativo B',        2,      30.00,  '07:00', '22:00', 'active'),
('Auditorio General',     30,     150.00, '08:00', '20:00', 'maintenance');
GO

-- =============================================
-- Bookings
-- =============================================

-- Reserva confirmada normal (Board Room A - John Smith)
INSERT INTO Bookings (SpaceId, UserId, StartTime, EndTime, Status, FinalPrice, RefundAmount)
VALUES (1, 1,
    DATEADD(HOUR, 9,  DATEADD(DAY, 1, CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
    DATEADD(HOUR, 11, DATEADD(DAY, 1, CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
    'Confirmed', 200.00, 0);

-- Reserva confirmada fin de semana (Meeting Room B - Maria Garcia)
INSERT INTO Bookings (SpaceId, UserId, StartTime, EndTime, Status, FinalPrice, RefundAmount)
VALUES (2, 2,
    DATEADD(HOUR, 10, DATEADD(DAY, 3, CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
    DATEADD(HOUR, 14, DATEADD(DAY, 3, CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
    'Confirmed', 230.00, 0);

-- Reserva pendiente con anticipacion (Creative Studio - Carlos Lopez)
INSERT INTO Bookings (SpaceId, UserId, StartTime, EndTime, Status, FinalPrice, RefundAmount)
VALUES (3, 3,
    DATEADD(HOUR, 14, DATEADD(DAY, 10, CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
    DATEADD(HOUR, 18, DATEADD(DAY, 10, CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
    'Pending', 222.00, 0);

-- Reserva cancelada con reembolso 100% (Focus Room 1 - Ana Martinez)
INSERT INTO Bookings (SpaceId, UserId, StartTime, EndTime, Status, FinalPrice, RefundAmount)
VALUES (4, 4,
    DATEADD(HOUR, 8,  DATEADD(DAY, 5, CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
    DATEADD(HOUR, 10, DATEADD(DAY, 5, CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
    'Cancelled', 60.00, 60.00);

-- Reserva completada (Board Room A - Peter Johnson)
INSERT INTO Bookings (SpaceId, UserId, StartTime, EndTime, Status, FinalPrice, RefundAmount)
VALUES (1, 5,
    DATEADD(HOUR, 9,  DATEADD(DAY, -2, CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
    DATEADD(HOUR, 13, DATEADD(DAY, -2, CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
    'Completed', 360.00, 0);

-- Reserva confirmada contigua (justo despues de la primera - edge case)
INSERT INTO Bookings (SpaceId, UserId, StartTime, EndTime, Status, FinalPrice, RefundAmount)
VALUES (1, 2,
    DATEADD(HOUR, 11, DATEADD(DAY, 1, CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
    DATEADD(HOUR, 13, DATEADD(DAY, 1, CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
    'Confirmed', 160.00, 0);

-- Reserva cancelada con reembolso 50% (Meeting Room B - John Smith)
INSERT INTO Bookings (SpaceId, UserId, StartTime, EndTime, Status, FinalPrice, RefundAmount)
VALUES (2, 1,
    DATEADD(HOUR, 15, DATEADD(DAY, 2, CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
    DATEADD(HOUR, 17, DATEADD(DAY, 2, CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME2))),
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