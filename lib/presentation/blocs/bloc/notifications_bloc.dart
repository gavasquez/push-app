import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:push_app/domain/entities/push_message.dart';
import 'package:push_app/firebase_options.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
}

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  //* Instancia de FirebaseMessaging
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationsBloc() : super(const NotificationsState()) {
    on<NotificationStatusChange>(
        (event, emit) => _notificationStatusChange(event, emit));

    on<NotificationReceived>(
        (event, emit) => _onPushMessageReceived(event, emit));

    // _onPueshMessageReceived

    // Verificar estado de las notificaciones
    _initialStatusCheck();
    // Listener para notificaciones en Foreground
    _onForegroungMessage();
  }

  void _onPushMessageReceived(
      NotificationReceived event, Emitter<NotificationsState> emit) {
    emit(
        state.copyWith(notifications: [event.message, ...state.notifications]));
  }

  void _notificationStatusChange(
      NotificationStatusChange event, Emitter<NotificationsState> emit) {
    final status = event.status;
    // Emitimos el evento para realizar el cambio
    emit(state.copyWith(status: status));
    _getFCMToken();
  }

  static Future<void> initializeFCM() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  void _initialStatusCheck() async {
    //* para saber el estado actual
    final settings = await messaging.getNotificationSettings();
    add(NotificationStatusChange(settings.authorizationStatus));
  }

  //* Obtener el token
  void _getFCMToken() async {
    if (state.status != AuthorizationStatus.authorized) return;
    final token = await messaging.getToken();
    print(token);
  }

  void handleRemoteMessage(RemoteMessage message) {
    if (message.notification == null) return;
    final notification = PushMessage(
        messageId:
            message.messageId?.replaceAll(':', '').replaceAll('%', '') ?? '',
        title: message.notification!.title ?? '',
        body: message.notification!.body ?? '',
        sentDate: message.sentTime ?? DateTime.now(),
        data: message.data,
        imageUrl: Platform.isAndroid
            ? message.notification!.android?.imageUrl
            : message.notification!.apple?.imageUrl);

    //* Nuevo evento
    add(NotificationReceived(notification));
  }

  void _onForegroungMessage() {
    FirebaseMessaging.onMessage.listen(handleRemoteMessage);
  }

  void requestPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );
    // con el add llamamos el evento
    add(NotificationStatusChange(settings.authorizationStatus));
  }

  PushMessage? getMessagesById(String pushMessageId) {
    final exist = state.notifications
        .any((element) => element.messageId == pushMessageId);
    if (!exist) return null;
    return state.notifications
        .firstWhere((element) => element.messageId == pushMessageId);
  }
}
