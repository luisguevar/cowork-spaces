import { Component, inject, OnInit, ViewChild } from '@angular/core';
import { RouterLink } from '@angular/router';
import { CommonModule } from '@angular/common';
import { MatTableModule, MatTableDataSource } from '@angular/material/table';
import { MatButtonModule } from '@angular/material/button';
import { MatChipsModule } from '@angular/material/chips';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatPaginator, MatPaginatorModule } from '@angular/material/paginator';
import { SpaceService } from '../../../core/services/space.service';
import { Space } from '../../../core/models/space.model';
import { AuthService } from '../../../core/services/auth.service';
import { MatSnackBar } from '@angular/material/snack-bar';

@Component({
  selector: 'app-space-list',
  standalone: true,
  imports: [
    CommonModule,
    RouterLink,
    MatTableModule,
    MatButtonModule,
    MatChipsModule,
    MatIconModule,
    MatProgressSpinnerModule,
    MatPaginatorModule
  ],
  templateUrl: 'space-list.component.html',
  styleUrls: ['space-list.component.scss']
})
export class SpaceListComponent implements OnInit {
  spaces: Space[] = [];
  dataSource = new MatTableDataSource<Space>([]);
  columns = ['name', 'capacity', 'hourlyRate', 'hours', 'status', 'actions'];
  loading = false;
  error = '';
  private _snackBar = inject(MatSnackBar);
  private paginator?: MatPaginator;

  @ViewChild(MatPaginator)
  set matPaginator(paginator: MatPaginator | undefined) {
    this.paginator = paginator;
    if (paginator) {
      this.dataSource.paginator = paginator;
    }
  }

  constructor(private spaceService: SpaceService, public authService: AuthService) { }

  ngOnInit(): void {
    this.loadSpaces();
  }

  loadSpaces(): void {
    this.loading = true;
    this.error = '';
    this.spaceService.getAll().subscribe({
      next: spaces => {
        this.spaces = spaces;
        this.dataSource.data = spaces;
        if (this.paginator) {
          this.dataSource.paginator = this.paginator;
          this.paginator.firstPage();
        }
        this.loading = false;
      },
      error: err => { this.error = err.message; this.loading = false; }
    });
  }

  deactivate(id: number): void {
    if (!confirm('¿Está seguro de que desea desactivar este ambiente?')) {
      return;
    }

    this.spaceService.deactivate(id).subscribe({
      next: () => {
        this.loadSpaces();
        this._snackBar.open(
          'Ambiente desactivado correctamente.',
          'Cerrar',
          { duration: 3000 }
        );
      },
      error: (err) => {
        this.error = err.message;
        this._snackBar.open(
          'Error al desactivar el ambiente.',
          'Cerrar',
          { duration: 3000 }
        );
      }
    });
  }

  getStatusName(status: string): string {
    switch (status) {
      case 'active': return 'Activo';
      case 'maintenance': return 'Mantenimiento';
      default: return status;
    }
  }

  getStatusClass(status: string): string {
    const map: Record<string, string> = {
      active: 'dot confirmed',
      maintenance: 'dot warning'
    };
    return map[status] ?? '';
  }
}