package com.techie.microservices.inventory.service;

import com.techie.microservices.inventory.repository.InventoryRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class InventoryServiceTest {

    @Mock
    private InventoryRepository inventoryRepository;

    @InjectMocks
    private InventoryService inventoryService;

    private String testSkuCode;
    private Integer testQuantity;

    @BeforeEach
    void setUp() {
        testSkuCode = "SKU-001";
        testQuantity = 10;
    }

    @Test
    void isInStock_WhenProductAvailableWithSufficientQuantity_ShouldReturnTrue() {
        // Arrange
        when(inventoryRepository.existsBySkuCodeAndQuantityIsGreaterThanEqual(testSkuCode, testQuantity))
                .thenReturn(true);

        // Act
        boolean result = inventoryService.isInStock(testSkuCode, testQuantity);

        // Assert
        assertTrue(result);
        verify(inventoryRepository).existsBySkuCodeAndQuantityIsGreaterThanEqual(testSkuCode, testQuantity);
    }

    @Test
    void isInStock_WhenProductNotAvailable_ShouldReturnFalse() {
        // Arrange
        when(inventoryRepository.existsBySkuCodeAndQuantityIsGreaterThanEqual(testSkuCode, testQuantity))
                .thenReturn(false);

        // Act
        boolean result = inventoryService.isInStock(testSkuCode, testQuantity);

        // Assert
        assertFalse(result);
        verify(inventoryRepository).existsBySkuCodeAndQuantityIsGreaterThanEqual(testSkuCode, testQuantity);
    }

    @Test
    void isInStock_WhenQuantityIsZero_ShouldCallRepository() {
        // Arrange
        Integer zeroQuantity = 0;
        when(inventoryRepository.existsBySkuCodeAndQuantityIsGreaterThanEqual(testSkuCode, zeroQuantity))
                .thenReturn(true);

        // Act
        boolean result = inventoryService.isInStock(testSkuCode, zeroQuantity);

        // Assert
        assertTrue(result);
        verify(inventoryRepository).existsBySkuCodeAndQuantityIsGreaterThanEqual(testSkuCode, zeroQuantity);
    }

    @Test
    void isInStock_WhenQuantityIsLarge_ShouldReturnFalse() {
        // Arrange
        Integer largeQuantity = 1000;
        when(inventoryRepository.existsBySkuCodeAndQuantityIsGreaterThanEqual(testSkuCode, largeQuantity))
                .thenReturn(false);

        // Act
        boolean result = inventoryService.isInStock(testSkuCode, largeQuantity);

        // Assert
        assertFalse(result);
        verify(inventoryRepository).existsBySkuCodeAndQuantityIsGreaterThanEqual(testSkuCode, largeQuantity);
    }

    @Test
    void isInStock_WithDifferentSkuCodes_ShouldReturnCorrectResults() {
        // Arrange
        String skuCode1 = "SKU-LAPTOP-001";
        String skuCode2 = "SKU-MOUSE-001";
        when(inventoryRepository.existsBySkuCodeAndQuantityIsGreaterThanEqual(skuCode1, 5)).thenReturn(true);
        when(inventoryRepository.existsBySkuCodeAndQuantityIsGreaterThanEqual(skuCode2, 5)).thenReturn(false);

        // Act
        boolean result1 = inventoryService.isInStock(skuCode1, 5);
        boolean result2 = inventoryService.isInStock(skuCode2, 5);

        // Assert
        assertTrue(result1);
        assertFalse(result2);
    }

    @Test
    void isInStock_WithNullSkuCode_ShouldThrowException() {
        // Arrange
        when(inventoryRepository.existsBySkuCodeAndQuantityIsGreaterThanEqual(null, testQuantity))
                .thenThrow(new IllegalArgumentException("SKU code cannot be null"));

        // Act & Assert
        assertThrows(IllegalArgumentException.class, () -> {
            inventoryService.isInStock(null, testQuantity);
        });
    }

    @Test
    void isInStock_WithNegativeQuantity_ShouldHandleGracefully() {
        // Arrange
        Integer negativeQuantity = -5;
        when(inventoryRepository.existsBySkuCodeAndQuantityIsGreaterThanEqual(testSkuCode, negativeQuantity))
                .thenReturn(true);

        // Act
        boolean result = inventoryService.isInStock(testSkuCode, negativeQuantity);

        // Assert
        assertTrue(result);
        verify(inventoryRepository).existsBySkuCodeAndQuantityIsGreaterThanEqual(testSkuCode, negativeQuantity);
    }
}
