import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { ProductService } from '../../services/product/product.service';
import { Product } from '../../model/product';
import { SimpleAuthService } from '../../services/auth/simple-auth.service';
import { ModalService } from '../../services/modal.service';
import { ConfirmModalComponent } from '../../shared/confirm-modal/confirm-modal.component';
import { ApiUrlPipe } from '../../shared/pipes/api-url.pipe';

@Component({
  selector: 'app-admin-dashboard',
  standalone: true,
  imports: [CommonModule, RouterModule, ConfirmModalComponent, ApiUrlPipe],
  templateUrl: './admin-dashboard.component.html',
  styleUrl: './admin-dashboard.component.css'
})
export class AdminDashboardComponent implements OnInit {
  private productService = inject(ProductService);
  private router = inject(Router);
  private authService = inject(SimpleAuthService);
  private modalService = inject(ModalService);

  products: Product[] = [];
  selectedTab = 'products'; // products, add-product, inventory, orders
  totalProducts = 0;
  lowStockProducts = 0;
  totalOrders = 0;

  ngOnInit(): void {
    // Vérifier si admin
    this.authService.user$.subscribe(user => {
      if (!user || user.role !== 'admin') {
        // Rediriger vers home si pas admin
        this.router.navigate(['/']);
      }
    });

    this.loadProducts();
  }

  isLowStock(stock: number | undefined): boolean {
    return (stock ?? 0) < 10;
  }

  loadProducts(): void {
    this.productService.getProducts().subscribe({
      next: (products: Product[]) => {
        this.products = products;
        this.totalProducts = products.length;
        this.lowStockProducts = 0; // TODO: calculer depuis inventory-service
      },
      error: (error: any) => console.error('Error loading products:', error)
    });
  }

  selectTab(tab: string): void {
    this.selectedTab = tab;
    if (tab === 'add-product') {
      this.router.navigate(['/add-product']);
    }
  }

  editProduct(product: Product): void {
    // Navigate to edit product page
    this.router.navigate(['/edit-product', product.id]);
  }

  deleteProduct(productId: string, productName?: string): void {
    this.modalService.openConfirm({
      title: 'Delete Product',
      message: `Are you sure you want to delete "${productName || 'this product'}"? This action cannot be undone.`,
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDangerous: true
    }).subscribe(confirmed => {
      if (confirmed) {
        this.productService.deleteProduct(productId).subscribe({
          next: () => {
            console.log('Product deleted successfully');
            this.loadProducts();
          },
          error: (error: any) => {
            console.error('Error deleting product:', error);
            alert('Error deleting product. Please try again.');
          }
        });
      }
    });
  }

  viewInventory(product: Product): void {
    // Show current stock
    alert(`Stock Details for: ${product.name}\n\nCurrent Stock: ${product.inStock || 0} units\n\nFull Inventory Management Coming Soon`);
  }
}
