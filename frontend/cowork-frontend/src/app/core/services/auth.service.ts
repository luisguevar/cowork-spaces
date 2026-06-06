import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Observable, tap } from 'rxjs';
import { LoginRequest, LoginResponse } from '../models/auth.model';

@Injectable({
    providedIn: 'root'
})
export class AuthService {
    private readonly apiUrl = 'http://localhost:5209/api/auth';

    currentUser = signal<LoginResponse | null>(null);

    constructor(private http: HttpClient, private router: Router) { }

    login(request: LoginRequest): Observable<LoginResponse> {
        return this.http.post<LoginResponse>(`${this.apiUrl}/login`, request).pipe(
            tap(response => this.currentUser.set(response))
        );
    }

    logout(): void {
        this.currentUser.set(null);
        this.router.navigate(['/login']);
    }

    isLoggedIn(): boolean {
        return this.currentUser() !== null;
    }

    getToken(): string | null {
        return this.currentUser()?.token ?? null;
    }
}