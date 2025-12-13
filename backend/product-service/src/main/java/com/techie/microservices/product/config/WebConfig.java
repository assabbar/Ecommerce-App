package com.techie.microservices.product.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Paths;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Value("${app.upload.dir}")
    private String uploadDir;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // Get absolute path
        String uploadPath = Paths.get(uploadDir).toAbsolutePath().toUri().toString();
        
        // Map /api/images/** to the file system
        registry.addResourceHandler("/api/images/**")
                .addResourceLocations(uploadPath)
                .setCachePeriod(31536000); // Cache for 1 year
    }
}
