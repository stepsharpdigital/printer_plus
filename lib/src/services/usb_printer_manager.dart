// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:printer_plus/src/enums/connection_response.dart';
import 'package:printer_plus/src/models/pos_printer.dart';
import 'package:printer_plus/src/models/usb_printer.dart';
import 'package:printer_plus/src/printer_plus.dart';
import 'package:printer_plus/src/services/printer_manager.dart';
import 'package:printer_plus/src/services/usb_service.dart';
import 'package:win32/win32.dart';

/// USB Printer
class USBPrinterManager extends PrinterManager {
  /// usb_serial
  FlutterUsbPrinter usbPrinter = FlutterUsbPrinter();

  /// [win32]
  Pointer<IntPtr> phPrinter = calloc<HANDLE>();
  Pointer<Utf16> pDocName = 'My Document'.toNativeUtf16();
  Pointer<Utf16> pDataType = 'RAW'.toNativeUtf16();
  Pointer<Uint32> dwBytesWritten = calloc<DWORD>();
  late Pointer<DOC_INFO_1> docInfo;
  late Pointer<Utf16> szPrinterName;
  late int hPrinter;
  late int dwCount;

  USBPrinterManager(
    POSPrinter printer,
    PaperSize paperSize,
    CapabilityProfile profile, {
    int spaceBetweenRows = 5,
    int port: 9100,
  }) {
    super.printer = printer;
    super.address = printer.address;
    super.productId = printer.productId;
    super.deviceId = printer.deviceId;
    super.vendorId = printer.vendorId;
    super.paperSize = paperSize;
    super.profile = profile;
    super.spaceBetweenRows = spaceBetweenRows;
    super.port = port;
    generator =
        Generator(paperSize, profile, spaceBetweenRows: spaceBetweenRows);
  }

  @override
  Future<ConnectionResponse> connect(
      {Duration timeout: const Duration(seconds: 5)}) async {
    if (Platform.isWindows) {
      try {
        docInfo = calloc<DOC_INFO_1>()
          ..ref.pDocName = pDocName
          ..ref.pOutputFile = nullptr
          ..ref.pDatatype = pDataType;
        szPrinterName = printer!.name!.toNativeUtf16();

        final phPrinter = calloc<HANDLE>();
        if (OpenPrinter(szPrinterName, phPrinter, nullptr) == FALSE) {
          PrinterPlus.logger.error('can not open');
          isConnected = false;
          printer!.connected = false;
        } else {
          PrinterPlus.logger.info('szPrinterName: $szPrinterName');
          hPrinter = phPrinter.value;
          isConnected = true;
          printer!.connected = true;
        }

        return Future<ConnectionResponse>.value(ConnectionResponse.success);
      } catch (e) {
        isConnected = false;
        printer!.connected = false;
        return Future<ConnectionResponse>.value(ConnectionResponse.timeout);
      }
    } else if (Platform.isAndroid) {
      assert(vendorId != null, 'Vendor Id cannot be null');
      assert(productId != null, 'Product Id cannot be null');
      final usbDevice = await usbPrinter.connect(vendorId!, productId!);
      if (usbDevice != null) {
        print('vendorId $vendorId, productId $productId ');
        isConnected = true;
        printer!.connected = true;
        return Future<ConnectionResponse>.value(ConnectionResponse.success);
      } else {
        isConnected = false;
        printer!.connected = false;
        return Future<ConnectionResponse>.value(ConnectionResponse.timeout);
      }
    } else {
      return Future<ConnectionResponse>.value(ConnectionResponse.timeout);
    }
  }

  /// [discover] let you explore all netWork printer in your network
  static Future<List<USBPrinter>> discover() async {
    final results = await USBService.findUSBPrinter();
    return results;
  }

  @override
  Future<ConnectionResponse> disconnect({Duration? timeout}) async {
    if (Platform.isWindows) {
      // Tidy up the printer handle.
      ClosePrinter(hPrinter);
      free(phPrinter);
      free(pDocName);
      free(pDataType);
      free(docInfo);
      free(dwBytesWritten);
      isConnected = false;
      printer!.connected = false;
      if (timeout != null) {
        await Future.delayed(timeout, () => null);
      }
      return ConnectionResponse.success;
    } else if (Platform.isAndroid) {
      await usbPrinter.close();
      isConnected = false;
      printer!.connected = false;
      if (timeout != null) {
        await Future.delayed(timeout, () => null);
      }
      return ConnectionResponse.success;
    }
    return ConnectionResponse.timeout;
  }

  @override
  Future<dynamic> sendData(List<int> data, {bool isDisconnect = true}) async {
    if (Platform.isWindows) {
      try {
        if (!isConnected) {
          await connect();
        }
        // Inform the spooler the document is beginning.
        final dwJob = StartDocPrinter(hPrinter, 1, docInfo);
        if (dwJob == 0) {
          ClosePrinter(hPrinter);
          return false;
        }
        // Start a page.
        if (StartPagePrinter(hPrinter) == 0) {
          EndDocPrinter(hPrinter);
          ClosePrinter(hPrinter);
          return false;
        }

        // Send the data to the printer.
        final lpData = data.toUint8();
        dwCount = data.length;
        if (WritePrinter(hPrinter, lpData, dwCount, dwBytesWritten) == 0) {
          EndPagePrinter(hPrinter);
          EndDocPrinter(hPrinter);
          ClosePrinter(hPrinter);
          return false;
        }
        // End the page.
        if (EndPagePrinter(hPrinter) == 0) {
          EndDocPrinter(hPrinter);
          ClosePrinter(hPrinter);
          return false;
        }
        // Inform the spooler that the document is ending.
        if (EndDocPrinter(hPrinter) == 0) {
          ClosePrinter(hPrinter);
          return false;
        }
        if (isDisconnect) {
          // Tidy up the printer handle.
          ClosePrinter(hPrinter);
          // Check to see if correct number of bytes were written.
          if (dwBytesWritten.value != dwCount) return false;
          return true;
        }
      } catch (e) {
        PrinterPlus.logger.error('Error : $e');
      }

      free(phPrinter);
      free(pDocName);
      free(pDataType);
      free(docInfo);
      free(dwBytesWritten);
    } else if (Platform.isAndroid) {
      PrinterPlus.logger('start write');
      final bytes = Uint8List.fromList(data);
      final max = 16384;

      /// maxChunk limit on android
      final datas = bytes.chunkBy(max);
      await Future.forEach(
          datas, (data) async => usbPrinter.write(Uint8List.fromList(data)));
      PrinterPlus.logger('end write bytes.length${bytes.length}');
      if (isDisconnect) {
        try {
          await usbPrinter.close();
          isConnected = false;
          printer!.connected = false;
        } catch (e) {
          PrinterPlus.logger.error('Error : $e');
        }
      }
    }
  }

  @override
  Stream<ConnectionStatus> connectionStatus() async* {
    var status = isConnected
        ? ConnectionStatus.connected
        : ConnectionStatus.disconnected;
    yield* Stream.value(status);
  }

  @override
  Future<bool> isDeviceConnected() async {
    return isConnected;
  }
}

/// extension for converting list<int> to Unit8 to work with win32
extension on List<int> {
  Pointer<Uint8> toUint8() {
    final result = calloc<Uint8>(length);
    final nativeString = result.asTypedList(length);
    nativeString.setAll(0, this);
    return result;
  }

  List<List<int>> chunkBy(int value) {
    var result = <List<int>>[];
    final size = length;
    var max = size ~/ value;
    final check = size % value;
    if (check > 0) {
      max += 1;
    }
    if (size <= value) {
      result = [this];
    } else {
      for (var i = 0; i < max; i++) {
        final startIndex = value * i;
        var endIndex = value * (i + 1);
        if (endIndex > size) {
          endIndex = size;
        }
        final sub = sublist(startIndex, endIndex);
        if (kDebugMode) {
          print('startIndex=$startIndex || endIndex=$endIndex');
        }
        result.add(sub);
      }
    }
    return result;
  }
}
