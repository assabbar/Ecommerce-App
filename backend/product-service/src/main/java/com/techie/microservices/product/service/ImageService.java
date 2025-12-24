package com.techie.microservices.product.service;

import com.azure.storage.blob.BlobClient;
import com.azure.storage.blob.BlobContainerClient;
import com.azure.storage.blob.BlobServiceClient;
import com.azure.storage.blob.BlobServiceClientBuilder;
import com.azure.storage.blob.models.BlobStorageException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class ImageService {

    @Value("${azure.storage.connection-string:}")
    private String connectionString;

    @Value("${azure.storage.container-name:product-images}")
    private String containerName;

    @Value("${azure.storage.account-url:}")
    private String accountUrl;

    private BlobContainerClient getContainerClient() {
        BlobServiceClient blobServiceClient;
        if (!connectionString.isEmpty()) {
            blobServiceClient = new BlobServiceClientBuilder()
                    .connectionString(connectionString)
                    .buildClient();
        } else if (!accountUrl.isEmpty()) {
            blobServiceClient = new BlobServiceClientBuilder()
                    .endpoint(accountUrl)
                    .buildClient();
        } else {
            throw new IllegalStateException("Azure Storage configuration not found");
        }
        return blobServiceClient.getBlobContainerClient(containerName);
    }

    /**
     * Save images from base64 data URLs to Azure Storage
     */
    public List<String> saveImagesFromBase64(List<String> base64Images) {
        List<String> savedImageUrls = new ArrayList<>();
        
        if (base64Images == null || base64Images.isEmpty()) {
            return savedImageUrls;
        }

        for (String base64Data : base64Images) {
            try {
                String imageUrl = saveBase64Image(base64Data);
                if (imageUrl != null) {
                    savedImageUrls.add(imageUrl);
                }
            } catch (Exception e) {
                log.error("Failed to save base64 image: {}", e.getMessage());
            }
        }
        return savedImageUrls;
    }

    /**
     * Save a single base64 image to Azure Storage
     */
    public String saveBase64Image(String base64Data) throws IOException {
        try {
            // Remove the data URL prefix if present
            String base64String = base64Data;
            if (base64String.contains(",")) {
                base64String = base64String.split(",")[1];
            }

            // Decode base64
            byte[] imageBytes = Base64.getDecoder().decode(base64String);

            // Generate unique filename
            String filename = generateFilename(base64Data);

            // Upload to Azure Storage
            BlobContainerClient containerClient = getContainerClient();
            BlobClient blobClient = containerClient.getBlobClient(filename);
            blobClient.upload(imageBytes, true);

            log.info("Image uploaded to Azure Storage: {}", filename);

            // Return the URL
            return blobClient.getBlobUrl();
        } catch (IllegalArgumentException e) {
            log.error("Invalid base64 format: {}", e.getMessage());
            throw new IOException("Invalid base64 image format", e);
        } catch (BlobStorageException e) {
            log.error("Failed to upload to Azure Storage: {}", e.getMessage());
            throw new IOException("Failed to upload image to Azure Storage", e);
        }
    }

    /**
     * Handle multipart file uploads to Azure Storage
     */
    public String saveImage(MultipartFile file) throws IOException {
        try {
            String filename = generateFilename(file.getOriginalFilename());
            
            BlobContainerClient containerClient = getContainerClient();
            BlobClient blobClient = containerClient.getBlobClient(filename);
            blobClient.upload(file.getInputStream(), file.getSize(), true);

            log.info("File uploaded to Azure Storage: {}", filename);
            return blobClient.getBlobUrl();
        } catch (IOException e) {
            log.error("Failed to upload file: {}", e.getMessage());
            throw new IOException("Failed to upload file to Azure Storage", e);
        }
    }

    /**
     * Retrieve image as bytes from Azure Storage
     */
    public byte[] getImageBytes(String filename) throws IOException {
        try {
            BlobContainerClient containerClient = getContainerClient();
            BlobClient blobClient = containerClient.getBlobClient(filename);
            
            if (!blobClient.exists()) {
                throw new IOException("Image not found: " + filename);
            }

            return blobClient.downloadContent().toBytes();
        } catch (BlobStorageException e) {
            log.error("Failed to download image from Azure Storage: {}", e.getMessage());
            throw new IOException("Failed to download image from Azure Storage", e);
        }
    }

    /**
     * Delete image from Azure Storage
     */
    public void deleteImage(String imagePath) {
        try {
            if (imagePath == null || imagePath.isEmpty()) {
                return;
            }
            
            // Extract filename from URL
            String filename = extractFilenameFromUrl(imagePath);
            BlobContainerClient containerClient = getContainerClient();
            containerClient.getBlobClient(filename).delete();
            log.info("Image deleted from Azure Storage: {}", filename);
        } catch (BlobStorageException e) {
            log.warn("Failed to delete image from Azure Storage: {}", e.getMessage());
        }
    }

    /**
     * Generate unique filename from base64 data or original filename
     */
    private String generateFilename(String data) {
        String extension = "jpg"; // default

        if (data != null && data.contains("data:")) {
            if (data.contains("png")) extension = "png";
            else if (data.contains("jpeg")) extension = "jpg";
            else if (data.contains("gif")) extension = "gif";
            else if (data.contains("webp")) extension = "webp";
        } else if (data != null && data.contains(".")) {
            String[] parts = data.split("\\.");
            extension = parts[parts.length - 1].toLowerCase();
        }

        return UUID.randomUUID() + "." + extension;
    }

    private String extractFilenameFromUrl(String url) {
        if (url == null) return null;
        return url.substring(url.lastIndexOf("/") + 1);
    }
}
