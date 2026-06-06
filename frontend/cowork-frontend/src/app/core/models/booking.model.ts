export interface Booking {
  id: number;
  spaceId: number;
  spaceName: string;
  userId: number;
  userName: string;
  startTime: string;
  endTime: string;
  status: 'Pending' | 'Confirmed' | 'Cancelled' | 'Completed';
  finalPrice: number;
  refundAmount: number;
  createdAt: string;
  updatedAt: string;
}

export interface CreateBookingRequest {
  spaceId: number;
  userId: number;
  startTime: string;
  endTime: string;
}

export interface PricePreview {
  basePrice: number;
  peakHourAdjustment: number;
  weekendAdjustment: number;
  longBookingDiscount: number;
  earlyBookingDiscount: number;
  finalPrice: number;
}

export interface CancelBookingResponse {
  id: number;
  status: string;
  finalPrice: number;
  refundAmount: number;
  refundDescription: string;
}