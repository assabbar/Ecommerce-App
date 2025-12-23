import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'apiUrl',
  standalone: true
})
export class ApiUrlPipe implements PipeTransform {
  private apiBaseUrl = '';

  transform(value: string | null | undefined): string {
    if (!value) {
      return 'assets/placeholder.png';
    }

    // If it's already a full URL, return it
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    // If it starts with /api/, prepend the base URL
    if (value.startsWith('/api/')) {
      return this.apiBaseUrl + value;
    }

    // Otherwise return as is
    return value;
  }
}
