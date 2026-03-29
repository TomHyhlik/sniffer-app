import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sniffer',
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
          ),
          dataTextStyle: const TextStyle(color: Colors.white),
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

// Apple manufacturer data subtype → device label
// Format: [subtype, length, ...data]
String _classifyApple(List<int> bytes) {
  if (bytes.isEmpty) return 'Apple Device';
  switch (bytes[0]) {
    case 0x02: return 'Apple iBeacon';
    case 0x03: return 'Apple AirPrint';
    case 0x05: return 'Apple AirDrop';
    case 0x06: return 'Apple HomeKit';
    case 0x07: return 'Apple AirPods';
    case 0x08: return 'Apple Hey Siri';
    case 0x09: return 'Apple AirPlay Target';
    case 0x0A: return 'Apple AirPlay Source';
    case 0x0B: return 'Apple Magic Switch';
    case 0x0C: return 'Apple Handoff';
    case 0x0D: return 'Apple Tethering';
    case 0x0E: return 'Apple Nearby Action';
    case 0x0F: return 'Apple iPhone';
    case 0x10: return 'Apple Find My';
    case 0x12: return 'Apple AirTag';
    default:   return 'Apple Device';
  }
}

String _classifySamsung(List<int> bytes) {
  if (bytes.isEmpty) return 'Samsung Device';
  // SmartTag: data[0]==0x01, data[1]==0x00, followed by tag model byte
  if (bytes.length >= 2 && bytes[0] == 0x01 && bytes[1] == 0x00) {
    return 'Samsung SmartTag';
  }
  // Galaxy Buds advertise with 0x08 prefix
  if (bytes[0] == 0x08) return 'Samsung Galaxy Buds';
  return 'Samsung Phone';
}

String classifyDevice(BleDevice d) {
  switch (d.vendorId) {
    case 0x004C: return _classifyApple(d.mfDataBytes);
    case 0x0075: return _classifySamsung(d.mfDataBytes);
    case 0x00E0: return 'Google Device';
    case 0x0059: return 'Nordic Dev Board';
    case 0x0006: return 'Microsoft Device';
    case 0x0131: return 'Fitbit';
    case 0x0087: return 'Garmin Watch';
    case 0x008A: return 'Polar Watch';
    case 0x0077: return 'Bose Headphones';
    case 0x038E: return 'Beats Headphones';
    case 0x038F: return 'Tile Tracker';
    case 0x0499: return 'Ruuvi Tag';
    case 0x01D0: return 'Xiaomi Device';
    case 0x0157: return 'Huawei Device';
    case 0x0171: return 'Amazon Device';
    case 0x01FF: return 'Meta Device';
    case 0x025A: return 'Jabra Headset';
    case 0x010F: return 'Suunto Watch';
    case 0x0046: return 'Sony Device';
    case 0x0077: return 'Bose Device';
    case 0x005A: return 'ST Microelectronics';
    case 0x089A: return 'Nothing Device';
    case null:   return 'Unknown Device';
    default:
      final v = kVendorNames[d.vendorId!];
      return v != null ? '$v Device' : 'Unknown Device';
  }
}

class BleDevice {
  final String id;
  final String name;
  int rssi;
  final int? vendorId;
  final List<int> mfDataBytes;
  final String advData;
  DateTime lastSeen;
  int? periodMs;

  BleDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.vendorId,
    required this.mfDataBytes,
    required this.advData,
  })  : lastSeen = DateTime.now(),
        periodMs = null;
}

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
          final newPeriod = now.difference(dev.lastSeen).inMilliseconds;
          dev.rssi = r.rssi;
          dev.periodMs = newPeriod;
          dev.lastSeen = now;
          changed = true;
        } else {
          final name = r.device.platformName.isNotEmpty
              ? r.device.platformName
              : '(unknown)';
          final mfDataBytes = mfData.isNotEmpty ? mfData.values.first : <int>[];
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

    final counts = <String, int>{};
    for (final d in devices) {
      final type = classifyDevice(d);
      counts[type] = (counts[type] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, i) {
        final entry = sorted[i];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  entry.key,
                  style: const TextStyle(fontSize: 15, color: Colors.white),
                ),
              ),
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
        title: const Text('Sniffer'),
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
