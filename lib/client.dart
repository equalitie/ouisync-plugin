import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:msgpack_dart/msgpack_dart.dart';

import 'ouisync_plugin.dart' show Error;

/// Client to interface with ouisync
class Client {
  final ClientSocket _socket;
  final _responses = HashMap<int, Completer<Object?>>();
  final _subscriptions = HashMap<int, StreamSink<Object?>>();
  int _nextMessageId = 0;

  Client(this._socket) {
    unawaited(_receive());
  }

  Future<T> invoke<T>(String method, [Object? args]) async {
    final id = _getMessageId();
    final completer = Completer();

    _responses[id] = completer;

    // DEBUG
    //print('send: id: $id, method: $method, args: $args');

    try {
      final message = serialize({
        'id': id,
        'method': method,
        'args': args,
      });

      _socket.sink.add(message);

      return await completer.future as T;
    } finally {
      _responses.remove(id);
    }
  }

  Future<void> close() async {
    await _socket.close();
  }

  Future<void> _receive() async {
    await for (final bytes in _socket.stream) {
      final message = deserialize(bytes);

      // DEBUG
      //print('received: $message');

      if (message is! Map) {
        continue;
      }

      final id = message['id'];
      if (id is! int) {
        continue;
      }

      final isSuccess = message.containsKey('success');
      final isFailure = message.containsKey('failure');
      final responseCompleter = _responses.remove(id);

      if (isSuccess || isFailure) {
        if (responseCompleter == null) {
          print('unsolicited response');
          continue;
        }

        if (isSuccess) {
          _handleResponseSuccess(responseCompleter, message['success']);
        } else if (isFailure) {
          _handleResponseFailure(responseCompleter, message['failure']);
        }
      } else if (responseCompleter != null) {
        _handleInvalidResponse(responseCompleter);
      }

      if (message.containsKey('notification')) {
        final subscription = _subscriptions[id];
        if (subscription == null) {
          print('unsolicited notification');
          continue;
        }

        subscription.add(message['notification']);
      }
    }
  }

  void _handleResponseSuccess(Completer<Object?> completer, Object? payload) {
    completer.complete(payload);
  }

  void _handleResponseFailure(Completer<Object?> completer, Object? payload) {
    if (payload is! List) {
      _handleInvalidResponse(completer);
      return;
    }

    final code = payload[0];
    final message = payload[1];

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
      : _controller = StreamController.broadcast() {
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

class ClientSocket {
  final Stream<Uint8List> stream;
  final Sink<Uint8List> sink;

  ClientSocket(this.stream, this.sink);

  Future<void> close() {
    sink.close();
    return Future.value();
  }
}
