import { NotificationHistory } from './notification.entity';

export const NotificationProvider = [
  {
    provide: 'NOTIFICATION_HISTORY_REPOSITORY',
    useValue: NotificationHistory,
  },
]; 