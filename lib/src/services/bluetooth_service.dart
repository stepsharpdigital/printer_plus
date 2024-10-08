// ignore_for_file: public_member_api_docs

import 'dart:io';

import 'package:blue_thermal_printer/blue_thermal_printer.dart' as thermal;
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fblue;
import 'package:printer_plus/printer_plus.dart';

class BluetoothService {
  static Future<List<BluetoothPrinter>> findBluetoothDevice() async {
    var devices = <BluetoothPrinter>[];
    if (Platform.isAndroid) {
      final bluetooth = thermal.BlueThermalPrinter.instance;

      final isBluetoothOn = await bluetooth.isOn;

      PrinterPlus.logger.debug('Bluetooth is ON: $isBluetoothOn');

      if (isBluetoothOn ?? false) {
        final results = await bluetooth.getBondedDevices();
        devices = results
            .map(
              (d) => BluetoothPrinter(
                id: d.address ?? '',
                address: d.address ?? '',
                name: d.name ?? '',
                type: d.type,
              ),
            )
            .toList();
      }
    } else if (Platform.isIOS) {
      final btState = await fblue.FlutterBluePlus.adapterState.first;

      var isBluetoothOn = false;

      if (btState == fblue.BluetoothAdapterState.on) {
        isBluetoothOn = true;
      }

      PrinterPlus.logger.debug('Bluetooth is ON: $isBluetoothOn');
      if (isBluetoothOn) {
        final results = <fblue.BluetoothDevice>[];
        await fblue.FlutterBluePlus.startScan(
            timeout: const Duration(seconds: 10));

        fblue.FlutterBluePlus.scanResults.listen((stream) {
          for (final result in stream) {
            results.add(result.device);
          }
        });
        await fblue.FlutterBluePlus.stopScan();
        devices = results
            .toSet()
            .toList()
            .map(
              (d) => BluetoothPrinter(
                id: d.remoteId.str,
                address: d.remoteId.str,
                name: d.platformName,
              ),
            )
            .toList();
      }
    }
    return devices;
  }
}
