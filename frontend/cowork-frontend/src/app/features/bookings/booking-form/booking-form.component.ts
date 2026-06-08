import { Component, inject, OnInit } from '@angular/core';
import { Router, ActivatedRoute } from '@angular/router';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators, AbstractControl, ValidationErrors } from '@angular/forms';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatCardModule } from '@angular/material/card';
import { MatDividerModule } from '@angular/material/divider';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { debounceTime, distinctUntilChanged } from 'rxjs';
import { SpaceService } from '../../../core/services/space.service';
import { BookingService } from '../../../core/services/booking.service';
import { Space } from '../../../core/models/space.model';
import { PricePreview } from '../../../core/models/booking.model';
import { PricePreviewComponent } from '../price-preview/price-preview.component';
import { UserService } from '../../../core/services/user.service';
import { User } from '../../../core/models/user.model';
import { MatSnackBar } from '@angular/material/snack-bar';

@Component({
  selector: 'app-booking-form',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatDatepickerModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule,
    MatCardModule,
    MatDividerModule,
    MatSlideToggleModule,
    PricePreviewComponent
  ],
  templateUrl: 'booking-form.component.html',
  styleUrls: ['booking-form.component.scss']
})
export class BookingFormComponent implements OnInit {
  form: FormGroup;
  spaces: Space[] = [];
  users: User[] = [];
  availableStartOptions: string[] = [];
  availableEndOptions: string[] = [];
  preview: PricePreview | null = null;
  loading = false;
  previewLoading = false;
  error = '';
  conflictError = false;
  readonly slotStepMinutes = 30;
  readonly minDurationMinutes = 30;
  readonly maxDurationMinutes = 8 * 60;

  private _snackBar = inject(MatSnackBar);

  constructor(
    private fb: FormBuilder,
    private spaceService: SpaceService,
    private userService: UserService,
    private bookingService: BookingService,
    private router: Router,
    private route: ActivatedRoute
  ) {
    this.form = this.fb.group({
      spaceId: [null, Validators.required],
      userId: [1, Validators.required],
      bookingDate: [null, Validators.required],
      exactTimes: [false],
      startSlot: ['', Validators.required],
      endSlot: ['', Validators.required],
      startTime: ['', Validators.required],
      endTime: ['', Validators.required]
    }, { validators: this.validateTimeRange });
  }

  ngOnInit(): void {
    // Cargar espacios activos
    this.spaceService.getAll('active').subscribe({
      next: spaces => {
        this.spaces = spaces;
        this.refreshTimeOptions();
      }
    });

    // Pre-seleccionar espacio si viene por queryParam
    this.route.queryParams.subscribe(params => {
      if (params['spaceId'])
        this.form.patchValue({ spaceId: +params['spaceId'] });
    });

    this.form.get('spaceId')?.valueChanges.subscribe(() => {
      this.refreshTimeOptions();
    });

    this.form.get('startSlot')?.valueChanges.subscribe(() => {
      if (!this.useExactTimesMode()) {
        this.refreshEndOptions();
      }
    });

    this.form.get('exactTimes')?.valueChanges.subscribe(() => {
      this.handleTimeModeChange();
    });

    // Preview en tiempo real
    this.form.valueChanges.pipe(
      debounceTime(500),
      distinctUntilChanged()
    ).subscribe(() => {
      this.syncDateTimeControls();
      this.refreshTimeOptions();
      this.loadPreview();
    });

    this.refreshTimeOptions();
    this.loadUsers();
  }

  private validateTimeRange = (control: AbstractControl): ValidationErrors | null => {
    const start = control.get('startTime')?.value;
    const end = control.get('endTime')?.value;

    if (!start || !end) {
      return null;
    }

    const startDate = new Date(start);
    const endDate = new Date(end);
    const durationMinutes = (endDate.getTime() - startDate.getTime()) / 60000;
    const currentSpace = this.getSelectedSpace();

    if (!currentSpace) {
      return null;
    }

    if (endDate <= startDate) {
      return { invalidTimeRange: true };
    }

    if (durationMinutes < this.minDurationMinutes) {
      return { minDuration: true };
    }

    if (durationMinutes > this.maxDurationMinutes) {
      return { maxDuration: true };
    }

    const openingMinutes = this.timeToMinutes(currentSpace.openingTime);
    const closingMinutes = this.timeToMinutes(currentSpace.closingTime);
    const startMinutes = startDate.getHours() * 60 + startDate.getMinutes();
    const endMinutes = endDate.getHours() * 60 + endDate.getMinutes();

    if (startMinutes < openingMinutes || endMinutes > closingMinutes) {
      return { outsideOpeningHours: true };
    }

    return null;
  }

  private syncDateTimeControls(): void {
    const bookingDate: Date | null = this.form.get('bookingDate')?.value;
    const startSlot: string = this.form.get('startSlot')?.value;
    const endSlot: string = this.form.get('endSlot')?.value;

    if (!bookingDate || !startSlot || !endSlot) {
      this.form.patchValue({ startTime: '', endTime: '' }, { emitEvent: false });
      return;
    }

    this.form.patchValue({
      startTime: this.toLocalDateTime(bookingDate, startSlot),
      endTime: this.toLocalDateTime(bookingDate, endSlot)
    }, { emitEvent: false });
  }

  private refreshTimeOptions(): void {
    const currentSpace = this.getSelectedSpace();
    const bookingDate: Date | null = this.form.get('bookingDate')?.value;

    if (this.useExactTimesMode()) {
      this.availableStartOptions = [];
      this.availableEndOptions = [];
      return;
    }

    if (!currentSpace) {
      this.availableStartOptions = [];
      this.availableEndOptions = [];
      this.form.patchValue({ startSlot: '', endSlot: '', startTime: '', endTime: '' }, { emitEvent: false });
      return;
    }

    this.availableStartOptions = this.buildStartOptions(currentSpace, bookingDate);

    const selectedStart = this.form.get('startSlot')?.value;
    if (selectedStart && !this.availableStartOptions.includes(selectedStart)) {
      this.form.patchValue({ startSlot: '', endSlot: '', startTime: '', endTime: '' }, { emitEvent: false });
      this.availableEndOptions = [];
      return;
    }

    this.refreshEndOptions();
  }

  private refreshEndOptions(): void {
    if (this.useExactTimesMode()) {
      this.availableEndOptions = [];
      return;
    }

    const currentSpace = this.getSelectedSpace();
    const startSlot: string = this.form.get('startSlot')?.value;

    if (!currentSpace || !startSlot) {
      this.availableEndOptions = [];
      this.form.patchValue({ endSlot: '', endTime: '' }, { emitEvent: false });
      return;
    }

    this.availableEndOptions = this.buildEndOptions(currentSpace, startSlot);

    const selectedEnd = this.form.get('endSlot')?.value;
    if (selectedEnd && !this.availableEndOptions.includes(selectedEnd)) {
      this.form.patchValue({ endSlot: '', endTime: '' }, { emitEvent: false });
    }
  }

  private toLocalDateTime(date: Date, slot: string): string {
    const [hours, minutes] = slot.split(':').map(Number);
    const value = new Date(date);
    value.setHours(hours, minutes, 0, 0);

    const year = value.getFullYear();
    const month = String(value.getMonth() + 1).padStart(2, '0');
    const day = String(value.getDate()).padStart(2, '0');
    const hour = String(value.getHours()).padStart(2, '0');
    const minute = String(value.getMinutes()).padStart(2, '0');

    return `${year}-${month}-${day}T${hour}:${minute}`;
  }

  private getSelectedSpace(): Space | null {
    const spaceId = this.form.get('spaceId')?.value;
    return this.spaces.find(space => space.id === spaceId) ?? null;
  }

  private buildStartOptions(space: Space, bookingDate: Date | null): string[] {
    const openingMinutes = this.timeToMinutes(space.openingTime);
    const lastStartMinutes = this.timeToMinutes(space.closingTime) - this.minDurationMinutes;
    const startMinutes = this.isToday(bookingDate)
      ? Math.max(openingMinutes, this.getRoundedCurrentMinutes())
      : openingMinutes;

    return this.buildOptionsRange(startMinutes, lastStartMinutes);
  }

  private buildEndOptions(space: Space, startSlot: string): string[] {
    const startMinutes = this.slotToMinutes(startSlot);
    const openingMinutes = this.timeToMinutes(space.openingTime);
    const closingMinutes = this.timeToMinutes(space.closingTime);
    const earliestEnd = Math.max(startMinutes + this.minDurationMinutes, openingMinutes + this.minDurationMinutes);
    const latestEnd = Math.min(startMinutes + this.maxDurationMinutes, closingMinutes);

    return this.buildOptionsRange(earliestEnd, latestEnd);
  }

  private buildOptionsRange(startMinutes: number, endMinutes: number): string[] {
    const options: string[] = [];

    for (let minutes = startMinutes; minutes <= endMinutes; minutes += this.slotStepMinutes) {
      options.push(this.minutesToSlot(minutes));
    }

    return options;
  }

  private timeToMinutes(time: string): number {
    const [hours, minutes] = time.split(':').map(Number);
    return hours * 60 + minutes;
  }

  private slotToMinutes(slot: string): number {
    const [hours, minutes] = slot.split(':').map(Number);
    return hours * 60 + minutes;
  }

  private minutesToSlot(totalMinutes: number): string {
    const hours = Math.floor(totalMinutes / 60);
    const minutes = totalMinutes % 60;
    return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}`;
  }

  private isToday(date: Date | null): boolean {
    if (!date) {
      return false;
    }

    const value = new Date(date);
    const now = new Date();

    return value.getFullYear() === now.getFullYear()
      && value.getMonth() === now.getMonth()
      && value.getDate() === now.getDate();
  }

  private getRoundedCurrentMinutes(): number {
    const now = new Date();
    const currentMinutes = now.getHours() * 60 + now.getMinutes();
    const rounded = Math.ceil(currentMinutes / this.slotStepMinutes) * this.slotStepMinutes;

    return Math.min(rounded, 24 * 60);
  }

  private useExactTimesMode(): boolean {
    return Boolean(this.form.get('exactTimes')?.value);
  }

  private handleTimeModeChange(): void {
    const isExactMode = this.useExactTimesMode();

    if (isExactMode) {
      this.availableStartOptions = [];
      this.availableEndOptions = [];
      return;
    }

    this.refreshTimeOptions();
  }

  loadPreview(): void {
    const { spaceId, userId, startTime, endTime } = this.form.value;
    if (!spaceId || !userId || !startTime || !endTime || this.form.invalid) {
      this.preview = null;
      return;
    }

    // Validar que endTime sea posterior a startTime
    if (new Date(endTime) <= new Date(startTime)) {
      this.preview = null;
      return;
    }

    this.previewLoading = true;
    this.preview = null;

    const request = {
      spaceId,
      userId,
      startTime: startTime + ':00',
      endTime: endTime + ':00'
    };

    this.bookingService.getPricePreview(request).subscribe({
      next: preview => { this.preview = preview; this.previewLoading = false; },
      error: () => { this.previewLoading = false; }
    });
  }

  onSubmit(): void {
    if (this.form.invalid || !this.preview) {
      return;
    }

    this.loading = true;
    this.error = '';
    this.conflictError = false;

    const { spaceId, userId, startTime, endTime } = this.form.value;

    const request = {
      spaceId,
      userId,
      startTime: `${startTime}:00`,
      endTime: `${endTime}:00`
    };

    this.bookingService.create(request).subscribe({
      next: () => {
        this._snackBar.open(
          'Reserva creada correctamente.',
          'Cerrar',
          { duration: 3000 }
        );

        this.router.navigate(['/bookings']);
      },
      error: (err) => {
        this.loading = false;

        if (err.status === 409) {
          this.conflictError = true;
        } else {
          this.error = err.message;
        }

        this._snackBar.open(
          'Error al crear la reserva.',
          'Cerrar',
          { duration: 3000 }
        );
      }
    });
  }

  cancel(): void {
    this.router.navigate(['/bookings']);
  }

  loadUsers(): void {

    this.userService.getAll().subscribe({
      next: users => {
        this.users = users;
      },
      error: err => { this.error = err.message; this.loading = false; }
    });
  }
}