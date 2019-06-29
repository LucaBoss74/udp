/*
 *
 *  Copyright 2019 Kennedy Tochukwu Ekeoha
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *  1. Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *
 *  2. Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *
 *  3. Neither the name of the copyright holder nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 *  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 *  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 *  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 *  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 *  OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 *  AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 *  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 *  WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *  POSSIBILITY OF SUCH DAMAGE.
 *
 */

import 'dart:async';
import 'dart:io';
import 'udp_endpoint.dart';

typedef UDPReceiveCallback = void Function(Datagram);

/// sends or receives UDP packets.
///
/// a [UDP] instance can send or receive packets to and from [Endpoint]s.
class UDP {
  Endpoint _localep;

  /// the [Endpoint] this [UDP] instance is bound to.
  Endpoint get local => _localep;

  RawDatagramSocket _socket;

  /// a reference to underlying [RawDatagramSocket].
  RawDatagramSocket get socket => _socket;

  // internal ctor
  UDP._(this._localep);

  /// Creates a new [UDP] instance.
  ///
  /// The [UDP] instance is created by the OS and bound to a local [Endpoint].
  ///
  /// [localEndpoint] - the local endpoint.
  ///
  /// returns the [UDP] instance.
  static Future<UDP> bind(Endpoint localEndpoint) async {
    var udp = UDP._(localEndpoint);

    await RawDatagramSocket.bind(
            localEndpoint.address, localEndpoint.port.value)
        .then((socket) {
      udp._socket = socket;
    });

    return udp;
  }

  /// Sends some [data] to a [remoteEndpoint].
  ///
  /// [data] - the data to send.
  /// [remoteEndpoint] - the remote endpoint.
  ///
  /// returns the number of bytes sent.
  Future<int> send(List<int> data, Endpoint remoteEndpoint) async {
    return Future.microtask(() async {
      var prevState = _socket.broadcastEnabled;
      if (remoteEndpoint.isBroadcast) {
        _socket.broadcastEnabled = true;
      }

      var _dataCount =
          _socket.send(data, remoteEndpoint.address, remoteEndpoint.port.value);

      _socket.broadcastEnabled = prevState;

      return _dataCount;
    });
  }

  /// Tells the [UDP] instance to listen for incoming messages for a certain
  /// amount of time.
  ///
  ///
  /// After the duration specfied by [timeout] has passed, the [UDP] instance
  /// stops listening.
  /// whenever new data is received, it is bundled in a [Datagram] and passed
  /// to the specified [callback].
  ///
  /// returns a [Future] that completes when the time runs out.
  Future<void> listen(UDPReceiveCallback callback, Duration timeout) async {
    // callback must not be null.
    assert(callback != null);

    StreamSubscription subscription;

    subscription = _socket.listen((event) {
      if (event == RawSocketEvent.read) {
        callback(_socket.receive());
      }
    });

    return Future.delayed(timeout).then((value) {
      subscription?.cancel();
    });
  }

  /// closes the [UDP] instance and the underlying socket.
  void close() => _socket?.close();
}