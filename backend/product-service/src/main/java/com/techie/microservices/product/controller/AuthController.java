package com.techie.microservices.product.controller;

import com.techie.microservices.product.dto.LoginRequest;
import com.techie.microservices.product.dto.RegisterRequest;
import com.techie.microservices.product.dto.UserResponse;
import com.techie.microservices.product.entity.User;
import com.techie.microservices.product.repository.UserRepository;
import com.techie.microservices.product.service.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Optional;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final JwtService jwtService;
    private final UserRepository userRepository;

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest registerRequest) {
        if (registerRequest.username() == null || registerRequest.username().isEmpty()) {
            return ResponseEntity.badRequest().body("Username required");
        }
        if (registerRequest.email() == null || registerRequest.email().isEmpty()) {
            return ResponseEntity.badRequest().body("Email required");
        }
        if (registerRequest.password() == null || registerRequest.password().isEmpty()) {
            return ResponseEntity.badRequest().body("Password required");
        }
        if (!registerRequest.password().equals(registerRequest.confirmPassword())) {
            return ResponseEntity.badRequest().body("Passwords do not match");
        }

        if (userRepository.existsByUsername(registerRequest.username())) {
            return ResponseEntity.badRequest().body("Username already exists");
        }

        User user = User.builder()
                .username(registerRequest.username())
                .email(registerRequest.email())
                .password(registerRequest.password()) // In production: use BCryptPasswordEncoder
                .role("user") // New users are always "user" role
                .enabled(true)
                .build();

        userRepository.save(user);

        String token = jwtService.generateToken(user.getUsername(), user.getRole());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(new UserResponse(user.getUsername(), user.getEmail(), user.getRole(), token));
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest loginRequest) {
        String username = loginRequest.username();
        String password = loginRequest.password();

        if (username == null || password == null || username.isEmpty() || password.isEmpty()) {
            return ResponseEntity.badRequest().body("Username and password required");
        }

        Optional<User> user = userRepository.findByUsername(username);
        if (user.isEmpty() || !user.get().getPassword().equals(password)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Invalid credentials");
        }

        User foundUser = user.get();
        if (!foundUser.isEnabled()) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("User account is disabled");
        }

        String token = jwtService.generateToken(foundUser.getUsername(), foundUser.getRole());
        return ResponseEntity.ok(new UserResponse(foundUser.getUsername(), foundUser.getEmail(), foundUser.getRole(), token));
    }

    @PostMapping("/validate")
    public ResponseEntity<?> validate(@RequestHeader("Authorization") String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Missing token");
        }

        String token = authHeader.substring(7);
        if (!jwtService.isTokenValid(token)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Invalid token");
        }

        String username = jwtService.extractUsername(token);
        Optional<User> user = userRepository.findByUsername(username);

        if (user.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("User not found");
        }

        User foundUser = user.get();
        return ResponseEntity.ok(new UserResponse(foundUser.getUsername(), foundUser.getEmail(), foundUser.getRole(), token));
    }
}


