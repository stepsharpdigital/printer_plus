// ignore_for_file: public_member_api_docs

import 'package:printer_plus/src/enums/connection_type.dart';
import 'package:printer_plus/src/models/pos_printer.dart';

class USBPrinter extends POSPrinter {
  USBPrinter({
    String? id,
    String? name,
    String? address,
    int? deviceId,
    int? vendorId,
    int? productId,
    bool connected = false,
    int type = 0,
  }) {
    this.id = id;
    this.name = name;
    this.address = address;
    this.deviceId = deviceId;
    this.vendorId = vendorId;
    this.productId = productId;
    this.connected = connected;
    this.type = type;
    this.connectionType = ConnectionType.usb;
  }
}
