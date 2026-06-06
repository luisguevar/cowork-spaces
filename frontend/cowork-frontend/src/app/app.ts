import { Component } from '@angular/core';
import { RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatButtonModule } from '@angular/material/button';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [
    RouterOutlet,
    RouterLink,
    RouterLinkActive,
    MatToolbarModule,
    MatButtonModule
  ],
  template: `
    <mat-toolbar color="primary">
      <span>CoWork Spaces</span>
      <span class="spacer"></span>
      <a mat-button routerLink="/spaces"   routerLinkActive="active-link">Ambientes</a>
      <a mat-button routerLink="/bookings" routerLinkActive="active-link">Reservas</a>
      <a mat-button routerLink="/reports"  routerLinkActive="active-link">Reportes</a>
    </mat-toolbar>

    <main class="container">
      <router-outlet />
    </main>
  `,
  styles: [`
    .spacer { flex: 1 1 auto; }
    .container { padding: 24px; max-width: 1200px; margin: 0 auto; }
    .active-link { background: rgba(255,255,255,0.15); border-radius: 4px; }
  `]
})
export class App {
  title = 'cowork-frontend';
}