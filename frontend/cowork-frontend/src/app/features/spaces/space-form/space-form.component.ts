import { Component, inject, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { SpaceService } from '../../../core/services/space.service';
import { MatSnackBar } from '@angular/material/snack-bar';

@Component({
  selector: 'app-space-form',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule
  ],
  templateUrl: 'space-form.component.html',
  styleUrls: ['space-form.component.scss']
})
export class SpaceFormComponent {
  form: FormGroup;
  loading = false;
  error = '';
  isEditMode = false;
  private spaceId: number | null = null;
  private _snackBar = inject(MatSnackBar);
  constructor(
    private fb: FormBuilder,
    private spaceService: SpaceService,
    private router: Router,
    private route: ActivatedRoute
  ) {
    this.form = this.fb.group({
      name: ['', [Validators.required, Validators.maxLength(100)]],
      capacity: [null, [Validators.required, Validators.min(1), Validators.max(2147483647)]],
      hourlyRate: [null, [Validators.required, Validators.min(0.01), Validators.max(1000), Validators.maxLength(3)]],
      status: ['active', Validators.required],
      openingTime: ['', Validators.required],
      closingTime: ['', Validators.required]
    });
  }

  ngOnInit(): void {
    const id = Number(this.route.snapshot.paramMap.get('id'));

    if (!Number.isNaN(id) && id > 0) {
      this.isEditMode = true;
      this.spaceId = id;
      this.loadSpace(id);
    }
  }

  onSubmit(): void {
    if (this.form.invalid) return;

    const confirmed = this.isEditMode
      ? confirm('¿Desea actualizar este ambiente?')
      : confirm('¿Desea guardar este ambiente?');

    if (!confirmed) {
      return;
    }

    this.loading = true;
    this.error = '';

    const request = this.form.getRawValue();

    if (this.isEditMode && this.spaceId !== null) {
      this.spaceService.update(this.spaceId, request).subscribe({
        next: () => {
          this._snackBar.open('Ambiente actualizado correctamente.', 'Cerrar', { duration: 3000 });
          this.router.navigate(['/spaces']);
        },
        error: err => { this.error = err.message; this.loading = false; }
      });

      return;
    }

    const { name, capacity, hourlyRate, openingTime, closingTime } = request;

    this.spaceService.create({
      name,
      capacity,
      hourlyRate,
      openingTime,
      closingTime
    }).subscribe({
      next: () => {
        this._snackBar.open('Ambiente guardado correctamente.', 'Cerrar', { duration: 3000 });
        this.router.navigate(['/spaces']);
      },
      error: err => { this.error = err.message; this.loading = false; }
    });
  }

  cancel(): void {
    this.router.navigate(['/spaces']);
  }

  private loadSpace(id: number): void {
    this.loading = true;
    this.error = '';

    this.spaceService.getById(id).subscribe({
      next: space => {
        this.form.patchValue({
          name: space.name,
          capacity: space.capacity,
          hourlyRate: space.hourlyRate,
          status: space.status,
          openingTime: space.openingTime,
          closingTime: space.closingTime
        });
        this.loading = false;
      },
      error: err => {
        this.error = err.message;
        this.loading = false;
      }
    });
  }
}