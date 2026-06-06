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