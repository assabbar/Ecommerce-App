import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, BehaviorSubject } from 'rxjs';
import { tap } from 'rxjs/operators';

export interface User {
  id?: string;
  username: string;
  email?: string;
  role: 'admin' | 'user';
  token?: string;
}

@Injectable({
  providedIn: 'root'
})
export class SimpleAuthService {
  private apiUrl = 'http://localhost:9000/api/auth';
  private userSubject = new BehaviorSubject<User | null>(this.loadUserFromStorage());
  public user$ = this.userSubject.asObservable();
  
  private isAdminSubject = new BehaviorSubject<boolean>(this.isAdmin());
  public isAdmin$ = this.isAdminSubject.asObservable();

  constructor(private http: HttpClient) {
    this.checkAuth();
  }

  private loadUserFromStorage(): User | null {
    const userStr = localStorage.getItem('user');
    return userStr ? JSON.parse(userStr) : null;
  }

  private isAdmin(): boolean {
    const user = this.loadUserFromStorage();
    return (user?.role === 'admin') || false;
  }

  checkAuth(): void {
    const user = this.loadUserFromStorage();
    if (user) {
      this.userSubject.next(user);
      this.isAdminSubject.next(user.role === 'admin');
    }
  }

  login(username: string, password: string): Observable<User> {
    return this.http.post<User>(`${this.apiUrl}/login`, { username, password })
      .pipe(
        tap(user => {
          localStorage.setItem('user', JSON.stringify(user));
          localStorage.setItem('token', user.token || '');
          this.userSubject.next(user);
          this.isAdminSubject.next(user.role === 'admin');
        })
      );
  }

  register(username: string, email: string, password: string, confirmPassword: string): Observable<User> {
    return this.http.post<User>(`${this.apiUrl}/register`, {
      username,
      email,
      password,
      confirmPassword
    }).pipe(
      tap(user => {
        localStorage.setItem('user', JSON.stringify(user));
        localStorage.setItem('token', user.token || '');
        this.userSubject.next(user);
        this.isAdminSubject.next(user.role === 'admin');
      })
    );
  }

  logout(): void {
    localStorage.removeItem('user');
    localStorage.removeItem('token');
    this.userSubject.next(null);
    this.isAdminSubject.next(false);
  }

  isAuthenticated(): boolean {
    return !!this.loadUserFromStorage();
  }

  getUser(): User | null {
    return this.userSubject.value;
  }

  getToken(): string | null {
    return localStorage.getItem('token');
  }
}
