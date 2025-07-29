import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class SerpApiService {
  static const String _apiKey =
      'bf0e75936d0582acd5803b88eafa5d0cca5e9bb6290289ec191a8d31992e80ac';

  // Türk siteleri listesi
  static const List<String> turkishSites = [
    'trendyol',
    'hepsiburada',
    'n11',
    'vatan',
    'teknosa',
    'migros',
    'a101',
  ];

  // Fiyat ve marka filtreleme fonksiyonu
  static List<Product> filterProductsByPriceAndBrand(
    List items,
    int minTL,
    int maxTL,
    String description,
    String query,
  ) {
    List<Product> products = [];
    for (var item in items) {
      final priceStr = (item['price'] ?? '').toString();
      final linkStr = (item['link'] ?? '').toString().toLowerCase();
      // Sadece TL fiyatları
      if (priceStr.contains('TL') || priceStr.contains('₺')) {
        final priceNum =
            double.tryParse(
              priceStr
                  .replaceAll('TL', '')
                  .replaceAll('₺', '')
                  .replaceAll('TRY', '')
                  .replaceAll('.', '')
                  .replaceAll(',', '.')
                  .trim()
                  .split(' ')
                  .first,
            ) ??
            0;
        if ((minTL == 0 || priceNum >= minTL) &&
            (maxTL == 0 || priceNum <= maxTL)) {
          products.add(
            Product(
              title: item['title'] ?? query,
              price: priceStr.replaceAll('TRY', 'TL').replaceAll('₺', 'TL'),
              link: item['link'] ?? '',
              imageUrl: item['thumbnail'] ?? '',
              description: description,
            ),
          );
        }
      }
    }

    // Önce Türk siteleri filtrele
    final turkishProducts = products.where(
      (p) => turkishSites.any((site) => p.link.toLowerCase().contains(site)),
    );
    if (turkishProducts.isNotEmpty) return turkishProducts.toList();
    return products;
  }

  static Future<Product?> searchFirstProduct(
    String query,
    String description, {
    int? minTL,
    int? maxTL,
  }) async {
    String searchQuery = query;
    if (minTL != null && maxTL != null && minTL > 0 && maxTL > minTL) {
      searchQuery += ' $minTL TL - $maxTL TL';
    }
    final url =
        'https://serpapi.com/search.json?q=${Uri.encodeComponent(searchQuery)}'
        '&tbm=shop'
        '&hl=tr'
        '&gl=tr'
        '&location=Turkey'
        '&api_key=$_apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    if (data['shopping_results'] == null || data['shopping_results'].isEmpty)
      return null;

    final items = data['shopping_results'] as List;

    final filteredProducts = filterProductsByPriceAndBrand(
      items,
      minTL ?? 0,
      maxTL ?? 0,
      description,
      query,
    );

    if (filteredProducts.isNotEmpty) return filteredProducts.first;

    // Filtreye uyan yoksa ilk ürünü "Fiyat belirtilmemiş" olarak döndür
    final item = items.first;
    return Product(
      title: item['title'] ?? query,
      price: 'Fiyat belirtilmemiş',
      link: item['link'] ?? '',
      imageUrl: item['thumbnail'] ?? '',
      description: description,
    );
  }
}
