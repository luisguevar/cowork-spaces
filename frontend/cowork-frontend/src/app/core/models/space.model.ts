export interface Space {
  id: number;
  name: string;
  capacity: number;
  hourlyRate: number;
  openingTime: string;
  closingTime: string;
  status: 'active' | 'maintenance';
  createdAt: string;
  updatedAt: string;
}

export interface CreateSpaceRequest {
  name: string;
  capacity: number;
  hourlyRate: number;
  openingTime: string;
  closingTime: string;
}

export interface UpdateSpaceRequest extends CreateSpaceRequest {
  status: 'active' | 'maintenance';
}