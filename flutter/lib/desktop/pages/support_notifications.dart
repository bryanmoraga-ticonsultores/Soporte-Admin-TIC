import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_hbb/common/widgets/peer_tab_page.dart' show RefreshWidget;
import 'package:flutter_hbb/common.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:window_manager/window_manager.dart';

class SupportNotification {
  final String requestId;
  final String id;
  final String hostname;
  final String timestamp;
  final String reason;
  SupportNotification({
    required this.requestId,
    required this.id,
    required this.hostname,
    required this.timestamp,
    required this.reason,
  });


  factory SupportNotification.fromJson(Map<String, dynamic> json) {
    return SupportNotification(
      requestId: json['request_id'] ?? '',
      id: json['id'] ?? '',
      hostname: json['hostname'] ?? '',
      timestamp: json['timestamp'] ?? '',
      reason: json['reason'] ?? '',
    );
  }
}


class SupportNotificationsPanel extends StatefulWidget {
  const SupportNotificationsPanel({Key? key}) : super(key: key);


  @override
  State<SupportNotificationsPanel> createState() => _SupportNotificationsPanelState();
}


class _SupportNotificationsPanelState extends State<SupportNotificationsPanel> with WindowListener {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<SupportNotification> _notifications = [];
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _healthCheckTimer;
  bool _disposed = false;
  bool _isConnected = false;
  DateTime _lastActivity = DateTime.now();


  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _connect();
    _healthCheckTimer = Timer.periodic(Duration(minutes: 2), (_){
      _checkAndRecconect();
    });
  }


  bool _isWithinWorkHours() {
    final now = DateTime.now();
    return now.hour >=8 && now.hour < 18;
  }


  void _checkAndRecconect() {
    if (_disposed) return;


    final silence = DateTime.now().difference(_lastActivity);
    final zombieConnection = _isConnected && silence > Duration(seconds: 90);


    if (zombieConnection) {
      print('[WS] conexión zombie detectada (sin actividad ${silence.inSeconds}s, forzando reconexión...)');
      _channel?.sink.close();
      _channel = null;
      setState(() => _isConnected = false);
      _connect();
      return;
    }


    if (!_isConnected && _isWithinWorkHours()) {
      print('[WS] health check: desconectado en horario laboral, reconectando...');
      _connect();
    }
  }


  @override
  void onWindowFocus() {
    /**if (Platform.isWindows) {
      WindowsTaskbar.resetFlashTaskbarAppIcon();
    }**/
    if (!_isConnected) {
      print('[WS] ventana recuperó foco, forzando reconexión...');
      _connect();
    }
  }


  @override
  void dispose() {
    windowManager.removeListener(this);
    _disposed = true;
    _reconnectTimer?.cancel();
    _healthCheckTimer?.cancel();
    _channel?.sink.close();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playNotificationSound() async {
    try {
      print("[Audio] Attempting to play notification sound...");
      // macOS (y cualquier otra plataforma no-Windows): reproducir el
      // asset directamente con audioplayers, sin pasar por un temp file.
      await _audioPlayer.play(AssetSource('sound/notification.wav'));
      print("[Audio] SUCCESS: audioplayers reproduciendo el asset.");
    } catch (e) {
      // silencioso
      print("[Audio] ERROR: Exception occurred: $e");
    }
  }

  bool _connecting = false;
  void _connect() {
    if (_connecting) {
      print("[WS] Ya hay un intento de conexión en curso, se omite...");
      return;
    }
    _connecting = true;
    // Cierra cualquier conexión previa, evitando sockets duplicados.
    _channel?.sink.close();
    _channel = null;
    

    print('[WS] intentando conectar...');
    _lastActivity = DateTime.now();
    try {
      final clientId = _stableClientId();
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://<SERVER_ADDR>/api/support/ws?client_id=${Uri.encodeComponent(clientId)}'),
      );
      _channel!.stream.listen(
        (message) {
          if (_disposed) return;
          _lastActivity = DateTime.now();
          print('[WS] mensaje crudo recibido: $message');
          if (!_isConnected){
            setState(() => _isConnected = true);
          }
          final data = jsonDecode(message);
          final type = data['type'];
          print('[WS] type=$type');


          if (type == 'new_request') {
            setState(() {
              _notifications.insert(
                  0, SupportNotification.fromJson(data['data']));
            });
            _playNotificationSound();
            /**if (Platform.isWindows) {
                WindowsTaskbar.setFlashTaskbarAppIcon(
                mode: TaskbarFlashMode.all,
                timeout: const Duration(milliseconds: 1000),
              );
            }**/
          } else if (type == 'remove_request') {
            final requestId = data['request_id'];
            setState(() {
              _notifications.removeWhere((n) => n.requestId == requestId);
            });
          }
        },
        onDone: () {
          print('[WS] conexión cerrada (onDone)');
          setState(() => _isConnected = false);
          _channel = null;
          _scheduleReconnect();
          },
        onError: (e) {
          print('[WS] error en el stream: $e');
          setState(() => _isConnected = false);
          _channel = null;
          _scheduleReconnect();
          },
      );
      setState(() => _isConnected = true);
    } catch (e) {
      print('[WS] exepción al conectar: $e');
      setState(() => _isConnected = false);
      _channel = null;
      _scheduleReconnect();
    } finally {
      _connecting = false;
    } 
  }


  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: 5), _connect);
  }

  String _stableClientId() {
    try {
      return Platform.localHostname;
    } catch (e) {
      print('[WS] no se pudo obtener localHostname, usando fallback: $e');
      return 'admin-unknown';
    }
  }

  void _handleConnect(SupportNotification n) {
    print('[WS] intentando remover requestId=${n.requestId}');
    connect(context, n.id);

    // feedback inmediato local
    setState(() {
      _notifications.removeWhere((x) => x.requestId == n.requestId);
    });

    // avisar a los demás admins
    _channel?.sink.add(jsonEncode({
      'type': 'handled',
      'request_id': n.requestId,
    }));
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(13)),
        border: Border.all(color: Theme.of(context).colorScheme.background),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isConnected ? Colors.green : Colors.red,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text('Solicitudes de asistencia',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              Tooltip(
                message: translate('Reconnect'),
                child: RefreshWidget(
                  onPressed: () {
                    print('[WS] reconexión manual solicitada');
                    _connect();
                  },
                  child: Icon(
                    Icons.refresh,
                    size: 18,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          SizedBox(
            height: 105,
            child: _notifications.isEmpty
                ? Center(
                    child: Text('Sin solicitudes por ahora',
                        style: Theme.of(context).textTheme.bodySmall),
                  )
                : ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => Divider(height: 12),
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      return Container(
                        //margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            //Expanded(
                              /*child:*/ Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('ID: ${n.id}',
                                      style: Theme.of(context).textTheme.bodySmall),
                                  Text(n.hostname,
                                      style: Theme.of(context).textTheme.bodySmall),
                                  if (n.reason.trim().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        n.reason,
                                        style: Theme.of(context).textTheme.bodySmall
                                            ?.copyWith(fontStyle: FontStyle.italic),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  Text(n.timestamp,
                                      style: Theme.of(context).textTheme.bodySmall
                                          ?.copyWith(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            //),
                            ElevatedButton(
                                onPressed: () => _handleConnect(n),
                                child: Text('Conectar'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
