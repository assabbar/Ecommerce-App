import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { CartService, CartItem } from '../../services/cart/cart.service';
import { ApiUrlPipe } from '../../shared/pipes/api-url.pipe';

@Component({
  selector: 'app-cart',
  standalone: true,
  imports: [CommonModule, RouterModule, ApiUrlPipe],
  template: `
    <div class="cart-container">
      <div class="cart-header">
        <h1>Shopping Cart</h1>
        <button class="back-btn" routerLink="/">← Continue Shopping</button>
      </div>

      <div class="cart-content">
        @if (cartItems.length > 0) {
          <div class="cart-items">
            @for (item of cartItems; track item.product.id) {
              <div class="cart-item">
                <img [src]="item.product.coverImage || item.product.image || 'assets/placeholder.png' | apiUrl" 
                     [alt]="item.product.name"
                     class="item-image">
                
                <div class="item-details">
                  <h3>{{ item.product.name }}</h3>
                  <p>{{ item.product.category }}</p>
                  <span class="item-price">{{ item.product.price | currency }}</span>
                </div>

                <div class="item-quantity">
                  <button (click)="decreaseQuantity(item.product.id!)">−</button>
                  <input type="number" [value]="item.quantity" disabled>
                  <button (click)="increaseQuantity(item.product.id!)">+</button>
                </div>

                <div class="item-total">
                  {{ (item.product.price * item.quantity) | currency }}
                </div>

                <button class="remove-btn" (click)="removeItem(item.product.id!)">
                  🗑️
                </button>
              </div>
            }
          </div>

          <div class="cart-summary">
            <h2>Order Summary</h2>
            <div class="summary-row">
              <span>Subtotal</span>
              <span>{{ cartTotal | currency }}</span>
            </div>
            <div class="summary-row">
              <span>Shipping</span>
              <span>Free</span>
            </div>
            <div class="summary-row total">
              <span>Total</span>
              <span>{{ cartTotal | currency }}</span>
            </div>
            <button class="checkout-btn">Proceed to Checkout</button>
          </div>
        } @else {
          <div class="empty-cart">
            <h2>Your cart is empty</h2>
            <p>Add some products to get started!</p>
            <button class="continue-btn" routerLink="/">Start Shopping</button>
          </div>
        }
      </div>
    </div>
  `,
  styles: [`
    .cart-container {
      max-width: 1200px;
      margin: 0 auto;
      padding: 20px;
    }

    .cart-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 30px;
    }

    .cart-header h1 {
      font-size: 32px;
      font-weight: 700;
      margin: 0;
    }

    .back-btn {
      background: transparent;
      border: 1px solid #ddd;
      padding: 10px 16px;
      border-radius: 6px;
      cursor: pointer;
      font-size: 14px;
      transition: all 0.3s ease;
    }

    .back-btn:hover {
      border-color: #7c3aed;
      color: #7c3aed;
    }

    .cart-content {
      display: grid;
      grid-template-columns: 1fr 350px;
      gap: 30px;
    }

    .cart-items {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    .cart-item {
      display: grid;
      grid-template-columns: 100px 1fr 120px 120px 50px;
      gap: 20px;
      align-items: center;
      padding: 16px;
      border: 1px solid #eee;
      border-radius: 8px;
      background: white;
    }

    .item-image {
      width: 100px;
      height: 100px;
      object-fit: cover;
      border-radius: 6px;
    }

    .item-details {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }

    .item-details h3 {
      margin: 0;
      font-size: 16px;
      font-weight: 600;
    }

    .item-details p {
      margin: 0;
      font-size: 13px;
      color: #999;
    }

    .item-price {
      font-size: 14px;
      font-weight: 600;
      color: #7c3aed;
    }

    .item-quantity {
      display: flex;
      align-items: center;
      border: 1px solid #eee;
      border-radius: 6px;
      overflow: hidden;
    }

    .item-quantity button {
      background: transparent;
      border: none;
      padding: 8px 12px;
      cursor: pointer;
      font-size: 16px;
      transition: background 0.3s;
    }

    .item-quantity button:hover {
      background: #f5f5f5;
    }

    .item-quantity input {
      border: none;
      width: 40px;
      text-align: center;
      font-weight: 600;
    }

    .item-total {
      font-weight: 600;
      font-size: 16px;
    }

    .remove-btn {
      background: transparent;
      border: none;
      cursor: pointer;
      font-size: 18px;
      transition: transform 0.3s;
    }

    .remove-btn:hover {
      transform: scale(1.2);
    }

    .cart-summary {
      background: white;
      border: 1px solid #eee;
      border-radius: 8px;
      padding: 24px;
      height: fit-content;
      position: sticky;
      top: 20px;
    }

    .cart-summary h2 {
      font-size: 20px;
      margin: 0 0 16px 0;
      font-weight: 600;
    }

    .summary-row {
      display: flex;
      justify-content: space-between;
      padding: 12px 0;
      border-bottom: 1px solid #eee;
      font-size: 14px;
    }

    .summary-row.total {
      border: none;
      font-weight: 700;
      font-size: 16px;
      padding-top: 16px;
      padding-bottom: 20px;
    }

    .checkout-btn {
      width: 100%;
      background: linear-gradient(135deg, #7c3aed 0%, #6d28d9 100%);
      color: white;
      border: none;
      padding: 12px;
      border-radius: 6px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.3s ease;
    }

    .checkout-btn:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(124, 58, 237, 0.4);
    }

    .empty-cart {
      grid-column: 1 / -1;
      text-align: center;
      padding: 60px 20px;
    }

    .empty-cart h2 {
      font-size: 28px;
      margin: 0 0 8px 0;
    }

    .empty-cart p {
      color: #666;
      margin-bottom: 20px;
    }

    .continue-btn {
      background: linear-gradient(135deg, #7c3aed 0%, #6d28d9 100%);
      color: white;
      border: none;
      padding: 12px 24px;
      border-radius: 6px;
      cursor: pointer;
      font-weight: 600;
    }
  `]
})
export class CartComponent implements OnInit {
  private cartService = inject(CartService);
  cartItems: CartItem[] = [];
  cartTotal: number = 0;

  ngOnInit(): void {
    this.cartService.cart$.subscribe(items => {
      this.cartItems = items;
      this.cartTotal = this.cartService.getCartTotal();
    });
  }

  increaseQuantity(productId: string): void {
    const item = this.cartItems.find(i => i.product.id === productId);
    if (item) {
      this.cartService.updateQuantity(productId, item.quantity + 1);
    }
  }

  decreaseQuantity(productId: string): void {
    const item = this.cartItems.find(i => i.product.id === productId);
    if (item && item.quantity > 1) {
      this.cartService.updateQuantity(productId, item.quantity - 1);
    }
  }

  removeItem(productId: string): void {
    this.cartService.removeFromCart(productId);
  }
}
