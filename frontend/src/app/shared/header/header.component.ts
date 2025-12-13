import {Component, inject, OnInit} from '@angular/core';
import {CommonModule} from "@angular/common";
import {Router, RouterModule} from "@angular/router";
import {CartService} from "../../services/cart/cart.service";
import {SimpleAuthService} from "../../services/auth/simple-auth.service";

@Component({
  selector: 'app-header',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './header.component.html',
  styleUrl: './header.component.css'
})
export class HeaderComponent implements OnInit {

  private readonly authService = inject(SimpleAuthService);
  private readonly cartService = inject(CartService);
  private readonly router = inject(Router);
  
  isAuthenticated = false;
  isAdmin = false;
  username = "";
  cartCount = 0;
  selectedCategory = 'all';

  ngOnInit(): void {
    // Subscribe to auth status
    this.authService.user$.subscribe(user => {
      this.isAuthenticated = !!user;
      this.username = user?.username || '';
    });

    // Subscribe to admin status
    this.authService.isAdmin$.subscribe(isAdmin => {
      this.isAdmin = isAdmin;
    });

    // Cart updates (only for non-admins)
    this.cartService.cart$.subscribe(() => {
      if (!this.isAdmin) {
        this.cartCount = this.cartService.getCartCount();
      }
    });
  }

  login(): void {
    this.router.navigate(['/login']);
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/login']);
  }

  selectCategory(category: string): void {
    this.selectedCategory = category;
    window.dispatchEvent(new CustomEvent('categorySelected', { detail: category }));
  }
}
