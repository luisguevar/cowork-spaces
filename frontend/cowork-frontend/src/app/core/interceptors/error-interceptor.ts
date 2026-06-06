import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { catchError, throwError } from 'rxjs';

export const errorInterceptor: HttpInterceptorFn = (req, next) => {
  return next(req).pipe(
    catchError((error: HttpErrorResponse) => {
      let message = 'Ocurrió un error inesperado. Por favor, inténtalo de nuevo.';

      if (error.error?.detail) {
        message = error.error.detail;
      }

      return throwError(() => ({
        status:  error.status,
        message: message
      }));
    })
  );
};