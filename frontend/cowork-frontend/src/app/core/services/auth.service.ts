import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Observable, tap } from 'rxjs';
import { LoginRequest, LoginResponse } from '../models/auth.model';
import { environment } from '../../../environments/environment';

@Injectable({
    providedIn: 'root'
})
export class AuthService {
    private readonly apiUrl = environment.apiUrl + '/auth';
    private readonly storageKey = 'cowork_user';

    currentUser = signal<LoginResponse | null>(this.loadFromStorage());

    constructor(private http: HttpClient, private router: Router) { }

    private loadFromStorage(): LoginResponse | null {
        try {
            const stored = localStorage.getItem(this.storageKey);
            if (!stored) return null;
            const user = JSON.parse(stored) as LoginResponse;
            // Verificar que el token no haya expirado
            if (new Date(user.expiresAt) < new Date()) {
                localStorage.removeItem(this.storageKey);
                return null;
            }
            return user;
        } catch {
            return null;
        }
    }

    login(request: LoginRequest): Observable<LoginResponse> {
        return this.http.post<LoginResponse>(`${this.apiUrl}/login`, request).pipe(
            tap(response => {
                localStorage.setItem(this.storageKey, JSON.stringify(response));
                this.currentUser.set(response);
            })
        );
    }

    logout(): void {
        localStorage.removeItem(this.storageKey);
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