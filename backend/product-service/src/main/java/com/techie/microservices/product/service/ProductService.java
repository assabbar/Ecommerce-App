package com.techie.microservices.product.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.techie.microservices.product.dto.ProductRequest;
import com.techie.microservices.product.dto.ProductResponse;
import com.techie.microservices.product.model.Product;
import com.techie.microservices.product.repository.ProductRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.Base64;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class ProductService {
    private final ProductRepository productRepository;
    private final ImageService imageService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public ProductResponse createProduct(ProductRequest productRequest) {
        // Save images and get their paths
        List<String> imagePaths = new ArrayList<>();
        String coverImagePath = null;

        if (productRequest.images() != null && !productRequest.images().isEmpty()) {
            imagePaths = imageService.saveImagesFromBase64(productRequest.images());
        }

        if (productRequest.coverImage() != null && !productRequest.coverImage().isEmpty()) {
            try {
                coverImagePath = imageService.saveBase64Image(productRequest.coverImage());
            } catch (java.io.IOException e) {
                log.error("Error saving cover image: ", e);
            }
        }

        Product product = Product.builder()
                .name(productRequest.name())
                .description(productRequest.description())
                .skuCode(productRequest.skuCode())
                .price(productRequest.price())
                .category(productRequest.category())
                .images(imagePaths)
                .coverImage(coverImagePath)
                .rating(productRequest.rating())
                .reviews(productRequest.reviews())
                .inStock(productRequest.inStock() != null ? productRequest.inStock() : 0)
                .colors(productRequest.colors())
                .sizes(productRequest.sizes())
                .build();
        productRepository.save(product);
        log.info("Product created successfully with {} images", imagePaths.size());
        return mapToProductResponse(product);
    }

    public ProductResponse createProductWithImages(String productJson, List<MultipartFile> images, int coverImageIndex) {
        try {
            // Parse product JSON
            ProductRequest productRequest = objectMapper.readValue(productJson, ProductRequest.class);
            
            // Save images locally and get their paths
            List<String> imagePaths = new ArrayList<>();
            for (MultipartFile image : images) {
                String imagePath = imageService.saveImage(image);
                imagePaths.add(imagePath);
            }
            
            // Set cover image (use the specified index or first image)
            String coverImage = null;
            if (!imagePaths.isEmpty()) {
                coverImage = imagePaths.get(Math.min(coverImageIndex, imagePaths.size() - 1));
            }
            
            // Create product
            Product product = Product.builder()
                    .name(productRequest.name())
                    .description(productRequest.description())
                    .skuCode(productRequest.skuCode())
                    .price(productRequest.price())
                    .category(productRequest.category())
                    .images(imagePaths)
                    .coverImage(coverImage)
                    .rating(4.5)
                    .reviews(0)
                    .inStock(10)
                    .colors(productRequest.colors())
                    .sizes(productRequest.sizes())
                    .build();
            
            productRepository.save(product);
            log.info("Product with images created successfully. {} images saved", imagePaths.size());
            return mapToProductResponse(product);
        } catch (Exception e) {
            log.error("Error creating product with images: ", e);
            throw new RuntimeException("Error creating product with images", e);
        }
    }

    public List<ProductResponse> getAllProducts() {
        return productRepository.findAll()
                .stream()
                .map(this::mapToProductResponse)
                .toList();
    }

    public ProductResponse getProductById(String id) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Product not found with id: " + id));
        return mapToProductResponse(product);
    }

    public ProductResponse updateProduct(String id, ProductRequest productRequest) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Product not found with id: " + id));
        
        product.setName(productRequest.name());
        product.setDescription(productRequest.description());
        product.setSkuCode(productRequest.skuCode());
        product.setPrice(productRequest.price());
        product.setCategory(productRequest.category());
        product.setImages(productRequest.images());
        product.setCoverImage(productRequest.coverImage());
        product.setRating(productRequest.rating());
        product.setReviews(productRequest.reviews());
        product.setInStock(productRequest.inStock() != null ? productRequest.inStock() : 0);
        product.setColors(productRequest.colors());
        product.setSizes(productRequest.sizes());
        
        productRepository.save(product);
        log.info("Product with id {} updated successfully", id);
        return mapToProductResponse(product);
    }

    public void deleteProduct(String id) {
        productRepository.deleteById(id);
        log.info("Product with id {} deleted successfully", id);
    }

    private ProductResponse mapToProductResponse(Product product) {
        return new ProductResponse(
                product.getId(),
                product.getName(),
                product.getDescription(),
                product.getSkuCode(),
                product.getPrice(),
                product.getCategory(),
                product.getImages(),
                product.getCoverImage(),
                product.getRating(),
                product.getReviews(),
                product.getInStock(),
                product.getColors(),
                product.getSizes()
        );
    }

    private String getImageType(String filename) {
        if (filename == null) return "png";
        String[] parts = filename.split("\\.");
        if (parts.length > 0) {
            return parts[parts.length - 1].toLowerCase();
        }
        return "png";
    }
}
