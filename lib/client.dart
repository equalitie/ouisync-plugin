import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:msgpack_dart/msgpack_dart.dart';

import 'bindings_global.dart';
import 'ouisync_plugin.dart' show Error;

/// Client to interface with ouisync
class Client {
  final int _session;
  final Stream<Uint8List> _stream;
  final _responses = HashMap<int, Completer<Object?>>();
  final _subscriptions = HashMap<int, StreamSink<Object?>>();
  int _nextMessageId = 0;

  Client(this._session, ReceivePort port) : _stream = port.cast<Uint8List>() {
    unawaited(_receive());
  }

  Future<T> invoke<T>(String method, [Object? args]) async {
    final id = _getMessageId();
    final completer = Completer();

    _responses[id] = completer;

    final request = {method: args};

    // DEBUG
    //print('send: id: $id, request: $request');

    try {
      // Message format:
      //
      // +-------------------------------------+-------------------------------------------+
      // | id (big endian 64 bit unsigned int) | request (messagepack encoded byte string) |
      // +-------------------------------------+-------------------------------------------+
      //
      // This allows the server to decode the id even if the request is malformed so it can send
      // error response back.
      final message = (BytesBuilder()
            ..add((ByteData(8)..setUint64(0, id)).buffer.asUint8List())
            ..add(serialize(request)))
          .takeBytes();

      _send(message);

      return await completer.future as T;
    } finally {
      _responses.remove(id);
    }
  }

  void _send(Uint8List data) {
    // TODO: is there a way to do this without having to allocate whole new buffer?
    var buffer = malloc<Uint8>(data.length);

    try {
      buffer.asTypedList(data.length).setAll(0, data);
      bindings.session_channel_send(_session, buffer, data.length);
    } finally {
      malloc.free(buffer);
    }
  }

  Future<void> _receive() async {
    await for (final bytes in _stream) {
      if (bytes.length < 8) {
        continue;
      }

      final id = bytes.buffer.asByteData().getUint64(0);
      final message = deserialize(bytes.sublist(8));

      // DEBUG
      //print('recv: id: $id, message: $message');

      if (message is! Map) {
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

        _handleNotification(subscription, message['notification']);
      }
    }
  }

  void _handleResponseSuccess(Completer<Object?> completer, Object? payload) {
    if (payload == "none") {
      completer.complete(null);
      return;
    }

    if (payload is Map && payload.length == 1) {
      completer.complete(payload.entries.single.value);
    } else {
      _handleInvalidResponse(completer);
    }
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

  void _handleNotification(StreamSink<Object?> sink, Object? payload) {
    if (payload is String) {
      sink.add(null);
    } else if (payload is Map && payload.length == 1) {
      sink.add(payload.entries.single.value);
    } else {
      final error = Exception('invalid notification');
      sink.addError(error);
    }
  }
}

class Subscription {
  final Client _client;
  final StreamController<Object?> _controller;
  final String _name;
  final Object? _arg;
  int _id = 0;
  _SubscriptionState _state = _SubscriptionState.idle;

  Subscription(this._client, this._name, this._arg)
      : _controller = StreamController.broadcast() {
    _controller.onListen = () => _switch(_SubscriptionState.subscribing);
    _controller.onCancel = () => _switch(_SubscriptionState.unsubscribing);
  }

  Stream<Object?> get stream => _controller.stream;

  Future<void> close() async {
    if (_controller.hasListener) {
      await _controller.close();
    }
  }

  Future<void> _switch(_SubscriptionState target) async {
    switch (_state) {
      case _SubscriptionState.idle:
        _state = target;
        break;
      case _SubscriptionState.subscribing:
      case _SubscriptionState.unsubscribing:
        _state = target;
        return;
    }

    while (true) {
      final state = _state;

      switch (state) {
        case _SubscriptionState.idle:
          return;
        case _SubscriptionState.subscribing:
          await _subscribe();
          break;
        case _SubscriptionState.unsubscribing:
          await _unsubscribe();
          break;
      }

      if (_state == state) {
        _state = _SubscriptionState.idle;
      }
    }
  }

  Future<void> _subscribe() async {
    if (_id != 0) {
      return;
    }

    try {
      _id = await _client.invoke('${_name}_subscribe', _arg) as int;
      _client._subscriptions[_id] = _controller.sink;
    } catch (e) {
      print('failed to subscribe to $_name: $e');
    }
  }

  Future<void> _unsubscribe() async {
    if (_id == 0) {
      return;
    }

    _client._subscriptions.remove(_id);

    try {
      await _client.invoke('unsubscribe', _id);
    } catch (e) {
      print('failed to unsubscribe from $_name: $e');
    }

    _id = 0;
  }
}

enum _SubscriptionState {
  idle,
  subscribing,
  unsubscribing,
}
