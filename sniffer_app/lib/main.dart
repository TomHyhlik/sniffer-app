import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE sniff',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          onPrimary: Colors.black,
          surface: Color(0xFF111111),
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.white,
          dividerColor: Colors.grey.shade900,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
        ),
        dataTableTheme: DataTableThemeData(
          headingRowColor: WidgetStateProperty.all(const Color(0xFF1C1C1C)),
          dataRowColor: WidgetStateProperty.all(Colors.black),
          headingTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          dataTextStyle: const TextStyle(color: Colors.white, fontSize: 19),
          dividerThickness: 0.3,
        ),
        dividerColor: Colors.grey.shade900,
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF1C1C1C),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// Vendor lookup
// ---------------------------------------------------------------------------

const Map<int, String> kVendorNames = {
  0x0000: 'Ericsson',
  0x0001: 'Nokia',
  0x0002: 'Intel',
  0x0003: 'IBM',
  0x0004: 'Toshiba',
  0x0006: 'Microsoft',
  0x0008: 'Motorola',
  0x000A: 'CSR',
  0x000F: 'Broadcom',
  0x0012: 'Zeevo',
  0x0013: 'Atmel',
  0x0015: 'Texas Instruments',
  0x001D: 'Qualcomm',
  0x0022: 'Macronix',
  0x0046: 'Sony',
  0x0048: 'LG Electronics',
  0x004C: 'Apple',
  0x0057: 'Harman',
  0x0059: 'Nordic Semiconductor',
  0x005A: 'ST Microelectronics',
  0x0075: 'Samsung',
  0x0077: 'Bose',
  0x0087: 'Garmin',
  0x008A: 'Polar Electro',
  0x00CD: 'iRobot',
  0x00D7: 'NXP Semiconductors',
  0x00E0: 'Google',
  0x00E7: 'Plantronics',
  0x010F: 'Suunto',
  0x0122: 'Broadcom (2)',
  0x0131: 'Fitbit',
  0x0157: 'Huawei',
  0x0171: 'Amazon',
  0x01D0: 'Xiaomi',
  0x01FF: 'Meta Platforms',
  0x025A: 'Jabra / GN Audio',
  0x0276: 'Zebra Technologies',
  0x02D0: 'OnePlus',
  0x038E: 'Beats Electronics',
  0x038F: 'Tile',
  0x03F0: 'HP',
  0x0499: 'Ruuvi Innovations',
  0x04F8: 'OPPO',
  0x05A7: 'Sonos',
  0x05AC: 'Realtek',
  0x076E: 'Honor',
  0x089A: 'Nothing Technology',
};

String _hexId(int id) => '0x${id.toRadixString(16).padLeft(4, '0')}';

String vendorName(int? id) {
  if (id == null) return '-';
  return kVendorNames[id] ?? 'Unknown (${_hexId(id)})';
}

// ---------------------------------------------------------------------------
// Device classification
// ---------------------------------------------------------------------------

class DeviceInfo {
  final String label;
  final int? vendorId;
  const DeviceInfo(this.label, this.vendorId);
}

// Apple proximity-pairing device model codes (big-endian: bytes[2]<<8 | bytes[3])
const Map<int, String> _appleAirPodsModels = {
  0x0220: 'AirPods 1st Gen',
  0x0E20: 'AirPods 2nd Gen',
  0x1420: 'AirPods 3rd Gen',
  0x2820: 'AirPods 4th Gen',
  0x0F20: 'AirPods Pro',
  0x1920: 'AirPods Pro 2nd Gen',
  0x2420: 'AirPods Pro 2nd Gen',
  0x1320: 'AirPods Max',
  0x1B20: 'AirPods Max 2nd Gen',
  0x2020: 'Beats Studio Buds',
  0x1120: 'PowerBeats Pro',
  0x1220: 'Beats Solo Pro',
  0x1720: 'Beats Flex',
  0x0320: 'Beats X',
  0x0920: 'Beats Solo 3',
  0x0620: 'Beats Headphones',
};

DeviceInfo _classifyApple(List<int> bytes, String name, List<String> svcUuids) {
  if (bytes.isEmpty) return const DeviceInfo('Apple Device', 0x004C);

  switch (bytes[0]) {
    case 0x02: return const DeviceInfo('Apple iBeacon', 0x004C);
    case 0x03: return const DeviceInfo('Apple AirPrint Printer', 0x004C);
    case 0x05: return const DeviceInfo('Apple AirDrop', 0x004C);
    case 0x06: return const DeviceInfo('Apple HomeKit Accessory', 0x004C);

    case 0x07: // Proximity pairing — AirPods / Beats
      if (bytes.length >= 4) {
        final model = (bytes[2] << 8) | bytes[3];
        final label = _appleAirPodsModels[model];
        if (label != null) return DeviceInfo(label, 0x004C);
      }
      return const DeviceInfo('Apple AirPods', 0x004C);

    case 0x08: return const DeviceInfo('Apple Hey Siri Device', 0x004C);
    case 0x09: return const DeviceInfo('Apple AirPlay Target', 0x004C);
    case 0x0A: return const DeviceInfo('Apple AirPlay Source', 0x004C);
    case 0x0B: return const DeviceInfo('Apple Magic Switch', 0x004C);
    case 0x0C: return const DeviceInfo('Apple Handoff', 0x004C);
    case 0x0D: return const DeviceInfo('Apple Personal Hotspot', 0x004C);

    case 0x0E: // Nearby Action — sub-type byte is bytes[2]
      if (bytes.length >= 3) {
        switch (bytes[2]) {
          case 0x01: return const DeviceInfo('Apple Watch Setup', 0x004C);
          case 0x06: return const DeviceInfo('Apple TV Setup', 0x004C);
          case 0x07: return const DeviceInfo('iPhone/iPad Setup', 0x004C);
          case 0x0B: return const DeviceInfo('Apple Watch AutoUnlock', 0x004C);
          case 0x0C: return const DeviceInfo('Apple Hotspot', 0x004C);
          case 0x0D: return const DeviceInfo('Apple Join Network', 0x004C);
          case 0x13: return const DeviceInfo('Apple Transfer', 0x004C);
          case 0x20: return const DeviceInfo('Apple TV Colour Balance', 0x004C);
        }
      }
      return const DeviceInfo('Apple Nearby Action', 0x004C);

    case 0x0F: // Nearby Info — device-type nibble in status flags
      if (bytes.length >= 3) {
        final devType = (bytes[2] >> 4) & 0xF;
        switch (devType) {
          case 0x1: return const DeviceInfo('iPhone', 0x004C);
          case 0x2: return const DeviceInfo('iPad', 0x004C);
          case 0x3: return const DeviceInfo('MacBook', 0x004C);
          case 0x4: return const DeviceInfo('Apple Watch', 0x004C);
          case 0x5: return const DeviceInfo('Apple iMac', 0x004C);
          case 0x6: return const DeviceInfo('iPod Touch', 0x004C);
          case 0xA: return const DeviceInfo('Apple TV', 0x004C);
          case 0xB: return const DeviceInfo('HomePod', 0x004C);
        }
      }
      return const DeviceInfo('iPhone', 0x004C);

    case 0x10: return const DeviceInfo('Apple Find My Device', 0x004C);
    case 0x12: return const DeviceInfo('Apple AirTag', 0x004C);
    default:   return const DeviceInfo('Apple Device', 0x004C);
  }
}

DeviceInfo _classifySamsung(List<int> bytes, String name, List<String> svcUuids) {
  final n = name.toLowerCase();

  if (n.contains('smarttag') || n.contains('smart tag')) {
    return const DeviceInfo('Samsung SmartTag', 0x0075);
  }
  if (n.contains('galaxy watch') || n.contains('gear')) {
    return const DeviceInfo('Samsung Galaxy Watch', 0x0075);
  }
  if (n.contains('buds')) {
    if (n.contains('pro'))  return const DeviceInfo('Samsung Galaxy Buds Pro', 0x0075);
    if (n.contains('live')) return const DeviceInfo('Samsung Galaxy Buds Live', 0x0075);
    if (n.contains('fe'))   return const DeviceInfo('Samsung Galaxy Buds FE', 0x0075);
    if (n.contains('2'))    return const DeviceInfo('Samsung Galaxy Buds2', 0x0075);
    return const DeviceInfo('Samsung Galaxy Buds', 0x0075);
  }
  if (n.contains('galaxy') || n.startsWith('sm-')) {
    return const DeviceInfo('Samsung Galaxy Phone', 0x0075);
  }
  if (svcUuids.any((u) => u.startsWith('0000fd5a'))) {
    return const DeviceInfo('Samsung SmartTag', 0x0075);
  }
  if (bytes.length >= 2 && bytes[0] == 0x01 && bytes[1] == 0x00) {
    return const DeviceInfo('Samsung SmartTag', 0x0075);
  }
  if (bytes.isNotEmpty && bytes[0] == 0x08) {
    return const DeviceInfo('Samsung Galaxy Buds', 0x0075);
  }
  return const DeviceInfo('Samsung Device', 0x0075);
}

// Service UUID prefix → (label, vendorId)
// Matches standard GATT services and well-known proprietary UUIDs.
DeviceInfo? _classifyByServiceUuids(List<String> uuids) {
  bool has(String prefix) => uuids.any((u) => u.startsWith(prefix));

  // Proprietary / company services
  if (has('0000fe2c') || has('0000fe9f')) return const DeviceInfo('Google Fast Pair Device', 0x00E0);
  if (has('0000fd6f'))                    return const DeviceInfo('COVID Exposure Beacon', null);
  if (has('0000feaa'))                    return const DeviceInfo('Eddystone Beacon', null);
  if (has('0000fd5a'))                    return const DeviceInfo('Samsung SmartTag', 0x0075);
  if (has('0000febe'))                    return const DeviceInfo('Tile Tracker', 0x038F);
  if (has('0000fe03'))                    return const DeviceInfo('Amazon Echo', 0x0171);

  // Standard GATT services (Bluetooth SIG assigned numbers)
  if (has('00001812')) return const DeviceInfo('HID Device (keyboard/mouse/gamepad)', null);
  if (has('0000180d')) return const DeviceInfo('Heart Rate Monitor', null);
  if (has('00001816')) return const DeviceInfo('Cycling Speed & Cadence Sensor', null);
  if (has('00001818')) return const DeviceInfo('Cycling Power Meter', null);
  if (has('00001819')) return const DeviceInfo('GPS / Navigation Device', null);
  if (has('0000181a')) return const DeviceInfo('Environmental Sensor', null);
  if (has('0000181d')) return const DeviceInfo('Weight Scale', null);
  if (has('0000181e')) return const DeviceInfo('Continuous Glucose Monitor', null);
  if (has('00001826')) return const DeviceInfo('Fitness Machine', null);
  if (has('00001808')) return const DeviceInfo('Glucose Meter', null);
  if (has('00001809')) return const DeviceInfo('Health Thermometer', null);
  if (has('00001810')) return const DeviceInfo('Blood Pressure Monitor', null);
  if (has('00001822')) return const DeviceInfo('Pulse Oximeter', null);
  if (has('0000180f')) return const DeviceInfo('BLE Peripheral (battery only)', null);

  return null;
}

DeviceInfo _classifyByName(String name, int? vendorId) {
  final n = name.toLowerCase();
  if (n == '(unknown)' || n.isEmpty) return DeviceInfo(
    vendorId != null ? 'Unknown (${_hexId(vendorId)})' : 'Unknown Device', vendorId);

  if (n.contains('keyboard'))   return DeviceInfo('Keyboard', vendorId);
  if (n.contains('mouse'))      return DeviceInfo('Mouse', vendorId);
  if (n.contains('headphone') || n.contains('headset') || n.contains('earphone') || n.contains('earbuds')) {
    return DeviceInfo('Headphones', vendorId);
  }
  if (n.contains('speaker'))    return DeviceInfo('Speaker', vendorId);
  if (n.contains('watch'))      return DeviceInfo('Smartwatch', vendorId);
  if (n.contains('band'))       return DeviceInfo('Fitness Band', vendorId);
  if (n.contains('scale'))      return DeviceInfo('Scale', vendorId);
  if (n.contains('beacon'))     return DeviceInfo('Beacon', vendorId);
  if (n.contains('tracker'))    return DeviceInfo('Tracker', vendorId);
  if (n.contains('lock'))       return DeviceInfo('Smart Lock', vendorId);
  if (n.contains('bulb') || n.contains('light') || n.contains('lamp')) {
    return DeviceInfo('Smart Light', vendorId);
  }
  if (n.contains('tv') || n.contains('television')) return DeviceInfo('Smart TV', vendorId);
  if (n.contains('phone') || n.contains('iphone') || n.contains('android')) {
    return DeviceInfo('Phone', vendorId);
  }

  // Has a readable name but no type matched — show name + vendor hint
  final vendorHint = vendorId != null ? ' (${_hexId(vendorId)})' : '';
  return DeviceInfo('$name$vendorHint', vendorId);
}

DeviceInfo classifyDevice(BleDevice d) {
  switch (d.vendorId) {
    case 0x004C: return _classifyApple(d.mfDataBytes, d.name, d.serviceUuids);
    case 0x0075: return _classifySamsung(d.mfDataBytes, d.name, d.serviceUuids);
    case 0x00E0:
      if (d.serviceUuids.any((u) => u.startsWith('0000fe2c') || u.startsWith('0000fe9f'))) {
        return const DeviceInfo('Google Fast Pair Device', 0x00E0);
      }
      return const DeviceInfo('Google Device', 0x00E0);
    case 0x0059: return const DeviceInfo('Nordic Dev Board', 0x0059);
    case 0x0006: return const DeviceInfo('Microsoft Device', 0x0006);
    case 0x0131: return const DeviceInfo('Fitbit', 0x0131);
    case 0x0087: return const DeviceInfo('Garmin Watch', 0x0087);
    case 0x008A: return const DeviceInfo('Polar Watch', 0x008A);
    case 0x010F: return const DeviceInfo('Suunto Watch', 0x010F);
    case 0x0077: return const DeviceInfo('Bose Headphones', 0x0077);
    case 0x038E: return const DeviceInfo('Beats Headphones', 0x038E);
    case 0x025A: return const DeviceInfo('Jabra Headset', 0x025A);
    case 0x00E7: return const DeviceInfo('Plantronics Headset', 0x00E7);
    case 0x038F: return const DeviceInfo('Tile Tracker', 0x038F);
    case 0x0499: return const DeviceInfo('Ruuvi Tag', 0x0499);
    case 0x00CD: return const DeviceInfo('iRobot', 0x00CD);
    case 0x05A7: return const DeviceInfo('Sonos Speaker', 0x05A7);
    case 0x01D0: return const DeviceInfo('Xiaomi Device', 0x01D0);
    case 0x0157: return const DeviceInfo('Huawei Device', 0x0157);
    case 0x0171: return const DeviceInfo('Amazon Device', 0x0171);
    case 0x01FF: return const DeviceInfo('Meta VR Device', 0x01FF);
    case 0x02D0: return const DeviceInfo('OnePlus Phone', 0x02D0);
    case 0x0046: return const DeviceInfo('Sony Device', 0x0046);
    case 0x089A: return const DeviceInfo('Nothing Device', 0x089A);
    case 0x04F8: return const DeviceInfo('OPPO Device', 0x04F8);
    case 0x076E: return const DeviceInfo('Honor Device', 0x076E);
    case 0x0276: return const DeviceInfo('Zebra Scanner', 0x0276);
    case 0x005A: return const DeviceInfo('ST Microelectronics', 0x005A);
    case 0x0015: return const DeviceInfo('TI SensorTag', 0x0015);
    default:
      // Known vendor but no specific classifier → try service UUIDs then name
      if (d.vendorId != null) {
        final svcMatch = _classifyByServiceUuids(d.serviceUuids);
        if (svcMatch != null) return svcMatch;
        final v = kVendorNames[d.vendorId!];
        if (v != null) return DeviceInfo('$v Device', d.vendorId);
      }
      // No vendor ID — try service UUIDs, then name, then raw vendor hex
      final svcMatch = _classifyByServiceUuids(d.serviceUuids);
      if (svcMatch != null) return svcMatch;
      return _classifyByName(d.name, d.vendorId);
  }
}

// ---------------------------------------------------------------------------
// Company logo widget
// ---------------------------------------------------------------------------

// Vendors with a Font Awesome brand icon
Widget _vendorLogo(int? vendorId) {
  IconData? faIcon;
  switch (vendorId) {
    case 0x004C: faIcon = FontAwesomeIcons.apple; break;
    case 0x00E0: faIcon = FontAwesomeIcons.google; break;
    case 0x0006: faIcon = FontAwesomeIcons.microsoft; break;
    case 0x01FF: faIcon = FontAwesomeIcons.meta; break;
    case 0x0171: faIcon = FontAwesomeIcons.amazon; break;
  }

  if (faIcon != null) {
    return FaIcon(faIcon, color: Colors.white, size: 34);
  }

  // No vendor ID at all → generic Bluetooth icon
  if (vendorId == null) {
    return const FaIcon(FontAwesomeIcons.bluetooth, color: Colors.white, size: 30);
  }

  // Known vendor name → up to 2-letter monogram
  // Unknown vendor ID → show hex (e.g. "3F1A")
  final name = kVendorNames[vendorId];
  String mono;
  if (name != null) {
    final words = name.split(RegExp(r'[\s/()+]+'));
    mono = words.take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    if (mono.isEmpty) mono = name[0].toUpperCase();
  } else {
    mono = vendorId.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  return Container(
    width: 40,
    height: 24,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade600, width: 1),
      borderRadius: BorderRadius.circular(4),
    ),
    alignment: Alignment.center,
    child: Text(
      mono,
      style: TextStyle(
        color: Colors.white,
        fontSize: mono.length > 2 ? 12 : 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class BleDevice {
  final String id;
  final String name;
  int rssi;
  final int? vendorId;
  final List<int> mfDataBytes;
  final List<String> serviceUuids;
  final String advData;
  DateTime lastSeen;
  int? periodMs;

  BleDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.vendorId,
    required this.mfDataBytes,
    required this.serviceUuids,
    required this.advData,
  })  : lastSeen = DateTime.now(),
        periodMs = null;
}

// ---------------------------------------------------------------------------
// UI
// ---------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final Map<String, BleDevice> _devices = {};
  StreamSubscription<List<ScanResult>>? _scanSub;
  bool _scanning = false;
  late final TabController _tabController;
  List<BleDevice>? _sortedCache;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scanSub?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  List<BleDevice> get _sortedDevices {
    _sortedCache ??= _devices.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));
    return _sortedCache!;
  }

  Future<void> _startScan() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    final denied = statuses.values.any((s) => s.isDenied || s.isPermanentlyDenied);
    if (denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth/location permissions required')),
        );
      }
      return;
    }

    setState(() {
      _devices.clear();
      _sortedCache = null;
      _scanning = true;
    });

    await FlutterBluePlus.startScan(androidUsesFineLocation: false);

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      bool changed = false;
      for (final r in results) {
        final id = r.device.remoteId.str;
        final mfData = r.advertisementData.manufacturerData;
        final int? vendorId = mfData.isNotEmpty ? mfData.keys.first : null;
        if (_devices.containsKey(id)) {
          final dev = _devices[id]!;
          final now = DateTime.now();
          dev.periodMs = now.difference(dev.lastSeen).inMilliseconds;
          dev.lastSeen = now;
          dev.rssi = r.rssi;
          changed = true;
        } else {
          final name = r.device.platformName.isNotEmpty
              ? r.device.platformName
              : '(unknown)';
          final mfDataBytes = mfData.isNotEmpty ? mfData.values.first : <int>[];
          final serviceUuids = r.advertisementData.serviceUuids
              .map((g) => g.str.toLowerCase())
              .toList();
          final advData = mfData.isNotEmpty
              ? mfData.entries
                  .map((e) =>
                      '${_hexId(e.key)}: ${e.value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}')
                  .join(', ')
              : '';
          _devices[id] = BleDevice(
            id: id,
            name: name,
            rssi: r.rssi,
            vendorId: vendorId,
            mfDataBytes: mfDataBytes,
            serviceUuids: serviceUuids,
            advData: advData,
          );
          changed = true;
        }
      }
      if (changed) {
        setState(() => _sortedCache = null);
      }
    });
  }

  Future<void> _stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSub?.cancel();
    _scanSub = null;
    setState(() => _scanning = false);
  }

  Widget _buildEmptyState() => Center(
        child: Text(
          _scanning ? 'Scanning...' : 'No devices found',
          style: const TextStyle(color: Colors.grey),
        ),
      );

  Widget _buildDashboardTab(List<BleDevice> devices) {
    if (devices.isEmpty) return _buildEmptyState();

    final counts    = <String, int>{};
    final vendorIds = <String, int?>{};
    for (final d in devices) {
      final info = classifyDevice(d);
      counts[info.label]       = (counts[info.label] ?? 0) + 1;
      vendorIds[info.label] ??= info.vendorId;
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sorted.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 68, endIndent: 16),
      itemBuilder: (context, i) {
        final entry    = sorted[i];
        final vendorId = vendorIds[entry.key];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Company logo
              SizedBox(
                width: 40,
                child: Center(child: _vendorLogo(vendorId)),
              ),
              const SizedBox(width: 12),
              // Device type label
              Expanded(
                child: Text(
                  entry.key,
                  style: const TextStyle(fontSize: 15, color: Colors.white),
                ),
              ),
              // Count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade700),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${entry.value}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDataTable(
    List<BleDevice> devices,
    List<DataColumn> columns,
    List<DataCell> Function(BleDevice) cells,
  ) {
    if (devices.isEmpty) return _buildEmptyState();
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          columns: columns,
          rows: devices.map((d) => DataRow(cells: cells(d))).toList(),
        ),
      ),
    );
  }

  Widget _buildDevicesTab(List<BleDevice> devices) => _buildDataTable(
        devices,
        const [
          DataColumn(label: Text('RSSI')),
          DataColumn(label: Text('MAC Address')),
          DataColumn(label: Text('Vendor ID')),
          DataColumn(label: Text('Manufacturer')),
        ],
        (d) => [
          DataCell(Text('${d.rssi} dBm')),
          DataCell(Text(d.id)),
          DataCell(Text(d.vendorId != null ? _hexId(d.vendorId!) : '-')),
          DataCell(Text(vendorName(d.vendorId))),
        ],
      );

  Widget _buildRawTab(List<BleDevice> devices) => _buildDataTable(
        devices,
        const [
          DataColumn(label: Text('RSSI')),
          DataColumn(label: Text('Period')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Address')),
          DataColumn(label: Text('Adv Data')),
        ],
        (d) => [
          DataCell(Text('${d.rssi} dBm')),
          DataCell(Text(d.periodMs == null ? '-' : '${d.periodMs} ms')),
          DataCell(Text(d.name)),
          DataCell(Text(d.id)),
          DataCell(Text(
            d.advData.isEmpty ? '-' : d.advData,
            overflow: TextOverflow.ellipsis,
          )),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final devices = _sortedDevices;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE sniff'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _scanning ? _stopScan : _startScan,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              child: Text(_scanning ? 'Stop' : 'Scan'),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(devices),
          _buildDevicesTab(devices),
          _buildRawTab(devices),
        ],
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Dashboard'),
          Tab(text: 'Devices'),
          Tab(text: 'Raw Packets'),
        ],
      ),
    );
  }
}
