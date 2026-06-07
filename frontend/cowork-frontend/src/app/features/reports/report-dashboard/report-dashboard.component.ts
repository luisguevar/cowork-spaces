import { Component, OnInit, AfterViewInit, ElementRef, ViewChild } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatTableModule } from '@angular/material/table';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatIconModule } from '@angular/material/icon';
import { ReportService } from '../../../core/services/report.service';
import { ReportResult } from '../../../core/models/report.model';
import { Chart, registerables } from 'chart.js';
import { MatDatepickerModule } from '@angular/material/datepicker';

Chart.register(...registerables);

@Component({
  selector: 'app-report-dashboard',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatCardModule,
    MatTableModule,
    MatProgressSpinnerModule,
    MatIconModule,
    MatDatepickerModule,
  ],
  templateUrl: 'report-dashboard.component.html',
  styleUrls: ['report-dashboard.component.scss']
})
export class ReportDashboardComponent implements OnInit, AfterViewInit {
  @ViewChild('revenueChart') chartRef!: ElementRef<HTMLCanvasElement>;

  form: FormGroup;
  report: ReportResult | null = null;
  loading = false;
  error = '';
  columns = ['spaceName', 'totalBookings', 'bookedHours', 'occupancyRate', 'totalRevenue'];
  private chart: Chart | null = null;

  constructor(
    private fb: FormBuilder,
    private reportService: ReportService
  ) {
    const today = new Date();
    const firstDay = new Date(today.getFullYear(), today.getMonth(), 1);

    this.form = this.fb.group({
      fromDate: [firstDay, Validators.required],
      toDate: [today, Validators.required]
    });
  }

  ngOnInit(): void { }

  ngAfterViewInit(): void { }

  loadReport(): void {
    if (this.form.invalid) return;

    this.loading = true;
    this.error = '';
    this.report = null;

    const { fromDate, toDate } = this.form.value;

    const fromDateValue = this.toApiDate(fromDate);
    const toDateValue = this.toApiDate(toDate);

    if (!fromDateValue || !toDateValue) {
      this.error = 'Las fechas no son validas.';
      this.loading = false;
      return;
    }

    this.reportService.getReport(fromDateValue, toDateValue).subscribe({
      next: report => {
        this.report = report;
        this.loading = false;
        setTimeout(() => this.renderChart(), 100);
      },
      error: err => {
        this.error = err.message;
        this.loading = false;
      }
    });
  }

  renderChart(): void {
    if (!this.chartRef || !this.report) return;

    if (this.chart) {
      this.chart.destroy();
      this.chart = null;
    }

    const labels = this.report.spaceOccupancies.map(s => s.spaceName);
    const data = this.report.spaceOccupancies.map(s => s.totalRevenue);

    this.chart = new Chart(this.chartRef.nativeElement, {
      type: 'bar',
      data: {
        labels,
        datasets: [{
          label: 'Ingresos (PEN)',
          data,
          backgroundColor: '#1565c0',
          borderRadius: 4
        }]
      },
      options: {
        responsive: true,
        plugins: {
          legend: { display: false }
        },
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              callback: value => '$' + value
            }
          }
        }
      }
    });
  }

  private toApiDate(value: Date | string | null): string | null {
    if (!value) {
      return null;
    }

    const date = value instanceof Date ? value : new Date(value);
    if (Number.isNaN(date.getTime())) {
      return null;
    }

    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');

    return `${year}-${month}-${day}`;
  }
}