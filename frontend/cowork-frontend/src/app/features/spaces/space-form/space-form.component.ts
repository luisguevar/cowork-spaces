import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { SpaceService } from '../../../core/services/space.service';

@Component({
  selector: 'app-space-form',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatFormFieldModule,
    MatInputModule,
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

  constructor(
    private fb: FormBuilder,
    private spaceService: SpaceService,
    private router: Router
  ) {
    this.form = this.fb.group({
      name: ['', [Validators.required, Validators.maxLength(100)]],
      capacity: [null, [Validators.required, Validators.min(1)]],
      hourlyRate: [null, [Validators.required, Validators.min(0.01)]],
      openingTime: ['', Validators.required],
      closingTime: ['', Validators.required]
    });
  }

  onSubmit(): void {
    if (this.form.invalid) return;

    this.loading = true;
    this.error = '';

    this.spaceService.create(this.form.value).subscribe({
      next: () => this.router.navigate(['/spaces']),
      error: err => { this.error = err.message; this.loading = false; }
    });
  }

  cancel(): void {
    this.router.navigate(['/spaces']);
  }
}