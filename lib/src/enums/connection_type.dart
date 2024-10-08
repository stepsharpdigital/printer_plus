// ignore_for_file: public_member_api_docs

enum ConnectionType { network, bluetooth, usb }

extension ConnectionTypeStringMethods on String {
  ConnectionType toType() {
    switch (this) {
      case 'network':
        return ConnectionType.network;
      case 'bluetooth':
        return ConnectionType.bluetooth;
      case 'usb':
        return ConnectionType.usb;
      default:
        return ConnectionType.network;
    }
  }
}
