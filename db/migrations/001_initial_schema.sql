-- =============================================
-- CoWork Spaces Booking System
-- Migration: 001_initial_schema
-- Author: Luis Guevara A.
-- Date: 09/06/2026
-- =============================================
USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'CoWorkSpaces')
BEGIN
    CREATE DATABASE CoWorkSpaces;
END
GO

USE CoWorkSpaces;
GO

-- =============================================
-- Drop indexes (deben eliminarse antes que las tablas)
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
-- Drop tables (en orden inverso por FK)
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

-- Cubre la query de solapamiento en sp_CreateBooking
CREATE INDEX IX_Bookings_SpaceId_StartTime_EndTime
    ON Bookings (SpaceId, StartTime, EndTime);
GO

-- Acelera filtros de reportes que excluyen reservas canceladas
CREATE INDEX IX_Bookings_Status
    ON Bookings (Status);
GO

-- Filtra espacios activos en listados de disponibilidad
CREATE INDEX IX_Spaces_Status
    ON Spaces (Status);
GO