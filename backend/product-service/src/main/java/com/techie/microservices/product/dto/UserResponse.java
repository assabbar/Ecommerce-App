package com.techie.microservices.product.dto;

public record UserResponse(String username, String email, String role, String token) {
}
