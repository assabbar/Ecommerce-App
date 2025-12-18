package com.techie.microservices.order.service;

import com.techie.microservices.order.client.InventoryClient;
import com.techie.microservices.order.dto.OrderRequest;
import com.techie.microservices.order.event.OrderPlacedEvent;
import com.techie.microservices.order.model.Order;
import com.techie.microservices.order.repository.OrderRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.kafka.core.KafkaTemplate;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private OrderRepository orderRepository;

    @Mock
    private InventoryClient inventoryClient;

    @Mock
    private KafkaTemplate<String, OrderPlacedEvent> kafkaTemplate;

    @InjectMocks
    private OrderService orderService;

    private OrderRequest orderRequest;

    @BeforeEach
    void setUp() {
        // OrderRequest with null userDetails for mocking
        orderRequest = new OrderRequest(null, null, "SKU-001", new BigDecimal("29.99"), 5, null);
    }

    @Test
    void placeOrder_WhenProductInStock_ShouldSaveOrderAndSendKafkaMessage() {
        // Arrange
        when(inventoryClient.isInStock("SKU-001", 5)).thenReturn(true);
        when(orderRepository.save(any(Order.class))).thenAnswer(invocation -> invocation.getArgument(0));

        // Act
        orderService.placeOrder(orderRequest);

        // Assert - Verify order was saved
        ArgumentCaptor<Order> orderCaptor = ArgumentCaptor.forClass(Order.class);
        verify(orderRepository, times(1)).save(orderCaptor.capture());
        
        Order savedOrder = orderCaptor.getValue();
        assertNotNull(savedOrder.getOrderNumber());
        assertEquals("SKU-001", savedOrder.getSkuCode());
        assertEquals(5, savedOrder.getQuantity());
        assertEquals(new BigDecimal("149.95"), savedOrder.getPrice());

        // Verify Kafka message was sent
        ArgumentCaptor<OrderPlacedEvent> eventCaptor = ArgumentCaptor.forClass(OrderPlacedEvent.class);
        verify(kafkaTemplate, times(1)).send(eq("order-placed"), eventCaptor.capture());
        
        OrderPlacedEvent sentEvent = eventCaptor.getValue();
        assertEquals(savedOrder.getOrderNumber(), sentEvent.getOrderNumber());
        assertEquals("john@example.com", sentEvent.getEmail());
        assertEquals("John", sentEvent.getFirstName());
        assertEquals("Doe", sentEvent.getLastName());
    }

    @Test
    void placeOrder_WhenProductOutOfStock_ShouldThrowException() {
        // Arrange
        when(inventoryClient.isInStock("SKU-001", 5)).thenReturn(false);

        // Act & Assert
        RuntimeException exception = assertThrows(RuntimeException.class, () -> {
            orderService.placeOrder(orderRequest);
        });

        assertTrue(exception.getMessage().contains("not in stock"));
        verify(orderRepository, never()).save(any());
        verify(kafkaTemplate, never()).send(anyString(), any());
    }

    @Test
    void placeOrder_WhenInventoryClientFails_ShouldThrowException() {
        // Arrange
        when(inventoryClient.isInStock("SKU-001", 5)).thenThrow(new RuntimeException("Inventory service unavailable"));

        // Act & Assert
        assertThrows(RuntimeException.class, () -> {
            orderService.placeOrder(orderRequest);
        });

        verify(orderRepository, never()).save(any());
        verify(kafkaTemplate, never()).send(anyString(), any());
    }

    @Test
    void placeOrder_WithLargeQuantity_ShouldCalculatePriceCorrectly() {
        // Arrange
        OrderRequest largeOrderRequest = new OrderRequest(null, null, "SKU-002", new BigDecimal("99.99"), 100, null);
        when(inventoryClient.isInStock("SKU-002", 100)).thenReturn(true);
        when(orderRepository.save(any(Order.class))).thenAnswer(invocation -> invocation.getArgument(0));

        // Act
        orderService.placeOrder(largeOrderRequest);

        // Assert
        ArgumentCaptor<Order> orderCaptor = ArgumentCaptor.forClass(Order.class);
        verify(orderRepository).save(orderCaptor.capture());
        
        Order savedOrder = orderCaptor.getValue();
        assertEquals(new BigDecimal("9999.00"), savedOrder.getPrice());
    }

    @Test
    void placeOrder_WithMinimumQuantity_ShouldSucceed() {
        // Arrange
        OrderRequest minOrderRequest = new OrderRequest(null, null, "SKU-003", new BigDecimal("10.00"), 1, null);
        when(inventoryClient.isInStock("SKU-003", 1)).thenReturn(true);
        when(orderRepository.save(any(Order.class))).thenAnswer(invocation -> invocation.getArgument(0));

        // Act
        orderService.placeOrder(minOrderRequest);

        // Assert
        verify(orderRepository, times(1)).save(any(Order.class));
        verify(kafkaTemplate, times(1)).send(eq("order-placed"), any(OrderPlacedEvent.class));
    }
}
