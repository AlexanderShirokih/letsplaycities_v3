import 'dart:io';

import 'package:flutter/services.dart';
import 'package:lets_play_cities/base/data/word_result.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/profile_info.dart';
import 'package:lets_play_cities/remote/server/back_json_message_converter.dart';
import 'package:lets_play_cities/remote/server/connection_transformer.dart';
import 'package:lets_play_cities/remote/server/lps_server_interactor.dart';
import 'package:lets_play_cities/remote/server/remote_api_server.dart';

/// Implementation of LPS local game server for remote mode
class RemoteApiServerImpl extends RemoteApiServer {
  /// Local port for server binding
  static final localPort = 8988;

  WebSocket? _serverSocket;

  LpsServerInteractor? _client;

  final ProfileInfo _owner;
  final GamePreferences _prefs;

  RemoteApiServerImpl(this._owner, this._prefs);

  @override
  Future<void> startServer() async {
    final pem = await rootBundle.loadString('assets/cert/lps.pem');

    final context = SecurityContext()..useCertificateChainBytes(pem.codeUnits);

    final server =
        await HttpServer.bindSecure(InternetAddress.anyIPv6, 8443, context);

    // TODO: Start with HTTPS to login users and upgrade to WSS when ready
    final upgradeRequest = await server.first;

    _serverSocket = await WebSocketTransformer.upgrade(upgradeRequest);
  }

  @override
  Future<ProfileInfo> awaitOpponent() async {
    if (_serverSocket == null) {
      throw RemoteException('Server socket is not started!');
    }

    final socket = await _serverSocket!.single;
    final client = WebSocketMessagePipe(socket);
    final jsonClient =
        ConvertableTransformer(client, BackJsonMessageConverter());

    _client = LpsServerInteractorImpl(jsonClient, _owner, _prefs);

    return await _client!.authorize();
  }

  @override
  Future<void> close() async {
    if (_client != null) {
      await _client!.close();
      _client = null;
    }

    if (_serverSocket == null) {
      throw RemoteException('Server socket is not started!');
    }

    await _serverSocket!.close();
  }

  @override
  Future<void> sendCity(WordResult wordResult, String city, int ownerId) {
    // TODO: implement sendCity
    throw UnimplementedError();
  }

  @override
  Future<void> sendMessage(String message, int ownerId) {
    // TODO: implement sendMessage
    throw UnimplementedError();
  }
}
