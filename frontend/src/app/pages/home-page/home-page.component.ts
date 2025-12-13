import {Component, inject, OnInit} from '@angular/core';
import {Product} from "../../model/product";
import {ProductService} from "../../services/product/product.service";
import {CommonModule} from "@angular/common";
import {RouterModule, Router} from "@angular/router";
import {Order} from "../../model/order";
import {OrderService} from "../../services/order/order.service";
import {ProductCardComponent} from "../../shared/product-card/product-card.component";
import {SimpleAuthService} from "../../services/auth/simple-auth.service";

@Component({
  selector: 'app-homepage',
  templateUrl: './home-page.component.html',
  standalone: true,
  imports: [
    CommonModule,
    RouterModule,
    ProductCardComponent
  ],
  styleUrl: './home-page.component.css'
})
export class HomePageComponent implements OnInit {
  private readonly authService = inject(SimpleAuthService);
  private readonly productService = inject(ProductService);
  private readonly orderService = inject(OrderService);
  private readonly router = inject(Router);
  
  isAuthenticated = false;
  isAdmin = false;
  products: Array<Product> = [];
  filteredProducts: Array<Product> = [];
  selectedCategory: string = 'all';
  categories: string[] = ['Fashion', 'Electronics', 'Home', 'Sports', 'Books'];
  orderSuccess = false;
  orderFailed = false;
  quantityIsNull = false;

  ngOnInit(): void {
    // Subscribe to admin status
    this.authService.isAdmin$.subscribe(isAdmin => {
      this.isAdmin = isAdmin;
      this.loadProducts();
    });

    // Subscribe to authentication status
    this.authService.user$.subscribe(user => {
      this.isAuthenticated = !!user;
      this.loadProducts();
    });

    // Listen to category changes from header
    window.addEventListener('categorySelected', ((event: CustomEvent) => {
      this.selectCategory(event.detail);
    }) as EventListener);
  }

  loadProducts(): void {
    if (this.isAuthenticated) {
      this.productService.getProducts()
        .subscribe(products => {
          this.products = products;
          this.products = this.products.map(p => ({
            ...p,
            image: p.image || p.coverImage || `https://via.placeholder.com/300x300?text=${p.name}`,
            category: p.category || 'Fashion',
            rating: p.rating || (Math.random() * 2 + 3.5),
            reviews: p.reviews || Math.floor(Math.random() * 200 + 10),
            inStock: p.inStock ?? 0
          }));
          this.filterProducts();
        });
    }
  }

  filterProducts(): void {
    if (this.selectedCategory === 'all') {
      this.filteredProducts = this.products;
    } else {
      this.filteredProducts = this.products.filter(p => 
        (p.category || 'Fashion').toLowerCase() === this.selectedCategory.toLowerCase()
      );
    }
  }

  selectCategory(category: string): void {
    this.selectedCategory = category;
    this.filterProducts();
  }

  goToCreateProductPage(): void {
    this.router.navigateByUrl('/add-product');
  }

  viewUserShop(): void {
    window.location.reload();
  }

  orderProduct(product: Product, quantity: string): void {
    const user = this.authService.getUser();
    if (!user) return;

    if (!quantity) {
      this.orderFailed = true;
      this.orderSuccess = false;
      this.quantityIsNull = true;
    } else {
      const order: Order = {
        skuCode: product.skuCode,
        price: product.price,
        quantity: Number(quantity),
        userDetails: {
          email: user.email || user.username + '@mlk.shop',
          firstName: user.username,
          lastName: ''
        }
      };

      this.orderService.orderProduct(order).subscribe(() => {
        this.orderSuccess = true;
      }, error => {
        this.orderFailed = true;
      });
    }
  }
}
