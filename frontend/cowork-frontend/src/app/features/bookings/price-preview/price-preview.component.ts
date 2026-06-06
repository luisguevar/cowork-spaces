import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatDividerModule } from '@angular/material/divider';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { PricePreview } from '../../../core/models/booking.model';

@Component({
  selector: 'app-price-preview',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatDividerModule,
    MatProgressSpinnerModule
  ],
  template: `
    <mat-card class="preview-card" *ngIf="preview || loading">
      <mat-card-header>
        <mat-card-title>Detalle de Reserva</mat-card-title>
      </mat-card-header>

      <mat-card-content>
        <div *ngIf="loading" class="preview-loading">
          <mat-spinner diameter="30" />
        </div>

        <div *ngIf="preview && !loading" class="price-breakdown">

          <div class="price-row">
            <span>Precio base</span>
            <span>{{ preview.basePrice | currency:'PEN ':'symbol' }}</span>
          </div>

          <div class="price-row adjustment" *ngIf="preview.peakHourAdjustment > 0">
            <span>Hora punta (+25%)</span>
            <span>+ {{ preview.peakHourAdjustment | currency:'PEN ':'symbol' }}</span>
          </div>

          <div class="price-row adjustment" *ngIf="preview.weekendAdjustment > 0">
            <span>Fin de semana (+15%)</span>
            <span>+ {{ preview.weekendAdjustment | currency:'PEN ':'symbol' }}</span>
          </div>

          <div class="price-row discount" *ngIf="preview.longBookingDiscount > 0">
            <span>Reserva larga (-10%)</span>
            <span>- {{ preview.longBookingDiscount | currency:'PEN ':'symbol' }}</span>
          </div>

          <div class="price-row discount" *ngIf="preview.earlyBookingDiscount > 0">
            <span>Reserva anticipada (-5%)</span>
            <span>- {{ preview.earlyBookingDiscount | currency:'PEN ':'symbol' }}</span>
          </div>

          <mat-divider />

          <div class="price-row total">
            <span>Total</span>
            <span>{{ preview.finalPrice | currency:'PEN ':'symbol' }}</span>
          </div>

        </div>
      </mat-card-content>
    </mat-card>
  `,
  styles: [`
    .preview-card { width: 300px; position: sticky; top: 24px; }
    .preview-loading { display: flex; justify-content: center; padding: 20px; }
    .price-breakdown { padding: 8px 0; }
    .price-row { display: flex; justify-content: space-between; padding: 8px 0; }
    .price-row.adjustment { color: #e65100; }
    .price-row.discount { color: #2e7d32; }
    .price-row.total { font-weight: 500; font-size: 1.1em; padding-top: 12px; }
  `]
})
export class PricePreviewComponent {
  @Input() preview: PricePreview | null = null;
  @Input() loading = false;
}