package com.techie.microservices.product.controller;

import com.techie.microservices.product.service.ImageService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

@RestController
@RequestMapping("/images")
@RequiredArgsConstructor
@Slf4j
public class ImageController {

    private final ImageService imageService;

    /**
     * Get image redirect to Azure Storage
     * Azure returns the image directly, so this is mainly for logging/tracking
     */
    @GetMapping("/{filename}")
    public ResponseEntity<?> getImage(@PathVariable String filename) {
        try {
            if (filename.contains("..") || filename.contains("/")) {
                return ResponseEntity.badRequest().build();
            }

            byte[] imageBytes = imageService.getImageBytes(filename);
            String contentType = getContentType(filename);
            
            return ResponseEntity.ok()
                    .header("Content-Type", contentType)
                    .body(imageBytes);

        } catch (IOException e) {
            log.warn("Image not found: {}", filename);
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            log.error("Error retrieving image: {}", filename, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Upload a new image
     */
    @PostMapping("/upload")
    public ResponseEntity<String> uploadImage(@RequestParam("file") MultipartFile file) {
        try {
            String imageUrl = imageService.saveImage(file);
            return ResponseEntity.status(HttpStatus.CREATED).body(imageUrl);
        } catch (IOException e) {
            log.error("Failed to upload image: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Failed to upload image: " + e.getMessage());
        }
    }

    /**
     * Delete an image
     */
    @DeleteMapping
    public ResponseEntity<String> deleteImage(@RequestParam("imageUrl") String imageUrl) {
        try {
            imageService.deleteImage(imageUrl);
            return ResponseEntity.ok("Image deleted successfully");
        } catch (Exception e) {
            log.error("Failed to delete image: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Failed to delete image: " + e.getMessage());
        }
    }

    private String getContentType(String filename) {
        if (filename.endsWith(".png")) {
            return "image/png";
        } else if (filename.endsWith(".jpg") || filename.endsWith(".jpeg")) {
            return "image/jpeg";
        } else if (filename.endsWith(".gif")) {
            return "image/gif";
        } else if (filename.endsWith(".webp")) {
            return "image/webp";
        } else if (filename.endsWith(".svg")) {
            return "image/svg+xml";
        }
        return "application/octet-stream";
    }
}
