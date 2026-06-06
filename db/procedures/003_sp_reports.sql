-- =============================================
-- CoWork Spaces Booking System
-- Procedures: Reports
-- Author: Luis Guevara A.
-- Date: 09/06/2026
-- =============================================

USE CoWorkSpaces;
GO

-- =============================================
-- sp_GetReports
-- =============================================
CREATE OR ALTER PROCEDURE sp_GetReports
    @FromDate   DATETIME2,
    @ToDate     DATETIME2
AS
BEGIN
    SET NOCOUNT ON;

    -- Calcular horas disponibles en el rango para cada espacio
    DECLARE @TotalHours DECIMAL(10,2);
    SET @TotalHours = DATEDIFF(HOUR, @FromDate, @ToDate);

    -- Ocupacion e ingresos por espacio
    SELECT
        s.Id                                                AS SpaceId,
        s.Name                                              AS SpaceName,
        s.HourlyRate,
        COUNT(b.Id)                                         AS TotalBookings,
        ISNULL(SUM(DATEDIFF(MINUTE, b.StartTime, b.EndTime)) / 60.0, 0)
                                                            AS BookedHours,
        CASE
            WHEN @TotalHours > 0
            THEN ROUND(
                ISNULL(SUM(DATEDIFF(MINUTE, b.StartTime, b.EndTime)) / 60.0, 0)
                / @TotalHours * 100, 2)
            ELSE 0
        END                                                 AS OccupancyRate,
        ISNULL(SUM(b.FinalPrice), 0)                        AS TotalRevenue
    FROM Spaces s
    LEFT JOIN Bookings b ON b.SpaceId = s.Id
        AND b.Status    NOT IN ('Cancelled')
        AND b.StartTime >= @FromDate
        AND b.EndTime   <= @ToDate
    GROUP BY s.Id, s.Name, s.HourlyRate
    ORDER BY TotalRevenue DESC;

    -- Horario mas demandado (por hora de inicio)
    SELECT TOP 1
        DATEPART(HOUR, StartTime)   AS PeakHour,
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