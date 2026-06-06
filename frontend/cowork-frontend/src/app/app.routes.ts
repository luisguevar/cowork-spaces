import { Routes } from '@angular/router';
import { authGuard } from './core/guards/auth.guard';

export const routes: Routes = [
  {
    path: 'login',
    loadComponent: () =>
      import('./features/auth/login/login.component')
        .then(m => m.LoginComponent)
  },
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
    canActivate: [authGuard],
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
    canActivate: [authGuard],
    loadComponent: () =>
      import('./features/bookings/booking-form/booking-form.component')
        .then(m => m.BookingFormComponent)
  },
  {
    path: 'reports',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./features/reports/report-dashboard/report-dashboard.component')
        .then(m => m.ReportDashboardComponent)
  },
  {
    path: '**',
    redirectTo: 'spaces'
  }
];