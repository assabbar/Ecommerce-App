package com.techie.microservices.product.config;

import com.techie.microservices.product.entity.User;
import com.techie.microservices.product.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@RequiredArgsConstructor
public class DataInitializer {

    private final UserRepository userRepository;

    @Bean
    public CommandLineRunner initializeUsers() {
        return args -> {
            // Only initialize if users don't exist
            if (userRepository.findByUsername("admin").isEmpty()) {
                User admin = User.builder()
                        .username("admin")
                        .email("admin@mlk.shop")
                        .password("admin")
                        .role("admin")
                        .enabled(true)
                        .build();
                userRepository.save(admin);
                System.out.println("✅ Admin user created: admin/admin");
            }

            if (userRepository.findByUsername("user").isEmpty()) {
                User user = User.builder()
                        .username("user")
                        .email("user@mlk.shop")
                        .password("user")
                        .role("user")
                        .enabled(true)
                        .build();
                userRepository.save(user);
                System.out.println("✅ Regular user created: user/user");
            }
        };
    }
}
