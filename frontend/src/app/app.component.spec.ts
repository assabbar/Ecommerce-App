import { TestBed } from '@angular/core/testing';
import { AppComponent } from './app.component';
import { provideRouter } from '@angular/router';
import { provideHttpClient } from '@angular/common/http';
import { OidcSecurityService } from 'angular-auth-oidc-client';
import { of } from 'rxjs';

describe('AppComponent', () => {
  const mockOidcSecurityService = {
    checkAuth: jasmine.createSpy('checkAuth').and.returnValue(
      of({ isAuthenticated: false })
    )
  };

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [AppComponent],
      providers: [
        provideRouter([]),
        provideHttpClient(),
        { provide: OidcSecurityService, useValue: mockOidcSecurityService }
      ]
    }).compileComponents();
  });

  it('should create the app', () => {
    const fixture = TestBed.createComponent(AppComponent);
    const app = fixture.componentInstance;
    expect(app).toBeTruthy();
  });

  it('should have the microservices-shop-frontend title', () => {
    const fixture = TestBed.createComponent(AppComponent);
    const app = fixture.componentInstance;
    expect(app.title).toEqual('microservices-shop-frontend');
  });
});
