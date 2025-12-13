import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule, FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { Location } from '@angular/common';
import { ProductService } from '../../services/product/product.service';
import { Product } from '../../model/product';
import { ApiUrlPipe } from '../../shared/pipes/api-url.pipe';

@Component({
  selector: 'app-edit-product',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, FormsModule, ApiUrlPipe],
  templateUrl: './edit-product.component.html',
  styleUrls: ['./edit-product.component.css']
})
export class EditProductComponent implements OnInit {
  editForm!: FormGroup;
  product: Product | null = null;
  productId: string = '';
  loading = true;
  error = '';
  selectedImages: string[] = [];
  newImagesBase64: string[] = [];
  coverImageFile: File | null = null;
  successMessage: string = '';

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private location: Location,
    private formBuilder: FormBuilder,
    private productService: ProductService
  ) {}

  ngOnInit(): void {
    this.initializeForm();
    this.getProductId();
  }

  private initializeForm(): void {
    this.editForm = this.formBuilder.group({
      name: ['', [Validators.required, Validators.minLength(3)]],
      description: ['', [Validators.required, Validators.minLength(10)]],
      price: [0, [Validators.required, Validators.min(0)]],
      category: ['', Validators.required],
      inStock: [0, [Validators.required, Validators.min(0)]],
      colors: [''],
      sizes: ['']
    });
  }

  private getProductId(): void {
    this.route.params.subscribe(params => {
      this.productId = params['id'];
      if (this.productId) {
        this.loadProduct();
      }
    });
  }

  private loadProduct(): void {
    this.productService.getProductById(this.productId).subscribe({
      next: (data: Product) => {
        this.product = data;
        this.populateForm(data);
        this.selectedImages = data.images || [];
        this.loading = false;
      },
      error: (err: any) => {
        this.error = 'Failed to load product details';
        this.loading = false;
      }
    });
  }

  private populateForm(product: Product): void {
    this.editForm.patchValue({
      name: product.name,
      description: product.description,
      price: product.price,
      category: product.category,
      inStock: product.inStock || 0,
      colors: product.colors ? product.colors.join(', ') : '',
      sizes: product.sizes ? product.sizes.join(', ') : ''
    });
  }

  onImageSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files) {
      Array.from(input.files).forEach(file => {
        const reader = new FileReader();
        reader.onload = (e) => {
          if (e.target?.result) {
            this.newImagesBase64.push(e.target.result as string);
          }
        };
        reader.readAsDataURL(file);
      });
    }
  }

  onCoverImageSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files[0]) {
      this.coverImageFile = input.files[0];
    }
  }

  removeImage(index: number): void {
    this.selectedImages.splice(index, 1);
  }

  removeNewImage(index: number): void {
    this.newImagesBase64.splice(index, 1);
  }

  goBack(): void {
    this.location.back();
  }

  onSubmit(): void {
    if (this.editForm.invalid) {
      this.error = 'Please fill in all required fields correctly';
      return;
    }

    const formValue = this.editForm.value;
    const updatedProduct: Product = {
      ...this.product,
      name: formValue.name,
      description: formValue.description,
      price: formValue.price,
      category: formValue.category,
      inStock: formValue.inStock,
      colors: formValue.colors ? formValue.colors.split(',').map((c: string) => c.trim()).filter((c: string) => c) : [],
      sizes: formValue.sizes ? formValue.sizes.split(',').map((s: string) => s.trim()).filter((s: string) => s) : [],
      images: [...this.selectedImages, ...this.newImagesBase64]
    } as Product;

    this.productService.updateProduct(this.productId, updatedProduct).subscribe({
      next: (response: Product) => {
        this.successMessage = '✓ Product updated successfully!';
        setTimeout(() => {
          this.location.back();
        }, 1500);
      },
      error: (err: any) => {
        this.error = 'Failed to update product: ' + (err.error?.message || 'Unknown error');
      }
    });
  }
}
