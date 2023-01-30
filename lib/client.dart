import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:io' show WebSocket;

import 'package:msgpack_dart/msgpack_dart.dart';

import 'ouisync_plugin.dart' show Error;

/// Client to interface with ouisync
class Client {
  final WebSocket _socket;
  final _responses = HashMap<int, Completer<Object?>>();
  final _subscriptions = HashMap<int, StreamSink<Object?>>();
  int _nextMessageId = 0;

  Client._(this._socket);

  static Future<Client> connect(String endpoint) async {
    final socket = await WebSocket.connect('ws://$endpoint');
    final client = Client._(socket);

    unawaited(client._receive());

    return client;
  }

  Future<Object?> invoke(String method, Object? args) async {
    final id = _getMessageId();
    final completer = Completer();

    _responses[id] = completer;

    try {
      final message = serialize({
        'id': id,
        'method': method,
        'args': args,
      });

      _socket.add(message);

      return await completer.future;
    } finally {
      _responses.remove(id);
    }
  }

  Future<void> close() async {
    await _socket.close();
  }

  Future<void> _receive() async {
    await for (final data in _socket) {
      final Uint8List bytes;
      if (data is List<int>) {
        bytes = Uint8List.fromList(data);
      } else {
        continue;
      }

      final message = deserialize(bytes);

      if (message is! Map) {
        continue;
      }

      final id = message['id'];
      if (id is! int) {
        continue;
      }

      final responseCompleter = _responses.remove(id);
      if (responseCompleter != null) {
        if (message.containsKey('success')) {
          _handleResponseSuccess(responseCompleter, message['success']);
        } else if (message.containsKey('failure')) {
          _handleResponseFailure(responseCompleter, message['failure']);
        } else {
          _handleInvalidResponse(responseCompleter);
        }
      }

      final subscription = _subscriptions[id];
      if (subscription != null) {
        subscription.add(message['payload']);
      }
    }
  }

  void _handleResponseSuccess(Completer<Object?> completer, Object? payload) {
    completer.complete(payload);
  }

  void _handleResponseFailure(Completer<Object?> completer, Object? payload) {
    if (payload is! Map) {
      _handleInvalidResponse(completer);
      return;
    }

    final code = payload['code'];
    final message = payload['message'];

    if (code is! int || message is! String) {
      _handleInvalidResponse(completer);
      return;
    }

    final error = Error(code, message);
    completer.completeError(error);
  }

  void _handleInvalidResponse(Completer<Object?> completer) {
    final error = Exception('invalid response');
    completer.completeError(error);
  }

  int _getMessageId() {
    final id = _nextMessageId;
    ++_nextMessageId;
    return id;
  }
}

class Subscription {
  final Client _client;
  final StreamController<Object?> _controller;
  final String _name;
  final Object? _arg;
  int _id = 0;

  Subscription(this._client, this._name, this._arg)
      : _controller = StreamController() {
    final sink = _controller.sink;

    _controller.onListen = () async {
      assert(_id == 0);

      _id = await _client.invoke('${_name}_subscribe', _arg) as int;
      _client._subscriptions[_id] = sink;
    };

    _controller.onCancel = () async {
      assert(_id != 0);

      _client._subscriptions.remove(_id);
      await _client.invoke('unsubscribe', _id);
    };
  }

  Stream<Object?> get stream => _controller.stream;

  Future<void> close() async {
    if (_controller.hasListener) {
      await _controller.close();
    }
  }
}
