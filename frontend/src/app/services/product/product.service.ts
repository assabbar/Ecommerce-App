import {Injectable} from '@angular/core';
import {HttpClient} from "@angular/common/http";
import {Observable} from "rxjs";
import {Product} from "../../model/product";

@Injectable({
  providedIn: 'root'
})
export class ProductService {

  constructor(private httpClient: HttpClient) {
  }

  getProducts(): Observable<Array<Product>> {
    return this.httpClient.get<Array<Product>>('/api/product');
  }

  getProductById(id: number): Observable<Product> {
    return this.httpClient.get<Product>(`/api/product/${id}`);
  }

  addProduct(product: Product): Observable<Product> {
    return this.httpClient.post<Product>('/api/product', product);
  }

  updateProduct(id: number, product: Product): Observable<Product> {
    return this.httpClient.put<Product>(`/api/product/${id}`, product);
  }

  addProductWithImages(formData: FormData): Observable<Product> {
    return this.httpClient.post<Product>('/api/product/with-images', formData);
  }

  getAllProducts(): Observable<Array<Product>> {
    return this.getProducts();
  }

  deleteProduct(id: string): Observable<void> {
    return this.httpClient.delete<void>(`/api/product/${id}`);
  }
}
