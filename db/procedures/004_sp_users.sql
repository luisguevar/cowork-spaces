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