import 'package:network_info_plus/network_info_plus.dart';
import 'package:printer_plus/src/helpers/network_analyzer.dart';
import 'package:printer_plus/src/printer_plus.dart';

class NetworkService {}

Future<List<String>> findNetworkPrinter({int port: 9100}) async {
  final String? ip = await (NetworkInfo().getWifiIP());
  PrinterPlus.logger.info("ip: $ip");
  if (ip != null) {
    final String subnet = ip.substring(0, ip.lastIndexOf('.'));
    PrinterPlus.logger.info("subnet: $subnet");

    final stream = NetworkAnalyzer.discover2(subnet, port);
    var results = await stream.toList();
    return [
      ...results
          .where((entry) => entry.exists)
          .toList()
          .map((e) => e.ip)
          .toList()
    ];
  }
  return [];
}
