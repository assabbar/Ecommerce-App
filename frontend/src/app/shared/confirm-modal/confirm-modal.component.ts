import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ModalService } from '../../services/modal.service';

@Component({
  selector: 'app-confirm-modal',
  standalone: true,
  imports: [CommonModule],
  template: `
    @let data = (modalData$ | async);
    @if (data) {
      <div class="modal-overlay" (click)="onBackdropClick()">
        <div class="modal-content" (click)="$event.stopPropagation()" [class.dangerous]="data.isDangerous">
          <div class="modal-header">
            <h2>{{ data.title }}</h2>
            <button class="close-btn" (click)="modalService.cancel()">×</button>
          </div>
          <div class="modal-body">
            <p>{{ data.message }}</p>
          </div>
          <div class="modal-footer">
            <button class="btn-cancel" (click)="modalService.cancel()">
              {{ data.cancelText || 'Annuler' }}
            </button>
            <button 
              [class.btn-danger]="data.isDangerous"
              [class.btn-confirm]="!data.isDangerous"
              (click)="modalService.confirm()">
              {{ data.confirmText || 'Confirmer' }}
            </button>
          </div>
        </div>
      </div>
    }
  `,
  styles: [`
    .modal-overlay {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(0, 0, 0, 0.5);
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 1000;
    }

    .modal-content {
      background: white;
      border-radius: 12px;
      box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
      max-width: 400px;
      width: 90%;
      overflow: hidden;
      animation: slideUp 0.3s ease;
    }

    @keyframes slideUp {
      from {
        transform: translateY(20px);
        opacity: 0;
      }
      to {
        transform: translateY(0);
        opacity: 1;
      }
    }

    .modal-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 20px;
      border-bottom: 1px solid #f0f0f0;
      background: #f9f9f9;
    }

    .modal-header h2 {
      margin: 0;
      font-size: 18px;
      color: #1a1a1a;
    }

    .close-btn {
      background: none;
      border: none;
      font-size: 28px;
      cursor: pointer;
      color: #999;
      padding: 0;
      width: 32px;
      height: 32px;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .close-btn:hover {
      color: #1a1a1a;
    }

    .modal-body {
      padding: 20px;
    }

    .modal-body p {
      margin: 0;
      color: #666;
      font-size: 15px;
      line-height: 1.5;
    }

    .modal-footer {
      padding: 16px 20px;
      display: flex;
      gap: 12px;
      justify-content: flex-end;
      border-top: 1px solid #f0f0f0;
      background: #f9f9f9;
    }

    button {
      padding: 10px 20px;
      border: none;
      border-radius: 6px;
      font-weight: 600;
      font-size: 14px;
      cursor: pointer;
      transition: all 0.3s ease;
    }

    .btn-cancel {
      background: #e8e8e8;
      color: #333;
    }

    .btn-cancel:hover {
      background: #d8d8d8;
    }

    .btn-confirm {
      background: #7c3aed;
      color: white;
    }

    .btn-confirm:hover {
      background: #6d28d9;
      transform: translateY(-2px);
    }

    .btn-danger {
      background: #dc3545;
      color: white;
    }

    .btn-danger:hover {
      background: #c82333;
      transform: translateY(-2px);
    }

    .modal-content.dangerous .modal-header {
      background: #fff5f5;
      border-bottom-color: #ffe0e0;
    }

    .modal-content.dangerous .modal-header h2 {
      color: #dc3545;
    }
  `]
})
export class ConfirmModalComponent {
  modalService = inject(ModalService);
  modalData$ = this.modalService.modal$;

  onBackdropClick(): void {
    this.modalService.cancel();
  }
}
