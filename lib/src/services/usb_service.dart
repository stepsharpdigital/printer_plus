// ignore_for_file: public_member_api_docs

import 'dart:io';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:printer_plus/src/models/usb_printer.dart';
import 'package:printing/printing.dart';

class USBService {
  static Future<List<USBPrinter>> findUSBPrinter() async {
    var devices = <USBPrinter>[];
    if (Platform.isWindows) {
      final results = await Printing.listPrinters();
      devices = [
        ...results.where((entry) => entry.isAvailable).toList().map(
              (e) => USBPrinter(
                name: e.name,
                address: e.url,
              ),
            )
      ];
    } else if (Platform.isAndroid) {
      final results = await FlutterUsbPrinter.getUSBDeviceList();

      devices = [
        ...results.map(
          (e) => USBPrinter(
            name: e['productName'] as String?,
            address: e['manufacturer'] as String?,
            vendorId: int.tryParse(e['vendorId'] as String),
            productId: int.tryParse(e['productId'] as String),
            deviceId: int.tryParse(e['deviceId'] as String),
          ),
        )
      ];
    } else {
      /// no support
    }

    return devices;
  }
}
