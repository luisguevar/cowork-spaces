import { Routes } from '@angular/router';

export const routes: Routes = [
  {
    path: '',
    redirectTo: 'spaces',
    pathMatch: 'full'
  },
  {
    path: 'spaces',
    loadComponent: () =>
      import('./features/spaces/space-list/space-list.component')
        .then(m => m.SpaceListComponent)
  },
  {
    path: 'spaces/new',
    loadComponent: () =>
      import('./features/spaces/space-form/space-form.component')
        .then(m => m.SpaceFormComponent)
  },
  {
    path: 'bookings',
    loadComponent: () =>
      import('./features/bookings/booking-list/booking-list.component')
        .then(m => m.BookingListComponent)
  },
  {
    path: 'bookings/new',
    loadComponent: () =>
      import('./features/bookings/booking-form/booking-form.component')
        .then(m => m.BookingFormComponent)
  },
  {
    path: 'reports',
    loadComponent: () =>
      import('./features/reports/report-dashboard/report-dashboard.component')
        .then(m => m.ReportDashboardComponent)
  },
  {
    path: '**',
    redirectTo: 'spaces'
  }
];