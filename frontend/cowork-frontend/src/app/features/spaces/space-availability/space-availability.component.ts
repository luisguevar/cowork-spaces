import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { FullCalendarModule } from '@fullcalendar/angular';
import { CalendarOptions, EventInput } from '@fullcalendar/core';
import timeGridPlugin from '@fullcalendar/timegrid';
import interactionPlugin from '@fullcalendar/interaction';
import esLocale from '@fullcalendar/core/locales/es';
import { MatCardModule } from '@angular/material/card';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatChipsModule } from '@angular/material/chips';
import { SpaceService } from '../../../core/services/space.service';
import { BookingService } from '../../../core/services/booking.service';
import { Space } from '../../../core/models/space.model';
import { Booking } from '../../../core/models/booking.model';

@Component({
  selector: 'app-space-availability',
  standalone: true,
  imports: [
    CommonModule,
    RouterLink,
    FullCalendarModule,
    MatCardModule,
    MatProgressSpinnerModule,
    MatButtonModule,
    MatIconModule,
    MatChipsModule
  ],
  template: `
    <div class="availability-container">

      <!-- Header -->
      <div class="header">
        <button mat-icon-button routerLink="/spaces">
          <mat-icon>arrow_back</mat-icon>
        </button>
        <div class="header-info" *ngIf="space">
          <h2>{{ space.name }}</h2>
          <span class="space-meta">
            <mat-icon>people</mat-icon> {{ space.capacity }} personas &nbsp;|&nbsp;
            <mat-icon>schedule</mat-icon> {{ space.openingTime }} - {{ space.closingTime }} &nbsp;|&nbsp;
            <mat-icon>attach_money</mat-icon> {{ space.hourlyRate | currency }}/hr
          </span>
        </div>
        <a mat-raised-button color="primary"
           [routerLink]="['/bookings/new']"
           [queryParams]="{ spaceId: spaceId }">
          <mat-icon>add</mat-icon> Reservar
        </a>
      </div>

      <!-- Leyenda -->
      <div class="legend">
        <span class="legend-item">
          <span class="dot confirmed"></span> Confirmada
        </span>
        <span class="legend-item">
          <span class="dot pending"></span> Pendiente
        </span>
        <span class="legend-item">
          <span class="dot completed"></span> Completada
        </span>
        <span class="legend-item">
          <span class="dot available"></span> Disponible
        </span>
      </div>

      <div *ngIf="loading" class="loading">
        <mat-spinner diameter="40" />
      </div>

      <div *ngIf="error" class="error-message">{{ error }}</div>

      <!-- Detalle de reserva seleccionada -->
      <mat-card *ngIf="selectedBooking" class="booking-detail">
        <mat-card-content>
          <div class="detail-header">
            <strong>Detalle de reserva</strong>
            <button mat-icon-button (click)="selectedBooking = null">
              <mat-icon>close</mat-icon>
            </button>
          </div>
          <div class="detail-row">
            <mat-icon>person</mat-icon>
            <span>{{ selectedBooking.userName }}</span>
          </div>
          <div class="detail-row">
            <mat-icon>schedule</mat-icon>
            <span>{{ selectedBooking.startTime | date:'short' }} — {{ selectedBooking.endTime | date:'shortTime' }}</span>
          </div>
          <div class="detail-row">
            <mat-icon>attach_money</mat-icon>
            <span>{{ selectedBooking.finalPrice | currency }}</span>
          </div>
          <div class="detail-row">
            <mat-icon>info</mat-icon>
            <span [class]="'status-' + selectedBooking.status.toLowerCase()">
              {{ selectedBooking.status }}
            </span>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Calendario -->
      <full-calendar
        *ngIf="!loading"
        [options]="calendarOptions">
      </full-calendar>

    </div>
  `,
  styles: [`
    .availability-container { max-width: 1100px; margin: 0 auto; }
    .header { display: flex; align-items: center; gap: 16px; margin-bottom: 16px; }
    .header-info { flex: 1; }
    .header-info h2 { margin: 0; }
    .space-meta { font-size: 0.85em; color: #666; display: flex; align-items: center; gap: 4px; }
    .space-meta mat-icon { font-size: 16px; height: 16px; width: 16px; }
    .legend { display: flex; gap: 16px; margin-bottom: 16px; flex-wrap: wrap; }
    .legend-item { display: flex; align-items: center; gap: 6px; font-size: 0.85em; }
    .dot { width: 12px; height: 12px; border-radius: 50%; display: inline-block; }
    .dot.confirmed  { background: #2e7d32; }
    .dot.pending    { background: #1565c0; }
    .dot.completed  { background: #6a1b9a; }
    .dot.available  { background: #e0e0e0; border: 1px solid #bdbdbd; }
    .loading { display: flex; justify-content: center; padding: 40px; }
    .error-message { color: red; padding: 16px; }
    .booking-detail { margin-bottom: 16px; }
    .detail-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
    .detail-row { display: flex; align-items: center; gap: 8px; padding: 4px 0; }
    .detail-row mat-icon { font-size: 18px; height: 18px; width: 18px; color: #666; }
    .status-confirmed { color: #2e7d32; font-weight: 500; }
    .status-pending   { color: #1565c0; font-weight: 500; }
    .status-cancelled { color: #c62828; font-weight: 500; }
    .status-completed { color: #6a1b9a; font-weight: 500; }
  `]
})
export class SpaceAvailabilityComponent implements OnInit {
  spaceId!: number;
  space: Space | null = null;
  bookings: Booking[] = [];
  selectedBooking: Booking | null = null;
  loading = false;
  error = '';

  calendarOptions: CalendarOptions = {
    plugins: [timeGridPlugin, interactionPlugin],
    initialView: 'timeGridWeek',
    locale: esLocale,
    headerToolbar: {
      left: 'prev,next today',
      center: 'title',
      right: 'timeGridWeek,timeGridDay'
    },
    slotMinTime: '07:00:00',
    slotMaxTime: '22:00:00',
    slotDuration: '00:30:00',
    allDaySlot: false,
    events: [],
    eventClick: this.onEventClick.bind(this),
    height: 'auto'
  };

  constructor(
    private route: ActivatedRoute,
    private spaceService: SpaceService,
    private bookingService: BookingService
  ) { }

  ngOnInit(): void {
    this.spaceId = +this.route.snapshot.paramMap.get('id')!;
    this.loadData();
  }

  loadData(): void {
    this.loading = true;
    this.error = '';

    // Cargar espacio
    this.spaceService.getById(this.spaceId).subscribe({
      next: space => {
        this.space = space;
        this.calendarOptions = {
          ...this.calendarOptions,
          slotMinTime: space.openingTime,
          slotMaxTime: space.closingTime
        };
      },
      error: err => this.error = err.message
    });

    // Cargar reservas del espacio
    this.bookingService.getAll(this.spaceId).subscribe({
      next: bookings => {
        this.bookings = bookings.filter(b => b.status !== 'Cancelled');
        this.calendarOptions = {
          ...this.calendarOptions,
          events: this.bookings.map(b => this.mapToEvent(b))
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
      Completed: '#6a1b9a'
    };

    return {
      id: booking.id.toString(),
      title: booking.userName,
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
}