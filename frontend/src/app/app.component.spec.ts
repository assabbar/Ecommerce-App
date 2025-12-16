import { TestBed } from '@angular/core/testing';
import { AppComponent } from './app.component';
import { provideRouter } from '@angular/router';
import { provideHttpClient } from '@angular/common/http';
import { OidcSecurityService } from 'angular-auth-oidc-client';
import { of } from 'rxjs';

describe('AppComponent', () => {
  let mockOidcSecurityService: jasmine.SpyObj<OidcSecurityService>;

  beforeEach(async () => {
    mockOidcSecurityService = jasmine.createSpyObj('OidcSecurityService', ['checkAuth']);
    mockOidcSecurityService.checkAuth.and.returnValue(of({ isAuthenticated: false }));

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

  it('should check authentication on init', () => {
    mockOidcSecurityService.checkAuth.and.returnValue(of({ isAuthenticated: true }));
    
    const fixture = TestBed.createComponent(AppComponent);
    fixture.detectChanges();
    
    expect(mockOidcSecurityService.checkAuth).toHaveBeenCalled();
  });

  it('should handle unauthenticated state', () => {
    mockOidcSecurityService.checkAuth.and.returnValue(of({ isAuthenticated: false }));
    
    const fixture = TestBed.createComponent(AppComponent);
    fixture.detectChanges();
    
    expect(mockOidcSecurityService.checkAuth).toHaveBeenCalled();
  });

  it('should render header component', () => {
    const fixture = TestBed.createComponent(AppComponent);
    fixture.detectChanges();
    
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('app-header')).toBeTruthy();
  });

  it('should have router outlet for navigation', () => {
    const fixture = TestBed.createComponent(AppComponent);
    fixture.detectChanges();
    
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('router-outlet')).toBeTruthy();
  });
});
