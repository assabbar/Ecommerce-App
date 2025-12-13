import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NotificationService, Notification } from '../../services/notification/notification.service';
import { trigger, transition, style, animate } from '@angular/animations';

@Component({
  selector: 'app-notification',
  standalone: true,
  imports: [CommonModule],
  animations: [
    trigger('slideIn', [
      transition(':enter', [
        style({ transform: 'translateX(400px)', opacity: 0 }),
        animate('300ms ease-out', style({ transform: 'translateX(0)', opacity: 1 }))
      ]),
      transition(':leave', [
        animate('300ms ease-in', style({ transform: 'translateX(400px)', opacity: 0 }))
      ])
    ])
  ],
  template: `
    <div class="notifications-container">
      @for (notification of notifications; track notification.id) {
        <div 
          class="notification"
          [class]="'notification-' + notification.type"
          [@slideIn]
          (click)="dismiss(notification.id)">
          <div class="notification-content">
            <span class="notification-icon">
              @switch (notification.type) {
                @case ('success') {
                  <span class="icon">✓</span>
                }
                @case ('error') {
                  <span class="icon">✕</span>
                }
                @case ('warning') {
                  <span class="icon">!</span>
                }
                @case ('info') {
                  <span class="icon">ⓘ</span>
                }
              }
            </span>
            <span class="notification-message">{{ notification.message }}</span>
          </div>
          <button class="notification-close" (click)="dismiss(notification.id)">×</button>
        </div>
      }
    </div>
  `,
  styles: [`
    .notifications-container {
      position: fixed;
      top: 20px;
      right: 20px;
      z-index: 9999;
      display: flex;
      flex-direction: column;
      gap: 12px;
      max-width: 400px;
    }

    .notification {
      padding: 16px;
      border-radius: 8px;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      cursor: pointer;
      transition: all 0.3s ease;
      min-width: 300px;
    }

    .notification:hover {
      box-shadow: 0 6px 16px rgba(0, 0, 0, 0.2);
    }

    .notification-content {
      display: flex;
      align-items: center;
      gap: 12px;
      flex: 1;
    }

    .notification-icon {
      font-weight: 600;
      font-size: 18px;
      display: flex;
      align-items: center;
      justify-content: center;
      min-width: 24px;
    }

    .notification-message {
      font-size: 14px;
      font-weight: 500;
      line-height: 1.4;
    }

    .notification-close {
      background: transparent;
      border: none;
      font-size: 24px;
      cursor: pointer;
      color: inherit;
      padding: 0;
      width: 24px;
      height: 24px;
      display: flex;
      align-items: center;
      justify-content: center;
      opacity: 0.7;
      transition: opacity 0.2s;
    }

    .notification-close:hover {
      opacity: 1;
    }

    /* Success Style */
    .notification-success {
      background: #d1fae5;
      color: #065f46;
      border-left: 4px solid #10b981;
    }

    .notification-success .notification-icon {
      color: #10b981;
    }

    /* Error Style */
    .notification-error {
      background: #fee2e2;
      color: #7f1d1d;
      border-left: 4px solid #ef4444;
    }

    .notification-error .notification-icon {
      color: #ef4444;
    }

    /* Warning Style */
    .notification-warning {
      background: #fef3c7;
      color: #78350f;
      border-left: 4px solid #f59e0b;
    }

    .notification-warning .notification-icon {
      color: #f59e0b;
    }

    /* Info Style */
    .notification-info {
      background: #dbeafe;
      color: #1e40af;
      border-left: 4px solid #3b82f6;
    }

    .notification-info .notification-icon {
      color: #3b82f6;
    }

    @media (max-width: 480px) {
      .notifications-container {
        left: 10px;
        right: 10px;
        max-width: none;
      }

      .notification {
        min-width: auto;
      }
    }
  `]
})
export class NotificationComponent implements OnInit {
  notifications: Notification[] = [];
  private notificationService = inject(NotificationService);

  ngOnInit(): void {
    this.notificationService.notifications$.subscribe(notifications => {
      this.notifications = notifications;
    });
  }

  dismiss(id: string): void {
    this.notificationService.remove(id);
  }
}
