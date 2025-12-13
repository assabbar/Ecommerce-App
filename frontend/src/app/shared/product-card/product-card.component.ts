import { Component, Input, Output, EventEmitter, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { Product } from '../../model/product';
import { CartService } from '../../services/cart/cart.service';
import { FavoritesService } from '../../services/favorites/favorites.service';
import { ApiUrlPipe } from '../pipes/api-url.pipe';

@Component({
  selector: 'app-product-card',
  standalone: true,
  imports: [CommonModule, RouterModule, ApiUrlPipe],
  template: `
    <div class="product-card" (click)="viewProduct()">
      <div class="product-image-container">
        <img [src]="product.coverImage || product.image || 'assets/placeholder.png' | apiUrl" 
             [alt]="product.name"
             class="product-image">
        
        <!-- Favorite Icon -->
        <button class="favorite-btn" (click)="toggleFavorite($event)" [class.active]="isFavorite">
          <span class="heart-icon">{{ isFavorite ? '❤️' : '♡' }}</span>
        </button>
        
        <!-- Sale Badge or Brand Name -->
        @if (product.category) {
          <div class="brand-badge">
            {{ product.category | uppercase }}
          </div>
        }
      </div>
      
      <div class="product-info">
        <h2 class="product-name">{{ product.name }}</h2>
        
        @if (product.rating) {
          <div class="product-rating">
            <div class="stars">
              <span *ngFor="let i of [1,2,3,4,5]" 
                    [class.filled]="i <= (product.rating || 0)"
                    class="star">★</span>
            </div>
            <span class="review-count">({{ product.reviews }})</span>
          </div>
        }

        <div class="product-footer">
          <span class="price">{{ product.price | currency:'EUR':'symbol':'1.2-2' }}</span>
          <button class="add-to-cart-btn" 
                  (click)="onAddToCart()"
                  [disabled]="!product.inStock">
            Add To Cart
          </button>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .product-card {
      background: white;
      border-radius: 12px;
      overflow: hidden;
      transition: all 0.3s ease;
      height: 100%;
      display: flex;
      flex-direction: column;
      box-shadow: 0 8px 24px rgba(124, 58, 237, 0.2);
    }

    .product-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 15px 40px rgba(124, 58, 237, 0.4);
    }

    .product-image-container {
      position: relative;
      width: 100%;
      height: 350px;
      background: #f5f5f5;
      overflow: hidden;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .product-image {
      max-width: 100%;
      max-height: 100%;
      width: auto;
      height: auto;
      object-fit: contain;
      transition: transform 0.3s ease;
    }

    .product-card:hover .product-image {
      transform: scale(1.08);
    }

    /* Favorite Button */
    .favorite-btn {
      position: absolute;
      top: 12px;
      right: 12px;
      background: white;
      border: none;
      border-radius: 50%;
      width: 36px;
      height: 36px;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      transition: all 0.3s ease;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
      z-index: 10;
    }

    .favorite-btn:hover {
      transform: scale(1.1);
    }

    .favorite-btn.active {
      background: #ffe5e5;
    }

    .heart-icon {
      font-size: 20px;
      color: #000;
    }

    /* Brand Badge */
    .brand-badge {
      position: absolute;
      top: 12px;
      left: 12px;
      background: rgba(0, 0, 0, 0.7);
      color: white;
      padding: 6px 12px;
      border-radius: 6px;
      font-size: 11px;
      font-weight: 700;
      letter-spacing: 0.5px;
      z-index: 5;
    }

    .product-info {
      padding: 16px;
      flex: 1;
      display: flex;
      flex-direction: column;
    }

    .product-name {
      font-size: 14px;
      font-weight: 600;
      margin: 0 0 8px 0;
      color: #1a1a1a;
      line-height: 1.4;
      overflow: hidden;
      text-overflow: ellipsis;
      display: -webkit-box;
      -webkit-line-clamp: 2;
      -webkit-box-orient: vertical;
    }

    .product-rating {
      display: flex;
      align-items: center;
      gap: 6px;
      margin-bottom: 12px;
    }

    .stars {
      display: flex;
      gap: 1px;
    }

    .star {
      color: #e0e0e0;
      font-size: 14px;
    }

    .star.filled {
      color: #ffc107;
    }

    .review-count {
      font-size: 11px;
      color: #999;
    }

    .product-footer {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      margin-top: auto;
    }

    .price {
      font-size: 18px;
      font-weight: 700;
      color: #1a1a1a;
    }

    .add-to-cart-btn {
      background: #7c3aed;
      color: white;
      border: none;
      padding: 8px 16px;
      border-radius: 6px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.3s ease;
      font-size: 13px;
      white-space: nowrap;
    }

    .add-to-cart-btn:hover:not(:disabled) {
      background: #6d28d9;
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(124, 58, 237, 0.3);
    }

    .add-to-cart-btn:disabled {
      background: #ccc;
      cursor: not-allowed;
    }
  `]
})
export class ProductCardComponent implements OnInit {
  @Input() product!: Product;
  @Output() addToCart = new EventEmitter<Product>();
  private cartService = inject(CartService);
  private favoritesService = inject(FavoritesService);
  private router = inject(Router);
  isFavorite: boolean = false;

  ngOnInit(): void {
    if (this.product?.id) {
      this.isFavorite = this.favoritesService.isFavorite(this.product.id);
    }
  }

  viewProduct(): void {
    if (this.product.id) {
      this.router.navigate(['/product', this.product.id]);
    }
  }

  onAddToCart(): void {
    this.cartService.addToCart(this.product, 1);
    this.addToCart.emit(this.product);
  }

  toggleFavorite(event: Event): void {
    event.stopPropagation();
    this.favoritesService.toggleFavorite(this.product);
    if (this.product?.id) {
      this.isFavorite = this.favoritesService.isFavorite(this.product.id);
    }
  }
}
