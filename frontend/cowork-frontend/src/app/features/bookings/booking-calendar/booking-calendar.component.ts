import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { FullCalendarModule } from '@fullcalendar/angular';
import { CalendarOptions, EventInput } from '@fullcalendar/core';
import dayGridPlugin from '@fullcalendar/daygrid';
import timeGridPlugin from '@fullcalendar/timegrid';
import interactionPlugin from '@fullcalendar/interaction';
import { MatCardModule } from '@angular/material/card';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatChipsModule } from '@angular/material/chips';
import { BookingService } from '../../../core/services/booking.service';
import { Booking } from '../../../core/models/booking.model';
import esLocale from '@fullcalendar/core/locales/es';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
@Component({
  selector: 'app-booking-calendar',
  standalone: true,
  imports: [
    CommonModule,
    RouterLink,
    FullCalendarModule,
    MatCardModule,
    MatProgressSpinnerModule,
    MatChipsModule,
    MatIconModule,
    MatButtonModule,
  ],
  templateUrl: './booking-calendar.component.html',
  styleUrls: ['./booking-calendar.component.scss']
})
export class BookingCalendarComponent implements OnInit {
  calendarOptions: CalendarOptions = {
    plugins: [dayGridPlugin, timeGridPlugin, interactionPlugin],
    initialView: 'dayGridMonth',
    locale: esLocale,
    headerToolbar: {
      left: 'prev,next today',
      center: 'title',
      right: 'dayGridMonth,timeGridWeek,timeGridDay'
    },
    events: [],
    eventClick: this.onEventClick.bind(this),
    height: 'auto'
  };

  bookings: Booking[] = [];
  selectedBooking: Booking | null = null;
  loading = false;
  error = '';

  constructor(private bookingService: BookingService) { }

  ngOnInit(): void {
    this.loadBookings();
  }

  loadBookings(): void {
    this.loading = true;
    this.error = '';

    this.bookingService.getAll().subscribe({
      next: bookings => {
        this.bookings = bookings;
        this.calendarOptions = {
          ...this.calendarOptions,
          events: bookings.map(b => this.mapToEvent(b))
        };
        this.loading = false;
      },
      error: err => {
        this.error = err.message;
        this.loading = false;
      }
    });
  }

  mapToEvent(booking: Booking): EventInput {
    const colorMap: Record<string, string> = {
      Confirmed: '#2e7d32',
      Pending: '#1565c0',
      Cancelled: '#c62828',
      Completed: '#6a1b9a'
    };

    return {
      id: booking.id.toString(),
      title: `${booking.spaceName} — ${booking.userName}`,
      start: booking.startTime,
      end: booking.endTime,
      color: colorMap[booking.status] ?? '#888',
      extendedProps: { bookingId: booking.id }
    };
  }

  onEventClick(info: any): void {
    const bookingId = info.event.extendedProps['bookingId'];
    this.selectedBooking = this.bookings.find(b => b.id === bookingId) ?? null;
  }

  getStatusName(status: string): string {
    const map: Record<string, string> = {
      Confirmed: 'Confirmado',
      Pending: 'Pendiente',
      Cancelled: 'Cancelado',
      Completed: 'Completado'
    };
    return map[status] ?? '';
  }
}