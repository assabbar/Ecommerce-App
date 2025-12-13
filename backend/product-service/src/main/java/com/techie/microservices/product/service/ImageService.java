package com.techie.microservices.product.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class ImageService {

    @Value("${app.upload.dir}")
    private String uploadDir;

    @Value("${app.image.base-url:/api/images}")
    private String imageBaseUrl;
    
    private Path getUploadPath() {
        Path uploadPath = Paths.get(uploadDir);
        if (!uploadPath.isAbsolute()) {
            uploadPath = Paths.get(System.getProperty("user.dir"), uploadDir);
        }
        return uploadPath;
    }

    /**
     * Save images from base64 data URLs and return their paths
     * Format: "data:image/png;base64,iVBORw0KGg..."
     */
    public List<String> saveImagesFromBase64(List<String> base64Images) {
        List<String> savedImagePaths = new ArrayList<>();
        
        if (base64Images == null || base64Images.isEmpty()) {
            return savedImagePaths;
        }

        for (String base64Data : base64Images) {
            try {
                String imagePath = saveBase64Image(base64Data);
                if (imagePath != null) {
                    savedImagePaths.add(imagePath);
                }
            } catch (IOException e) {
                log.error("Error saving base64 image: ", e);
            }
        }

        return savedImagePaths;
    }

    /**
     * Save a single base64 image and return its path
     */
    public String saveBase64Image(String base64Data) throws IOException {
        if (base64Data == null || base64Data.isEmpty()) {
            return null;
        }

        // Extract actual base64 data from data URL
        // Format: "data:image/png;base64,iVBORw0KGg..."
        String[] parts = base64Data.split(",");
        if (parts.length < 2) {
            log.warn("Invalid base64 data URL format");
            return null;
        }

        String base64Image = parts[1];
        
        // Extract image type from mime type
        // Format: "data:image/png;base64"
        String mimeType = parts[0].split(":")[1].split(";")[0]; // "image/png"
        String extension = getExtensionFromMimeType(mimeType);

        // Create uploads directory if it doesn't exist
        Path uploadPath = getUploadPath();
        Files.createDirectories(uploadPath);

        // Generate unique filename
        String filename = UUID.randomUUID() + "." + extension;
        Path filePath = uploadPath.resolve(filename);

        try {
            // Decode base64 and save file
            byte[] imageBytes = Base64.getDecoder().decode(base64Image);
            Files.write(filePath, imageBytes);
            
            log.info("Image saved successfully: {} at {}", filename, filePath.toAbsolutePath());
            
            // Return the API path that will be used to retrieve the image
            return imageBaseUrl + "/" + filename;
        } catch (IllegalArgumentException e) {
            log.error("Invalid base64 string: {}", e.getMessage());
            return null;
        }
    }

    /**
     * Save image from MultipartFile and return its path
     */
    public String saveImage(MultipartFile file) throws IOException {
        if (file.isEmpty()) {
            throw new IllegalArgumentException("File is empty");
        }

        // Create uploads directory if it doesn't exist
        Path uploadPath = getUploadPath();
        Files.createDirectories(uploadPath);

        // Get file extension
        String originalFilename = file.getOriginalFilename();
        String extension = getExtensionFromFilename(originalFilename);

        // Generate unique filename
        String filename = UUID.randomUUID() + "." + extension;
        Path filePath = uploadPath.resolve(filename);

        // Save file
        Files.write(filePath, file.getBytes());

        log.info("Image saved successfully: {} at {}", filename, filePath.toAbsolutePath());
        
        // Return the API path that will be used to retrieve the image
        return imageBaseUrl + "/" + filename;
    }

    /**
     * Delete an image file
     */
    public void deleteImage(String imagePath) {
        try {
            if (imagePath == null || !imagePath.startsWith(imageBaseUrl)) {
                return;
            }

            // Extract filename from path
            String filename = imagePath.substring(imageBaseUrl.length() + 1);
            Path uploadPath = getUploadPath();
            Path filePath = uploadPath.resolve(filename);

            if (Files.exists(filePath)) {
                Files.delete(filePath);
                log.info("Image deleted successfully: {}", filename);
            }
        } catch (IOException e) {
            log.error("Error deleting image: ", e);
        }
    }

    /**
     * Get the full file path for serving the image
     */
    public Path getImageFilePath(String filename) {
        Path uploadPath = getUploadPath();
        return uploadPath.resolve(filename);
    }

    private String getExtensionFromMimeType(String mimeType) {
        return switch (mimeType.toLowerCase()) {
            case "image/jpeg" -> "jpg";
            case "image/png" -> "png";
            case "image/gif" -> "gif";
            case "image/webp" -> "webp";
            case "image/svg+xml" -> "svg";
            default -> "jpg";
        };
    }

    private String getExtensionFromFilename(String filename) {
        if (filename == null || !filename.contains(".")) {
            return "jpg";
        }
        return filename.substring(filename.lastIndexOf(".") + 1).toLowerCase();
    }
}
