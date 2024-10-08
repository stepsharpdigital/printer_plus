import 'package:printer_plus/src/enums/connection_type.dart';
import 'package:printer_plus/src/models/pos_printer.dart';

class BluetoothPrinter extends POSPrinter {
  BluetoothPrinter({
    String? id,
    String? name,
    String? address,
    bool connected: false,
    int type: 0,
  }) {
    this.id = id;
    this.name = name;
    this.address = address;
    this.connected = connected;
    this.type = type;
    this.connectionType = ConnectionType.bluetooth;
  }
}
