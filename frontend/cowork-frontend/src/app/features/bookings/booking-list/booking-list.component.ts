import { Component, OnInit, ViewChild } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { CommonModule } from '@angular/common';
import { MatTableModule, MatTableDataSource } from '@angular/material/table';
import { MatButtonModule } from '@angular/material/button';
import { MatChipsModule } from '@angular/material/chips';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatDialogModule, MatDialog } from '@angular/material/dialog';
import { MatPaginator, MatPaginatorModule, PageEvent } from '@angular/material/paginator';
import { BookingService } from '../../../core/services/booking.service';
import { Booking } from '../../../core/models/booking.model';
import { MatCardModule } from '@angular/material/card';
import { MatDividerModule } from '@angular/material/divider';
import { Space } from '../../../core/models/space.model';
import { SpaceService } from '../../../core/services/space.service';
import { AuthService } from '../../../core/services/auth.service';

@Component({
  selector: 'app-booking-list',
  standalone: true,
  imports: [
    CommonModule,
    MatTableModule,
    MatButtonModule,
    MatChipsModule,
    /*     RouterLink, */
    MatIconModule,
    MatProgressSpinnerModule,
    MatDialogModule,
    MatPaginatorModule,
    MatCardModule,
    MatDividerModule
  ],
  templateUrl: 'booking-list.component.html',
  styleUrls: ['booking-list.component.scss']
})
export class BookingListComponent implements OnInit {

  bookings: Booking[] = [];
  dataSource = new MatTableDataSource<Booking>([]);
  columns = ['id', 'createdAt', 'space', 'user', 'date', 'startTime', 'endTime', 'finalPrice', 'status', 'actions'];
  loading = false;
  error = '';
  successMessage = '';
  spaces: Space[] = [];
  loadingSpaces = false;
  pageIndex = 0;
  pageSize = 10;

  private paginator?: MatPaginator;

  @ViewChild(MatPaginator)
  set matPaginator(paginator: MatPaginator | undefined) {
    this.paginator = paginator;
    if (paginator) {
      this.dataSource.paginator = paginator;
    }
  }

  constructor(
    private bookingService: BookingService,
    private spaceService: SpaceService,
    private dialog: MatDialog,
    private router: Router,
    public authService: AuthService
  ) { }

  ngOnInit(): void {
    this.loadSpaces();
    this.loadBookings();
  }

  loadBookings(): void {
    this.loading = true;
    this.error = '';
    this.bookingService.getAll().subscribe({
      next: bookings => {
        this.bookings = bookings;
        this.dataSource.data = bookings;
        this.pageIndex = 0;
        if (this.paginator) {
          this.dataSource.paginator = this.paginator;
          this.paginator.firstPage();
        }
        this.loading = false;
      },
      error: err => { this.error = err.message; this.loading = false; }
    });
  }

  loadSpaces(): void {
    this.loadingSpaces = true;
    this.spaceService.getAll('active').subscribe({
      next: spaces => { this.spaces = spaces; this.loadingSpaces = false; },
      error: () => { this.loadingSpaces = false; }
    });
  }

  bookSpace(space: Space): void {
    this.router.navigate(['/bookings/new'], {
      queryParams: { spaceId: space.id }
    });
  }

  getStatusClass(status: string): string {
    const map: Record<string, string> = {
      Confirmed: 'chip-confirmed',
      Pending: 'chip-pending',
      Cancelled: 'chip-cancelled',
      Completed: 'chip-completed'
    };
    return map[status] ?? '';
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

  cancelBooking(booking: Booking): void {
    const refundMsg = this.getRefundMessage(booking);
    if (!confirm(`¿Cancelar esta reserva?\n\n${refundMsg}`)) return;

    this.bookingService.cancel(booking.id).subscribe({
      next: result => {
        this.successMessage = `Reserva cancelada. ${result.refundDescription}`;
        this.loadBookings();
        setTimeout(() => this.successMessage = '', 5000);
      },
      error: err => this.error = err.message
    });
  }

  getRefundMessage(booking: Booking): string {
    const hoursUntil = (new Date(booking.startTime).getTime() - Date.now()) / 36e5;
    if (hoursUntil >= 48) return 'Recibirá un reembolso completo (100%).';
    if (hoursUntil >= 24) return 'Recibirá un reembolso parcial (50%).';
    return 'No se emitirá ningún reembolso (menos de 24h de aviso).';
  }

  onPageChange(event: PageEvent): void {
    this.pageIndex = event.pageIndex;
    this.pageSize = event.pageSize;
  }

  get pagedBookingsForMobile(): Booking[] {
    const start = this.pageIndex * this.pageSize;
    return this.dataSource.data.slice(start, start + this.pageSize);
  }
}