import { Injectable, inject } from '@angular/core';
import { Router, CanActivateFn } from '@angular/router';
import { SimpleAuthService } from '../services/auth/simple-auth.service';

export const adminGuard: CanActivateFn = (route, state) => {
  const authService = inject(SimpleAuthService);
  const router = inject(Router);

  const user = authService.getUser();
  if (user && user.role === 'admin') {
    return true;
  }
  
  router.navigate(['/login']);
  return false;
};
