import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { ReportResult } from '../models/report.model';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class ReportService {
  private readonly apiUrl = environment.apiUrl + '/reports';

  constructor(private http: HttpClient) {}

  getReport(fromDate: string, toDate: string): Observable<ReportResult> {
    const params = new HttpParams()
      .set('fromDate', fromDate)
      .set('toDate',   toDate);
    return this.http.get<ReportResult>(this.apiUrl, { params });
  }
}