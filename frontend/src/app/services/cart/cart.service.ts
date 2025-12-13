import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { Product } from '../../model/product';

export interface CartItem {
  product: Product;
  quantity: number;
}

@Injectable({
  providedIn: 'root'
})
export class CartService {
  private cart = new BehaviorSubject<CartItem[]>([]);
  public cart$ = this.cart.asObservable();

  constructor() {
    this.loadCart();
  }

  addToCart(product: Product, quantity: number = 1): void {
    const currentCart = this.cart.value;
    const existingItem = currentCart.find(item => item.product.id === product.id);

    if (existingItem) {
      existingItem.quantity += quantity;
    } else {
      currentCart.push({ product, quantity });
    }

    this.cart.next([...currentCart]);
    this.saveCart();
  }

  removeFromCart(productId: string): void {
    const updatedCart = this.cart.value.filter(item => item.product.id !== productId);
    this.cart.next(updatedCart);
    this.saveCart();
  }

  updateQuantity(productId: string, quantity: number): void {
    const currentCart = this.cart.value;
    const item = currentCart.find(i => i.product.id === productId);
    if (item) {
      item.quantity = Math.max(0, quantity);
      this.cart.next([...currentCart]);
      this.saveCart();
    }
  }

  getCartItems(): CartItem[] {
    return this.cart.value;
  }

  getCartTotal(): number {
    return this.cart.value.reduce((total, item) => total + (item.product.price * item.quantity), 0);
  }

  getCartCount(): number {
    return this.cart.value.reduce((count, item) => count + item.quantity, 0);
  }

  clearCart(): void {
    this.cart.next([]);
    localStorage.removeItem('cart');
  }

  private saveCart(): void {
    localStorage.setItem('cart', JSON.stringify(this.cart.value));
  }

  private loadCart(): void {
    const savedCart = localStorage.getItem('cart');
    if (savedCart) {
      this.cart.next(JSON.parse(savedCart));
    }
  }
}
