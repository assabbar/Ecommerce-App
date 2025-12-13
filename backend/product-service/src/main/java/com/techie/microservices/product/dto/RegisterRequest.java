package com.techie.microservices.product.dto;

public record RegisterRequest(
    String username,
    String email,
    String password,
    String confirmPassword
) {}
