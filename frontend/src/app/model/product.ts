export interface Product {
  id?: string;
  skuCode: string;
  name: string;
  description: string;
  price: number;
  image?: string;           // Main display image (for backward compatibility)
  category?: string;
  rating?: number;
  reviews?: number;
  inStock?: number;         // Stock quantity
  quantity?: number;
  images?: string[];        // Array of all product images
  coverImage?: string;      // Main cover image URL
  colors?: string[];        // Available colors
  sizes?: string[];         // Available sizes
}
