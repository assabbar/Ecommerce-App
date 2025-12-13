package com.techie.microservices.product.dto;

import java.math.BigDecimal;
import java.util.List;

public record ProductResponse(String id, String name, String description,
                              String skuCode, BigDecimal price, String category,
                              List<String> images, String coverImage,
                              Double rating, Integer reviews, Integer inStock,
                              List<String> colors, List<String> sizes) {
}
