import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { OrderService } from './order.service';
import { Order } from '../../model/order';

describe('OrderService', () => {
  let service: OrderService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [OrderService]
    });

    service = TestBed.inject(OrderService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should place an order', () => {
    const mockOrder: Order = {
      skuCode: 'SKU001',
      price: 99.99,
      quantity: 2,
      userDetails: {
        email: 'test@example.com',
        firstName: 'John',
        lastName: 'Doe'
      }
    };

    service.orderProduct(mockOrder).subscribe(response => {
      expect(response).toEqual('Order Placed Successfully');
    });

    const req = httpMock.expectOne('http://localhost:9000/api/order');
    expect(req.request.method).toBe('POST');
    expect(req.request.body).toEqual(mockOrder);
    req.flush('Order Placed Successfully');
  });
});
