// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:io';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:printer_plus/src/enums/connection_response.dart';
import 'package:printer_plus/src/models/network_printer.dart';
import 'package:printer_plus/src/models/pos_printer.dart';
import 'package:printer_plus/src/printer_plus.dart';
import 'package:printer_plus/src/services/network_service.dart';
import 'package:printer_plus/src/services/printer_manager.dart';

/// Network Printer
class NetworkPrinterManager extends PrinterManager {
  Socket? socket;

  NetworkPrinterManager(
    POSPrinter printer,
    PaperSize paperSize,
    CapabilityProfile profile, {
    int spaceBetweenRows = 5,
    int port = 9100,
  }) {
    super.printer = printer;
    super.address = printer.address;
    super.paperSize = paperSize;
    super.profile = profile;
    super.spaceBetweenRows = spaceBetweenRows;
    super.port = port;
    generator =
        Generator(paperSize, profile, spaceBetweenRows: spaceBetweenRows);
  }

  /// [connect] let you connect to a network printer
  @override
  Future<ConnectionResponse> connect({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      socket = null;
      socket = await Socket.connect(address, port, timeout: timeout);
      isConnected = true;
      printer!.connected = true;
      return Future<ConnectionResponse>.value(ConnectionResponse.success);
    } catch (e) {
      isConnected = false;
      printer!.connected = false;
      return Future<ConnectionResponse>.value(ConnectionResponse.timeout);
    }
  }

  /// [discover] let you explore all netWork printer in your network
  static Future<List<NetWorkPrinter>> discover() async {
    final results = await findNetworkPrinter();
    return [
      ...results.map(
        (e) => NetWorkPrinter(
          id: e,
          name: e,
          address: e,
        ),
      )
    ];
  }

  /// [sendData] let you write raw list int data into socket
  @override
  Future<dynamic> sendData(List<int> data, {bool isDisconnect = true}) async {
    try {
      if (!isConnected) {
        await connect();
      }
      if (kDebugMode) {
        print(socket);
      }
      socket?.add(data);
      if (isDisconnect) {
        await disconnect();
      }
    } catch (e) {
      PrinterPlus.logger.error('Error : $e');
    }
  }

  /// [timeout]: milliseconds to wait after closing the socket
  @override
  Future<ConnectionResponse> disconnect({Duration? timeout}) async {
    await socket?.flush();
    await socket?.close();
    isConnected = false;
    if (timeout != null) {
      await Future.delayed(timeout, () => null);
    }
    return ConnectionResponse.success;
  }

  @override
  Stream<ConnectionStatus> connectionStatus() {
    return Stream.periodic(
      const Duration(seconds: 3),
      (computationCount) => isConnected
          ? ConnectionStatus.connected
          : ConnectionStatus.disconnected,
    );
  }

  @override
  Future<bool> isDeviceConnected() async {
    return isConnected;
  }
}
