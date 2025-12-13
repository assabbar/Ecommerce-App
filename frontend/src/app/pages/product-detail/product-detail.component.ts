import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { Product } from '../../model/product';
import { ProductService } from '../../services/product/product.service';
import { CartService } from '../../services/cart/cart.service';
import { FavoritesService } from '../../services/favorites/favorites.service';
import { ApiUrlPipe } from '../../shared/pipes/api-url.pipe';

@Component({
  selector: 'app-product-detail',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule, ApiUrlPipe],
  templateUrl: './product-detail.component.html',
  styleUrl: './product-detail.component.css'
})
export class ProductDetailComponent implements OnInit {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private productService = inject(ProductService);
  private cartService = inject(CartService);
  private favoritesService = inject(FavoritesService);

  product: Product | null = null;
  selectedImage: string = '';
  selectedColor: string = '';
  selectedSize: string = '';
  quantity: number = 1;
  loading: boolean = true;
  error: string = '';
  isFavorite: boolean = false;

  ngOnInit(): void {
    const productId = this.route.snapshot.paramMap.get('id');
    if (productId) {
      this.loadProduct(productId);
    }
  }

  loadProduct(id: string): void {
    this.productService.getProductById(id).subscribe({
      next: (product) => {
        this.product = product;
        if (product.id) {
          this.isFavorite = this.favoritesService.isFavorite(product.id);
        }
        // Set the selected image to coverImage or first image from images array
        if (product.coverImage) {
          this.selectedImage = product.coverImage;
        } else if (product.images && product.images.length > 0) {
          this.selectedImage = product.images[0];
        } else {
          this.selectedImage = product.image || '';
        }
        // Set default color and size if available
        if (product.colors && product.colors.length > 0) {
          this.selectedColor = product.colors[0];
        }
        if (product.sizes && product.sizes.length > 0) {
          this.selectedSize = product.sizes[0];
        }
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading product:', error);
        this.error = 'Failed to load product details. Please try again.';
        this.loading = false;
      }
    });
  }

  selectImage(image: string): void {
    this.selectedImage = image;
  }

  selectColor(color: string): void {
    this.selectedColor = color;
  }

  selectSize(size: string): void {
    this.selectedSize = size;
  }

  decreaseQuantity(): void {
    if (this.quantity > 1) {
      this.quantity--;
    }
  }

  increaseQuantity(): void {
    const maxQuantity = this.product?.inStock || 1;
    if (this.quantity < maxQuantity) {
      this.quantity++;
    }
  }

  addToCart(): void {
    if (this.product) {
      this.cartService.addToCart(this.product, this.quantity);
      // Optional: Show success message or navigate to cart
      alert(`${this.product.name} added to cart!`);
    }
  }

  toggleFavorite(): void {
    if (this.product) {
      this.favoritesService.toggleFavorite(this.product);
      if (this.product.id) {
        this.isFavorite = this.favoritesService.isFavorite(this.product.id);
      }
    }
  }

  goBack(): void {
    this.router.navigate(['/']);
  }
}
