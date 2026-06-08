import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Space, CreateSpaceRequest, UpdateSpaceRequest } from '../models/space.model';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class SpaceService {
  private readonly apiUrl = environment.apiUrl + '/spaces';

  constructor(private http: HttpClient) {}

  getAll(status?: string): Observable<Space[]> {
    let params = new HttpParams();
    if (status) params = params.set('status', status);
    return this.http.get<Space[]>(this.apiUrl, { params });
  }

  getById(id: number): Observable<Space> {
    return this.http.get<Space>(`${this.apiUrl}/${id}`);
  }

  create(request: CreateSpaceRequest): Observable<Space> {
    return this.http.post<Space>(this.apiUrl, request);
  }

  update(id: number, request: UpdateSpaceRequest): Observable<Space> {
    return this.http.put<Space>(`${this.apiUrl}/${id}`, request);
  }

  deactivate(id: number): Observable<Space> {
    return this.http.delete<Space>(`${this.apiUrl}/${id}`);
  }
}