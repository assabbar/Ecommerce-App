import { Component, inject } from '@angular/core';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './login.component.html',
  styleUrl: './login.component.css'
})
export class LoginComponent {
  private readonly router = inject(Router);
  
  username: string = 'admin';
  password: string = '';
  errorMessage: string = '';

  login(): void {
    // Simple demo login without Keycloak
    if (this.username && this.password) {
      // Store in localStorage for demo purposes
      localStorage.setItem('auth_token', 'demo-token-' + this.username);
      localStorage.setItem('username', this.username);
      localStorage.setItem('role', this.username === 'admin' ? 'ADMIN' : 'USER');
      this.router.navigate(['/']);
    } else {
      this.errorMessage = 'Please enter username and password';
    }
  }

  loginAsAdmin(): void {
    this.username = 'admin';
    this.password = 'admin';
    this.login();
  }
}
