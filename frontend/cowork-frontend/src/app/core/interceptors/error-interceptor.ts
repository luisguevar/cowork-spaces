import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, throwError } from 'rxjs';
import { AuthService } from '../services/auth.service';

export const errorInterceptor: HttpInterceptorFn = (req, next) => {
  const router = inject(Router);
  const authService = inject(AuthService);

  return next(req).pipe(
    catchError((error: HttpErrorResponse) => {
      if (error.status === 401) {
        authService.logout();
        router.navigate(['/login']);
      }

      let message = 'Se ha producido un error inesperado. Inténtalo de nuevo.';

      if (error.error?.errors) {
        const validationErrors = Object.values(error.error.errors)
          .flat() as string[];

        if (validationErrors.length > 0) {
          message = validationErrors[0];
        }
      } else if (error.error?.detail) {
        message = error.error.detail;
      }

      return throwError(() => ({
        status: error.status,
        message
      }));
    })
  );
};