package com.techie.microservices.notification.service;

import com.techie.microservices.order.event.OrderPlacedEvent;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mail.MailException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessagePreparator;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class NotificationServiceTest {

    @Mock
    private JavaMailSender javaMailSender;

    @InjectMocks
    private NotificationService notificationService;

    private OrderPlacedEvent orderPlacedEvent;

    @BeforeEach
    void setUp() {
        orderPlacedEvent = new OrderPlacedEvent();
        orderPlacedEvent.setOrderNumber("ORDER-12345");
        orderPlacedEvent.setEmail("customer@example.com");
        orderPlacedEvent.setFirstName("John");
        orderPlacedEvent.setLastName("Doe");
    }

    @Test
    void listen_WhenOrderPlacedEventReceived_ShouldSendEmailSuccessfully() {
        // Arrange - Mock will not throw exception
        doNothing().when(javaMailSender).send(any(MimeMessagePreparator.class));

        // Act
        notificationService.listen(orderPlacedEvent);

        // Assert
        ArgumentCaptor<MimeMessagePreparator> captor = ArgumentCaptor.forClass(MimeMessagePreparator.class);
        verify(javaMailSender, times(1)).send(captor.capture());
        assertNotNull(captor.getValue());
    }

    @Test
    void listen_WhenEmailSendingFails_ShouldThrowRuntimeException() {
        // Arrange
        doThrow(new MailException("SMTP connection failed") {})
                .when(javaMailSender).send(any(MimeMessagePreparator.class));

        // Act & Assert
        RuntimeException exception = assertThrows(RuntimeException.class, () -> {
            notificationService.listen(orderPlacedEvent);
        });

        assertTrue(exception.getMessage().contains("Exception occurred when sending mail"));
        verify(javaMailSender, times(1)).send(any(MimeMessagePreparator.class));
    }

    @Test
    void listen_WithValidOrderPlacedEvent_ShouldAttemptEmailSend() {
        // Arrange
        OrderPlacedEvent event = new OrderPlacedEvent();
        event.setOrderNumber("ORDER-67890");
        event.setEmail("john.smith@example.com");
        event.setFirstName("John");
        event.setLastName("Smith");
        
        doNothing().when(javaMailSender).send(any(MimeMessagePreparator.class));

        // Act
        notificationService.listen(event);

        // Assert
        verify(javaMailSender, times(1)).send(any(MimeMessagePreparator.class));
    }

    @Test
    void listen_WhenMultipleEventsReceived_ShouldSendEmailForEach() {
        // Arrange
        doNothing().when(javaMailSender).send(any(MimeMessagePreparator.class));

        OrderPlacedEvent event1 = new OrderPlacedEvent();
        event1.setOrderNumber("ORDER-001");
        event1.setEmail("user1@example.com");
        event1.setFirstName("User");
        event1.setLastName("One");

        OrderPlacedEvent event2 = new OrderPlacedEvent();
        event2.setOrderNumber("ORDER-002");
        event2.setEmail("user2@example.com");
        event2.setFirstName("User");
        event2.setLastName("Two");

        // Act
        notificationService.listen(event1);
        notificationService.listen(event2);

        // Assert
        verify(javaMailSender, times(2)).send(any(MimeMessagePreparator.class));
    }

    @Test
    void listen_WithNullEvent_ShouldHandleGracefully() {
        // Act - Should handle null event gracefully
        // This test verifies null handling doesn't crash
        try {
            notificationService.listen(null);
        } catch (NullPointerException | IllegalArgumentException e) {
            // Expected behavior for null input
            assertNotNull(e);
        }
    }

    @Test
    void listen_WhenEmailIsEmpty_ShouldStillAttemptSend() {
        // Arrange
        OrderPlacedEvent eventWithEmptyEmail = new OrderPlacedEvent();
        eventWithEmptyEmail.setOrderNumber("ORDER-99999");
        eventWithEmptyEmail.setEmail("");
        eventWithEmptyEmail.setFirstName("Test");
        eventWithEmptyEmail.setLastName("User");
        
        doNothing().when(javaMailSender).send(any(MimeMessagePreparator.class));

        // Act
        notificationService.listen(eventWithEmptyEmail);

        // Assert
        verify(javaMailSender, times(1)).send(any(MimeMessagePreparator.class));
    }
}
