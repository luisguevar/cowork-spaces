import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SpaceAvailabilityComponent } from './space-availability.component';

describe('SpaceAvailabilityComponent', () => {
  let component: SpaceAvailabilityComponent;
  let fixture: ComponentFixture<SpaceAvailabilityComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SpaceAvailabilityComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(SpaceAvailabilityComponent);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
