// ignore_for_file: public_member_api_docs, sort_constructors_first, sort_unnamed_constructors_first

import 'dart:convert';

import 'package:printer_plus/src/enums/bluetooth_printer_type.dart';
import 'package:printer_plus/src/enums/connection_type.dart';

class POSPrinter {
  String? id;
  String? name;
  String? address;
  int? deviceId;
  int? vendorId;
  int? productId;
  bool? connected;
  int type;
  BluetoothPrinterType? get bluetoothType => type.printerType();
  ConnectionType? connectionType;

  factory POSPrinter.instance() => POSPrinter();

  POSPrinter({
    this.id = '',
    this.name = '',
    this.address = '',
    this.deviceId = -1,
    this.vendorId = -1,
    this.productId = -1,
    this.connected = false,
    this.type = 0,
    this.connectionType,
  });

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    if (id != null) {
      result.addAll({'id': id});
    }
    if (name != null) {
      result.addAll({'name': name});
    }
    if (address != null) {
      result.addAll({'address': address});
    }
    if (deviceId != null) {
      result.addAll({'deviceId': deviceId});
    }
    if (vendorId != null) {
      result.addAll({'vendorId': vendorId});
    }
    if (productId != null) {
      result.addAll({'productId': productId});
    }
    if (connected != null) {
      result.addAll({'connected': connected});
    }
    result.addAll({'type': type});
    if (connectionType != null) {
      result.addAll({'connectionType': connectionType!.name});
    }

    return result;
  }

  factory POSPrinter.fromMap(Map<String, dynamic> map) {
    return POSPrinter(
      id: map['id'] as String?,
      name: map['name'] as String?,
      address: map['address'] as String?,
      deviceId: map['deviceId'] as int?,
      vendorId: map['vendorId'] as int?,
      productId: map['productId'] as int?,
      connected: map['connected'] as bool?,
      type: (map['type'] as int?) ?? 0,
      connectionType: map['connectionType'] != null
          ? (map['connectionType'] as String?)?.toType()
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory POSPrinter.fromJson(String source) =>
      POSPrinter.fromMap(json.decode(source) as Map<String, dynamic>);
}

extension on int? {
  BluetoothPrinterType printerType() {
    BluetoothPrinterType value;
    switch (this) {
      case 1:
        value = BluetoothPrinterType.classic;
        break;
      case 2:
        value = BluetoothPrinterType.le;
        break;
      case 3:
        value = BluetoothPrinterType.dual;
        break;
      default:
        value = BluetoothPrinterType.unknown;
    }
    return value;
  }
}
