import { Component, inject, OnInit } from '@angular/core';
import { OidcSecurityService } from 'angular-auth-oidc-client';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './login.component.html',
  styleUrl: './login.component.css'
})
export class LoginComponent implements OnInit {
  private readonly oidcSecurityService = inject(OidcSecurityService);
  private readonly router = inject(Router);

  ngOnInit(): void {
    // Check if user is already authenticated
    this.oidcSecurityService.isAuthenticated$.subscribe(({ isAuthenticated }) => {
      if (isAuthenticated) {
        this.router.navigate(['/']);
      }
    });
  }

  login(): void {
    console.log('Login button clicked');
    this.oidcSecurityService.authorize();
  }

  loginAsAdmin(): void {
    // The actual login is the same, the role is determined by Keycloak
    this.login();
  }
}
