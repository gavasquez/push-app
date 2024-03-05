part of 'notifications_bloc.dart';

sealed class NotificationsEvent {
  const NotificationsEvent();
}

class NotificationStatusChange extends NotificationsEvent {
  final AuthorizationStatus status;
  const NotificationStatusChange(this.status);
}

// NotificationReceived PushMessage

class NotificationReceived extends NotificationsEvent {
  final PushMessage message;
  NotificationReceived(this.message);
}
