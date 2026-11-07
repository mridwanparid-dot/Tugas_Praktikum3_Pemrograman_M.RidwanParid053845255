import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

/// Model data: mewakili satu cryptocurrency dari API CoinLore.
class Crypto {
  final int rank;
  final String name;
  final String symbol;
  final String priceUsd;

  Crypto({
    required this.rank,
    required this.name,
    required this.symbol,
    required this.priceUsd,
  });

  // Mengubah satu objek JSON menjadi objek Crypto.
  factory Crypto.fromJson(Map<String, dynamic> json) {
    return Crypto(
      rank: int.parse(json['rank'].toString()),
      name: json['name'].toString(),
      symbol: json['symbol'].toString(),
      priceUsd: json['price_usd'].toString(),
    );
  }
}

/// Mengambil data dari API online.
Future<List<Crypto>> fetchCryptos() async {
  final response =
      await http.get(Uri.parse('https://api.coinlore.net/api/tickers/'));

  if (response.statusCode == 200) {
    final Map<String, dynamic> body = jsonDecode(response.body);
    final List<dynamic> data = body['data'];
    return data.map((item) => Crypto.fromJson(item)).toList();
  } else {
    throw Exception('Gagal memuat data (kode ${response.statusCode})');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Daftar Cryptocurrency',
      home: CryptoPage(),
    );
  }
}

class CryptoPage extends StatefulWidget {
  const CryptoPage({super.key});

  @override
  State<CryptoPage> createState() => _CryptoPageState();
}

class _CryptoPageState extends State<CryptoPage> {
  late Future<List<Crypto>> _futureCryptos;

  @override
  void initState() {
    super.initState();
    _futureCryptos = fetchCryptos(); // load pertama kali
  }

  // Dipanggil tombol Refresh: ambil ulang data dari API.
  void _refresh() {
    setState(() {
      _futureCryptos = fetchCryptos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton(
                onPressed: _refresh,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0057D9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Refresh'),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Crypto>>(
                future: _futureCryptos,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Terjadi kesalahan:\n${snapshot.error}',
                          textAlign: TextAlign.center),
                    );
                  }
                  final cryptos = snapshot.data!;
                  return ListView.builder(
                    itemCount: cryptos.length,
                    itemBuilder: (context, index) =>
                        CryptoItem(crypto: cryptos[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu baris item: Rank | Name + Symbol | USD + Harga.
class CryptoItem extends StatelessWidget {
  final Crypto crypto;
  const CryptoItem({super.key, required this.crypto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1CC),
        border: Border.all(color: const Color(0xFFE6D3A0), width: 0.8),
      ),
      child: Row(
        children: [
          // Kolom 1: Rank
          SizedBox(
            width: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rank', style: TextStyle(fontSize: 11)),
                Text('${crypto.rank}', style: const TextStyle(fontSize: 18)),
              ],
            ),
          ),
          // Kolom 2: Name dan Symbol
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(crypto.name, style: const TextStyle(fontSize: 11)),
                Text(crypto.symbol,
                    style: const TextStyle(fontSize: 20),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // Kolom 3: Harga USD
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('USD', style: TextStyle(fontSize: 11)),
                Text(crypto.priceUsd,
                    style: const TextStyle(fontSize: 18),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
