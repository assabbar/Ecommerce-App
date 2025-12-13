import { Injectable, inject } from '@angular/core';
import { BehaviorSubject, Observable, map } from 'rxjs';
import { OidcSecurityService } from 'angular-auth-oidc-client';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private oidcSecurityService = inject(OidcSecurityService);
  private isAdminSubject = new BehaviorSubject<boolean>(false);
  public isAdmin$ = this.isAdminSubject.asObservable();

  constructor() {
    // Listen to user data changes and update admin status
    this.oidcSecurityService.userData$.subscribe(
      ({userData}) => {
        if (userData && userData.realm_access) {
          const roles = userData.realm_access.roles || [];
          const isAdmin = roles.includes('admin');
          this.isAdminSubject.next(isAdmin);
          console.log('AuthService - User Roles:', roles, 'Is Admin:', isAdmin);
        } else {
          this.isAdminSubject.next(false);
        }
      }
    );
  }

  getIsAdmin(): boolean {
    return this.isAdminSubject.value;
  }

  isAuthenticated$(): Observable<boolean> {
    return this.oidcSecurityService.isAuthenticated$.pipe(
      map(result => result.isAuthenticated)
    );
  }
}

