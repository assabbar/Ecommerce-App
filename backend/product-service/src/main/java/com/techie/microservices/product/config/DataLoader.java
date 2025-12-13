package com.techie.microservices.product.config;

import com.techie.microservices.product.repository.ProductRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@RequiredArgsConstructor
public class DataLoader {

    @Bean
    public CommandLineRunner loadProducts(ProductRepository productRepository) {
        return args -> {
            // Disabled - load products manually via API
            System.out.println("DataLoader: No products loaded (manual creation only)");
        };
    }
}
