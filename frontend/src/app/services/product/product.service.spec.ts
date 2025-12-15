import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { ProductService } from './product.service';

describe('ProductService', () => {
  let service: ProductService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [ProductService]
    });

    service = TestBed.inject(ProductService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should fetch all products', () => {
    const mockProducts = [
      { id: '1', skuCode: 'SKU001', name: 'Nike Air Jordan', description: 'Premium sneakers', price: 150 },
      { id: '2', skuCode: 'SKU002', name: 'Adidas Runner', description: 'Running shoes', price: 120 }
    ];

    service.getProducts().subscribe(products => {
      expect(products.length).toBe(2);
      expect(products).toEqual(mockProducts);
    });

    const req = httpMock.expectOne('http://localhost:9000/api/product');
    expect(req.request.method).toBe('GET');
    req.flush(mockProducts);
  });

  it('should fetch product by id', () => {
    const mockProduct = { id: '1', skuCode: 'SKU001', name: 'Nike Air Jordan', description: 'Premium sneakers', price: 150 };

    service.getProductById('1').subscribe(product => {
      expect(product).toEqual(mockProduct);
    });

    const req = httpMock.expectOne('http://localhost:9000/api/product/1');
    expect(req.request.method).toBe('GET');
    req.flush(mockProduct);
  });

  it('should create product', () => {
    const newProduct = { skuCode: 'SKU003', name: 'New Product', description: 'New description', price: 100 };
    const mockResponse = { id: '3', ...newProduct };

    service.createProduct(newProduct).subscribe(product => {
      expect(product).toEqual(mockResponse);
    });

    const req = httpMock.expectOne('http://localhost:9000/api/product');
    expect(req.request.method).toBe('POST');
    req.flush(mockResponse);
  });

  it('should update product', () => {
    const updatedProduct = { skuCode: 'SKU001', name: 'Updated Product', description: 'Updated description', price: 120 };
    const mockResponse = { id: '1', ...updatedProduct };

    service.updateProduct('1', updatedProduct).subscribe(product => {
      expect(product).toEqual(mockResponse);
    });

    const req = httpMock.expectOne('http://localhost:9000/api/product/1');
    expect(req.request.method).toBe('PUT');
    req.flush(mockResponse);
  });

  it('should delete product', () => {
    service.deleteProduct('1').subscribe();

    const req = httpMock.expectOne('http://localhost:9000/api/product/1');
    expect(req.request.method).toBe('DELETE');
    req.flush({});
  });

  afterEach(() => {
    httpMock.verify();
  });
});
