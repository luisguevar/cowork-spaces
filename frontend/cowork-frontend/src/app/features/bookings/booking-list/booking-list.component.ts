import { Component, OnInit, ViewChild } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { CommonModule } from '@angular/common';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { MatTableModule, MatTableDataSource } from '@angular/material/table';
import { MatButtonModule } from '@angular/material/button';
import { MatChipsModule } from '@angular/material/chips';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatDialogModule, MatDialog, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatPaginator, MatPaginatorModule, PageEvent } from '@angular/material/paginator';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatSelectModule } from '@angular/material/select';
import { BookingService } from '../../../core/services/booking.service';
import { Booking } from '../../../core/models/booking.model';
import { MatCardModule } from '@angular/material/card';
import { MatDividerModule } from '@angular/material/divider';
import { Space } from '../../../core/models/space.model';
import { SpaceService } from '../../../core/services/space.service';
import { AuthService } from '../../../core/services/auth.service';
import { inject } from '@angular/core';

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

  openManageDialog(booking: Booking): void {
    const dialogRef = this.dialog.open(BookingManageDialogComponent, {
      width: '560px',
      data: { booking }
    });

    dialogRef.afterClosed().subscribe(updated => {
      if (updated) this.loadBookings();
    });
  }


  /*   getStatusClass(status: string): string {
      const map: Record<string, string> = {
        Confirmed: 'chip-confirmed',
        Pending: 'chip-pending',
        Cancelled: 'chip-cancelled',
        Completed: 'chip-completed'
      };
      return map[status] ?? '';
    } */

  getStatusClass(status: string): string {
    const map: Record<string, string> = {
      Confirmed: 'dot confirmed',
      Pending: 'dot pending',
      Cancelled: 'dot cancelled',
      Completed: 'dot completed'
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

@Component({
  selector: 'app-booking-manage-dialog',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatDialogModule,
    MatFormFieldModule,
    MatSelectModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule
  ],
  template: `
    <h2 mat-dialog-title>Gestionar Reserva</h2>

    <mat-dialog-content>
      <div class="detail-row"><strong>Ambiente:</strong> {{ data.booking.spaceName }}</div>
      <div class="detail-row"><strong>Usuario:</strong> {{ data.booking.userName }}</div>
      <div class="detail-row"><strong>Fecha:</strong> {{ data.booking.startTime | date:'dd/MM/yyyy' }}</div>
      <div class="detail-row"><strong>Horario:</strong> {{ data.booking.startTime | date:'HH:mm' }} - {{ data.booking.endTime | date:'HH:mm' }}</div>
      <div class="detail-row"><strong>Estado actual:</strong>
        <span [class]="'status-' + data.booking.status.toLowerCase()">
          {{ getStatusName(data.booking.status) }}
        </span>
      </div>

      <mat-form-field appearance="outline" class="full-width">
        <mat-label>Nuevo estado</mat-label>
        <mat-select [formControl]="statusControl">
          <mat-option value="Pending">Pendiente</mat-option>
          <mat-option value="Confirmed">Confirmado</mat-option>
          <mat-option value="Completed">Completado</mat-option>
        </mat-select>
      </mat-form-field>

      <div *ngIf="error" class="error-message">{{ error }}</div>
    </mat-dialog-content>

    <mat-dialog-actions align="end">
      <button mat-button (click)="close()">Cerrar</button>
      <button mat-raised-button color="primary"
              [disabled]="loading || statusControl.value === data.booking.status"
              (click)="save()">
        <mat-spinner *ngIf="loading" diameter="20" />
        <span *ngIf="!loading">Guardar</span>
      </button>
    </mat-dialog-actions>
  `,
  styles: [`
    .detail-row { margin-bottom: 8px; }
    .full-width { width: 100%; margin-top: 16px; }
    .error-message { color: red; font-size: 0.85em; margin-top: 8px; }
    .status-confirmed { color: #2e7d32; font-weight: 500; }
    .status-pending   { color: #1565c0; font-weight: 500; }
    .status-cancelled { color: #c62828; font-weight: 500; }
    .status-completed { color: #6a1b9a; font-weight: 500; }
  `]
})
export class BookingManageDialogComponent {
  readonly data = inject(MAT_DIALOG_DATA) as { booking: Booking };
  private readonly dialogRef = inject(MatDialogRef<BookingManageDialogComponent>);
  private readonly bookingService = inject(BookingService);

  readonly statusControl = new FormControl<string>(this.data.booking.status);
  loading = false;
  error = '';

  save(): void {
    const newStatus = this.statusControl.value;
    if (!newStatus || newStatus === this.data.booking.status) return;

    this.loading = true;
    this.error = '';

    this.bookingService.updateStatus(this.data.booking.id, newStatus).subscribe({
      next: updated => {
        this.loading = false;
        this.dialogRef.close(updated);
      },
      error: err => {
        this.error = err.message;
        this.loading = false;
      }
    });
  }

  close(): void {
    this.dialogRef.close();
  }

  getStatusName(status: string): string {
    const map: Record<string, string> = {
      Confirmed: 'Confirmado',
      Pending: 'Pendiente',
      Cancelled: 'Cancelado',
      Completed: 'Completado'
    };
    return map[status] ?? status;
  }
}