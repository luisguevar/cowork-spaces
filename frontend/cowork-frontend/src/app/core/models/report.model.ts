export interface SpaceOccupancy {
  spaceId: number;
  spaceName: string;
  hourlyRate: number;
  totalBookings: number;
  bookedHours: number;
  occupancyRate: number;
  totalRevenue: number;
}

export interface PeakHour {
  hour: number;
  bookingCount: number;
}

export interface ReportResult {
  spaceOccupancies: SpaceOccupancy[];
  peakHour: PeakHour;
  totalRevenue: number;
}