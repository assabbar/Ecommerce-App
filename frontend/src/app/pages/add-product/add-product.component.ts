import {Component, inject, OnInit} from '@angular/core';
import {FormBuilder, FormGroup, ReactiveFormsModule, Validators} from "@angular/forms";
import {Product} from "../../model/product";
import {ProductService} from "../../services/product/product.service";
import {CommonModule} from "@angular/common";
import {RouterModule} from "@angular/router";
import {FormsModule} from "@angular/forms";

interface ImagePreview {
  file: File;
  url: string;
  isCover: boolean;
}

@Component({
  selector: 'app-add-product',
  standalone: true,
  imports: [ReactiveFormsModule, CommonModule, RouterModule, FormsModule],
  templateUrl: './add-product.component.html',
  styleUrl: './add-product.component.css'
})
export class AddProductComponent implements OnInit {
  addProductForm: FormGroup;
  private readonly productService = inject(ProductService);
  productCreated = false;
  selectedImages: ImagePreview[] = [];
  isSubmitting = false;
  newColor = '';
  newSize = '';
  colors: string[] = [];
  sizes: string[] = [];

  constructor(private fb: FormBuilder) {
    this.addProductForm = this.fb.group({
      skuCode: ['', [Validators.required]],
      name: ['', [Validators.required]],
      description: ['', [Validators.required]],
      price: [0, [Validators.required]],
      category: ['Fashion', [Validators.required]],
      inStock: [10, [Validators.required, Validators.min(0)]]
    })
  }

  ngOnInit(): void {
    // Initialize with default colors and sizes
    this.colors = ['#7C3AED', '#EF4444', '#3B82F6', '#10B981'];
    this.sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  }

  onFileSelected(event: any): void {
    const files: FileList = event.target.files;
    if (files && files.length > 0) {
      for (let i = 0; i < files.length; i++) {
        const file = files[i];
        if (file.type.startsWith('image/')) {
          const reader = new FileReader();
          reader.onload = (e: any) => {
            this.selectedImages.push({
              file: file,
              url: e.target.result,
              isCover: this.selectedImages.length === 0 // First image is cover by default
            });
          };
          reader.readAsDataURL(file);
        }
      }
    }
  }

  setCoverImage(index: number): void {
    this.selectedImages.forEach((img, i) => {
      img.isCover = i === index;
    });
  }

  removeImage(index: number): void {
    this.selectedImages.splice(index, 1);
    // If removed image was cover, set first image as cover
    if (this.selectedImages.length > 0 && !this.selectedImages.some(img => img.isCover)) {
      this.selectedImages[0].isCover = true;
    }
  }

  addColor(): void {
    console.log('newColor value:', this.newColor, 'colors:', this.colors);
    if (this.newColor && !this.colors.includes(this.newColor)) {
      this.colors.push(this.newColor);
      this.newColor = '';
      console.log('Color added. colors now:', this.colors);
    } else {
      console.log('Color not added - either empty or already exists');
    }
  }

  removeColor(index: number): void {
    this.colors.splice(index, 1);
  }

  addSize(): void {
    console.log('newSize value:', this.newSize, 'sizes:', this.sizes);
    if (this.newSize && !this.sizes.includes(this.newSize)) {
      this.sizes.push(this.newSize.toUpperCase());
      this.newSize = '';
      console.log('Size added. sizes now:', this.sizes);
    } else {
      console.log('Size not added - either empty or already exists');
    }
  }

  removeSize(index: number): void {
    this.sizes.splice(index, 1);
  }

  onSubmit(): void {
    if (this.addProductForm.valid) {
      this.isSubmitting = true;
      
      // Prepare images as base64
      const images: string[] = [];
      let coverImage = '';
      
      this.selectedImages.forEach((img) => {
        images.push(img.url); // img.url is already base64 from FileReader
        if (img.isCover) {
          coverImage = img.url;
        }
      });

      const product: Product = {
        skuCode: this.addProductForm.get('skuCode')?.value,
        name: this.addProductForm.get('name')?.value,
        description: this.addProductForm.get('description')?.value,
        price: this.addProductForm.get('price')?.value,
        category: this.addProductForm.get('category')?.value,
        inStock: this.addProductForm.get('inStock')?.value,
        images: images.length > 0 ? images : undefined,
        coverImage: coverImage || (images.length > 0 ? images[0] : undefined),
        colors: this.colors.length > 0 ? this.colors : undefined,
        sizes: this.sizes.length > 0 ? this.sizes : undefined
      };

      this.productService.createProduct(product).subscribe({
        next: (product) => {
          this.productCreated = true;
          this.isSubmitting = false;
          this.addProductForm.reset();
          this.selectedImages = [];
          this.colors = [];
          this.sizes = [];
          console.log('Product created successfully:', product);
          setTimeout(() => {
            this.productCreated = false;
            window.location.href = '/admin'; // Redirect to admin dashboard
          }, 2000);
        },
        error: (error) => {
          console.error('Error creating product:', error);
          this.isSubmitting = false;
          alert('Error creating product: ' + (error.message || 'Unknown error'));
        }
      });
    } else {
      alert('Please fill in all required fields');
    }
  }

  get skuCode() {
    return this.addProductForm.get('skuCode');
  }

  get name() {
    return this.addProductForm.get('name');
  }

  get description() {
    return this.addProductForm.get('description');
  }

  get price() {
    return this.addProductForm.get('price');
  }

  get category() {
    return this.addProductForm.get('category');
  }

  get inStock() {
    return this.addProductForm.get('inStock');
  }
}
