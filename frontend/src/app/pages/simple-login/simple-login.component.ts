import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { SimpleAuthService } from '../../services/auth/simple-auth.service';

@Component({
  selector: 'app-simple-login',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './simple-login.component.html',
  styleUrl: './simple-login.component.css'
})
export class SimpleLoginComponent {
  private authService = inject(SimpleAuthService);
  private router = inject(Router);

  // Login state
  username = '';
  password = '';
  loading = false;
  error = '';
  activeTab: 'login' | 'register' = 'login';
  showLoginPassword = false;

  // Register state
  registerUsername = '';
  registerEmail = '';
  registerPassword = '';
  registerConfirmPassword = '';
  registerError = '';
  registerSuccess = '';
  showRegisterPassword = false;
  showRegisterConfirm = false;

  ngOnInit(): void {
    if (this.authService.isAuthenticated()) {
      this.router.navigate(['/']);
    }
  }

  login(): void {
    if (!this.username || !this.password) {
      this.error = 'Username and password required';
      return;
    }

    this.loading = true;
    this.error = '';

    this.authService.login(this.username, this.password).subscribe({
      next: (user) => {
        this.loading = false;
        this.router.navigate(['/']);
      },
      error: (err) => {
        this.loading = false;
        this.error = err.error || 'Login failed';
        console.error('Login error:', err);
      }
    });
  }

  register(): void {
    if (!this.registerUsername || !this.registerEmail || !this.registerPassword) {
      this.registerError = 'All fields required';
      return;
    }

    if (this.registerPassword !== this.registerConfirmPassword) {
      this.registerError = 'Passwords do not match';
      return;
    }

    this.loading = true;
    this.registerError = '';
    this.registerSuccess = '';

    this.authService.register(
      this.registerUsername,
      this.registerEmail,
      this.registerPassword,
      this.registerConfirmPassword
    ).subscribe({
      next: (user) => {
        this.loading = false;
        this.registerSuccess = 'Account created successfully! Logging in...';
        setTimeout(() => {
          this.router.navigate(['/']);
        }, 1500);
      },
      error: (err) => {
        this.loading = false;
        this.registerError = err.error || 'Registration failed';
        console.error('Register error:', err);
      }
    });
  }

  switchTab(tab: 'login' | 'register'): void {
    this.activeTab = tab;
    this.error = '';
    this.registerError = '';
    this.registerSuccess = '';
  }

  toggleLoginPassword(): void {
    this.showLoginPassword = !this.showLoginPassword;
  }

  toggleRegisterPassword(): void {
    this.showRegisterPassword = !this.showRegisterPassword;
  }

  toggleRegisterConfirm(): void {
    this.showRegisterConfirm = !this.showRegisterConfirm;
  }
}


