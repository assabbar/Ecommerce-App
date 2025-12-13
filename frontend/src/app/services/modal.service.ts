import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';

export interface ConfirmModalData {
  title: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  isDangerous?: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class ModalService {
  private modalSubject = new BehaviorSubject<ConfirmModalData | null>(null);
  public modal$ = this.modalSubject.asObservable();

  private resultSubject = new BehaviorSubject<boolean | null>(null);
  public result$ = this.resultSubject.asObservable();

  openConfirm(data: ConfirmModalData): Observable<boolean> {
    this.modalSubject.next(data);
    return this.result$ as Observable<boolean>;
  }

  confirm(): void {
    this.resultSubject.next(true);
    this.modalSubject.next(null);
  }

  cancel(): void {
    this.resultSubject.next(false);
    this.modalSubject.next(null);
  }
}
