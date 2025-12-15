package com.techie.microservices.product.service;

import com.techie.microservices.product.dto.ProductRequest;
import com.techie.microservices.product.dto.ProductResponse;
import com.techie.microservices.product.model.Product;
import com.techie.microservices.product.repository.ProductRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ProductServiceTest {

    @Mock
    private ProductRepository productRepository;

    @Mock
    private ImageService imageService;

    @InjectMocks
    private ProductService productService;

    private Product testProduct;
    private ProductRequest testProductRequest;

    @BeforeEach
    void setUp() {
        testProduct = Product.builder()
                .id("test-id-123")
                .name("Test Product")
                .description("Test Description")
                .price(BigDecimal.valueOf(99.99))
                .build();

        testProductRequest = new ProductRequest(
                "test-id-123",
                "Test Product",
                "Test Description",
                BigDecimal.valueOf(99.99),
                null
        );
    }

    @Test
    void createProduct_ShouldReturnProductResponse() {
        // Given
        when(productRepository.save(any(Product.class))).thenReturn(testProduct);

        // When
        ProductResponse response = productService.createProduct(testProductRequest);

        // Then
        assertNotNull(response);
        assertEquals("Test Product", response.name());
        assertEquals("Test Description", response.description());
        assertEquals(BigDecimal.valueOf(99.99), response.price());
        verify(productRepository, times(1)).save(any(Product.class));
    }

    @Test
    void getAllProducts_ShouldReturnListOfProducts() {
        // Given
        List<Product> products = Arrays.asList(testProduct);
        when(productRepository.findAll()).thenReturn(products);

        // When
        List<ProductResponse> responses = productService.getAllProducts();

        // Then
        assertNotNull(responses);
        assertEquals(1, responses.size());
        assertEquals("Test Product", responses.get(0).name());
        verify(productRepository, times(1)).findAll();
    }

    @Test
    void getProductById_WhenProductExists_ShouldReturnProduct() {
        // Given
        when(productRepository.findById("test-id-123")).thenReturn(Optional.of(testProduct));

        // When
        ProductResponse response = productService.getProductById("test-id-123");

        // Then
        assertNotNull(response);
        assertEquals("Test Product", response.name());
        verify(productRepository, times(1)).findById("test-id-123");
    }

    @Test
    void getProductById_WhenProductNotExists_ShouldThrowException() {
        // Given
        when(productRepository.findById("non-existent")).thenReturn(Optional.empty());

        // When & Then
        assertThrows(RuntimeException.class, () -> {
            productService.getProductById("non-existent");
        });
        verify(productRepository, times(1)).findById("non-existent");
    }

    @Test
    void deleteProduct_ShouldCallRepositoryDelete() {
        // Given
        String productId = "test-id-123";

        // When
        productService.deleteProduct(productId);

        // Then
        verify(productRepository, times(1)).deleteById(productId);
    }
}
