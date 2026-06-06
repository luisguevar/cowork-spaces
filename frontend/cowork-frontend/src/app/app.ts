import { Component } from '@angular/core';
import { RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';
import { CommonModule } from '@angular/common';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { AuthService } from './core/services/auth.service';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [
    CommonModule,
    RouterOutlet,
    RouterLink,
    RouterLinkActive,
    MatToolbarModule,
    MatButtonModule,
    MatIconModule
  ],
  template: `
    <mat-toolbar color="primary">
      <span>CoWork Spaces</span>
      <span class="spacer"></span>

      <ng-container *ngIf="authService.isLoggedIn()">
        <a mat-button routerLink="/spaces"   routerLinkActive="active-link">Spaces</a>
        <a mat-button routerLink="/bookings" routerLinkActive="active-link">Bookings</a>
        <a mat-button routerLink="/reports"  routerLinkActive="active-link">Reports</a>
        <span class="user-name">
          <mat-icon>account_circle</mat-icon>
          {{ authService.currentUser()?.name }}
        </span>
        <button mat-button (click)="authService.logout()">
          <mat-icon>logout</mat-icon> Logout
        </button>
      </ng-container>
    </mat-toolbar>

    <main class="container">
      <router-outlet />
    </main>
  `,
  styles: [`
    .spacer { flex: 1 1 auto; }
    .container { padding: 24px; max-width: 1200px; margin: 0 auto; }
    .active-link { background: rgba(255,255,255,0.15); border-radius: 4px; }
    .user-name { display: flex; align-items: center; gap: 4px;
                 margin: 0 8px; font-size: 0.9em; opacity: 0.9; }
  `]
})
export class App {
  constructor(public authService: AuthService) { }
}