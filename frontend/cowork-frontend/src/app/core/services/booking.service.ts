import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import {
  Booking,
  CreateBookingRequest,
  PricePreview,
  CancelBookingResponse
} from '../models/booking.model';

@Injectable({
  providedIn: 'root'
})
export class BookingService {
  private readonly apiUrl = 'http://localhost:5209/api/bookings';

  constructor(private http: HttpClient) {}

  getAll(spaceId?: number, userId?: number, status?: string): Observable<Booking[]> {
    let params = new HttpParams();
    if (spaceId) params = params.set('spaceId', spaceId);
    if (userId)  params = params.set('userId',  userId);
    if (status)  params = params.set('status',  status);
    return this.http.get<Booking[]>(this.apiUrl, { params });
  }

  getById(id: number): Observable<Booking> {
    return this.http.get<Booking>(`${this.apiUrl}/${id}`);
  }

  create(request: CreateBookingRequest): Observable<Booking> {
    return this.http.post<Booking>(this.apiUrl, request);
  }

  getPricePreview(request: CreateBookingRequest): Observable<PricePreview> {
    let params = new HttpParams()
      .set('spaceId',   request.spaceId)
      .set('userId',    request.userId)
      .set('startTime', request.startTime)
      .set('endTime',   request.endTime);
    return this.http.get<PricePreview>(`${this.apiUrl}/price-preview`, { params });
  }

  cancel(id: number): Observable<CancelBookingResponse> {
    return this.http.patch<CancelBookingResponse>(`${this.apiUrl}/${id}/cancel`, {});
  }
}