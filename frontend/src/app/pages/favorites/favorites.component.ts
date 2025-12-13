import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { Product } from '../../model/product';
import { FavoritesService } from '../../services/favorites/favorites.service';
import { CartService } from '../../services/cart/cart.service';
import { ApiUrlPipe } from '../../shared/pipes/api-url.pipe';
import { trigger, transition, style, animate } from '@angular/animations';

@Component({
  selector: 'app-favorites',
  standalone: true,
  imports: [CommonModule, RouterModule, ApiUrlPipe],
  animations: [
    trigger('fadeIn', [
      transition(':enter', [
        style({ opacity: 0, transform: 'translateY(20px)' }),
        animate('300ms ease-out', style({ opacity: 1, transform: 'translateY(0)' }))
      ])
    ])
  ],
  template: `
    <div class="favorites-container" [@fadeIn]>
      <div class="favorites-header">
        <h1>My Favorites</h1>
        <p class="favorite-count">{{ filteredFavorites.length }} items</p>
      </div>

      @if (favorites.length === 0) {
        <div class="empty-state">
          <div class="empty-icon">♡</div>
          <h2>No Favorites Yet</h2>
          <p>Start adding your favorite products to see them here</p>
          <button class="continue-btn" (click)="continueShopping()">
            Continue Shopping
          </button>
        </div>
      } @else {
        @if (filteredFavorites.length === 0) {
          <div class="empty-category">
            <p>No favorites in this category</p>
            <button class="continue-btn" (click)="continueShopping()">
              Continue Shopping
            </button>
          </div>
        } @else {
          <div class="favorites-grid">
            @for (product of filteredFavorites; track product.id) {
              <div class="favorite-card" [@fadeIn]>
                <div class="card-image-container">
                  <img [src]="product.coverImage || product.image || 'assets/placeholder.png' | apiUrl" 
                       [alt]="product.name"
                       class="card-image">
                  <button class="remove-btn" (click)="removeFavorite(product.id)" title="Remove from favorites">
                    ✕
                  </button>
                </div>
                
                <div class="card-content">
                  <h3 class="card-name">{{ product.name }}</h3>
                  <p class="card-category">{{ product.category }}</p>
                  
                  <div class="card-footer">
                    <span class="card-price">{{ product.price | currency:'EUR':'symbol':'1.2-2' }}</span>
                    <button class="add-cart-btn" 
                            (click)="addToCart(product)"
                            [disabled]="!product.inStock">
                      {{ product.inStock ? 'Add to Cart' : 'Out of Stock' }}
                    </button>
                  </div>
                </div>
              </div>
            }
          </div>
        }
      }
    </div>
  `,
  styles: [`
    .favorites-container {
      max-width: 1200px;
      margin: 0 auto;
      padding: 40px 20px;
    }

    .favorites-header {
      text-align: center;
      margin-bottom: 40px;
    }

    .favorites-header h1 {
      font-size: 32px;
      font-weight: 700;
      color: #1a1a1a;
      margin: 0 0 8px 0;
    }

    .favorite-count {
      font-size: 14px;
      color: #7c3aed;
      margin: 0;
    }

    .empty-state {
      text-align: center;
      padding: 80px 20px;
      background: linear-gradient(135deg, #f5f3ff 0%, #faf8ff 100%);
      border-radius: 16px;
    }

    .empty-icon {
      font-size: 64px;
      margin-bottom: 20px;
    }

    .empty-state h2 {
      font-size: 24px;
      font-weight: 600;
      color: #1a1a1a;
      margin: 0 0 12px 0;
    }

    .empty-state p {
      font-size: 14px;
      color: #666;
      margin: 0 0 24px 0;
    }

    .continue-btn {
      background: #7c3aed;
      color: white;
      border: none;
      padding: 12px 32px;
      border-radius: 8px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.3s ease;
    }

    .continue-btn:hover {
      background: #6d28d9;
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(124, 58, 237, 0.3);
    }

    .empty-category {
      text-align: center;
      padding: 60px 20px;
      background: linear-gradient(135deg, #f5f3ff 0%, #faf8ff 100%);
      border-radius: 16px;
    }

    .empty-category p {
      font-size: 16px;
      color: #666;
      margin: 0 0 20px 0;
    }

    .favorites-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
      gap: 24px;
    }

    .favorite-card {
      background: white;
      border-radius: 12px;
      overflow: hidden;
      transition: all 0.3s ease;
      box-shadow: 0 8px 24px rgba(124, 58, 237, 0.2);
      display: flex;
      flex-direction: column;
    }

    .favorite-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 15px 40px rgba(124, 58, 237, 0.4);
    }

    .card-image-container {
      position: relative;
      width: 100%;
      height: 280px;
      background: #f5f5f5;
      overflow: hidden;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .card-image {
      max-width: 100%;
      max-height: 100%;
      width: auto;
      height: auto;
      object-fit: contain;
      transition: transform 0.3s ease;
    }

    .favorite-card:hover .card-image {
      transform: scale(1.08);
    }

    .remove-btn {
      position: absolute;
      top: 12px;
      right: 12px;
      background: rgba(255, 255, 255, 0.95);
      border: none;
      border-radius: 50%;
      width: 32px;
      height: 32px;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      font-size: 18px;
      color: #e74c3c;
      transition: all 0.3s ease;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
    }

    .remove-btn:hover {
      background: #e74c3c;
      color: white;
      transform: scale(1.1);
    }

    .card-content {
      padding: 16px;
      flex: 1;
      display: flex;
      flex-direction: column;
    }

    .card-name {
      font-size: 14px;
      font-weight: 600;
      color: #1a1a1a;
      margin: 0 0 6px 0;
      line-height: 1.4;
      overflow: hidden;
      text-overflow: ellipsis;
      display: -webkit-box;
      -webkit-line-clamp: 2;
      -webkit-box-orient: vertical;
    }

    .card-category {
      font-size: 12px;
      color: #999;
      margin: 0 0 12px 0;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    .card-footer {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      margin-top: auto;
      padding-top: 12px;
      border-top: 1px solid #eee;
    }

    .card-price {
      font-size: 16px;
      font-weight: 700;
      color: #7c3aed;
    }

    .add-cart-btn {
      background: #7c3aed;
      color: white;
      border: none;
      padding: 8px 12px;
      border-radius: 6px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.3s ease;
      font-size: 12px;
      white-space: nowrap;
    }

    .add-cart-btn:hover:not(:disabled) {
      background: #6d28d9;
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(124, 58, 237, 0.3);
    }

    .add-cart-btn:disabled {
      background: #ccc;
      cursor: not-allowed;
    }

    @media (max-width: 768px) {
      .favorites-grid {
        grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
        gap: 16px;
      }

      .favorites-header h1 {
        font-size: 24px;
      }
    }
  `]
})
export class FavoritesComponent implements OnInit {
  favorites: Product[] = [];
  filteredFavorites: Product[] = [];
  selectedCategory: string = 'all';
  
  private favoritesService = inject(FavoritesService);
  private cartService = inject(CartService);
  private router = inject(Router);

  ngOnInit(): void {
    // Subscribe to favorites changes
    this.favoritesService.favorites$.subscribe(favorites => {
      this.favorites = favorites;
      this.filterByCategory();
    });

    // Listen to category changes from header
    window.addEventListener('categorySelected', (event: any) => {
      this.selectedCategory = event.detail;
      this.filterByCategory();
    });
  }

  private filterByCategory(): void {
    if (this.selectedCategory === 'all') {
      this.filteredFavorites = this.favorites;
    } else {
      this.filteredFavorites = this.favorites.filter(
        p => p.category === this.selectedCategory
      );
    }
  }

  removeFavorite(productId: string | undefined): void {
    if (productId) {
      this.favoritesService.removeFavorite(productId);
    }
  }

  addToCart(product: Product): void {
    this.cartService.addToCart(product, 1);
  }

  continueShopping(): void {
    this.router.navigate(['/']);
  }
}
