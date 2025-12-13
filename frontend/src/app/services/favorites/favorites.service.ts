import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { Product } from '../../model/product';

@Injectable({
  providedIn: 'root'
})
export class FavoritesService {
  private favoritesSubject = new BehaviorSubject<Product[]>(this.loadFavorites());
  public favorites$ = this.favoritesSubject.asObservable();

  constructor() {}

  private loadFavorites(): Product[] {
    const stored = localStorage.getItem('favorites');
    return stored ? JSON.parse(stored) : [];
  }

  private saveFavorites(favorites: Product[]): void {
    localStorage.setItem('favorites', JSON.stringify(favorites));
    this.favoritesSubject.next(favorites);
  }

  addFavorite(product: Product): void {
    if (!product.id) return;
    const favorites = this.favoritesSubject.value;
    const exists = favorites.some(p => p.id === product.id);
    if (!exists) {
      favorites.push(product);
      this.saveFavorites([...favorites]);
    }
  }

  removeFavorite(productId: string | undefined): void {
    if (!productId) return;
    const favorites = this.favoritesSubject.value;
    const filtered = favorites.filter(p => p.id !== productId);
    this.saveFavorites(filtered);
  }

  isFavorite(productId: string | undefined): boolean {
    if (!productId) return false;
    return this.favoritesSubject.value.some(p => p.id === productId);
  }

  getFavorites(): Product[] {
    return this.favoritesSubject.value;
  }

  toggleFavorite(product: Product): void {
    if (!product.id) return;
    if (this.isFavorite(product.id)) {
      this.removeFavorite(product.id);
    } else {
      this.addFavorite(product);
    }
  }
}
