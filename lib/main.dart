import 'package:flutter/material.dart';
import 'models/product.dart';
import 'services/gemini_service.dart';
import 'services/serpapi_service.dart';
import 'utils/prompt_builder.dart';
import 'utils/gemini_suggestion_parser.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MaterialApp(home: GiftSuggestionPage()));
}

Future<void> openLink(
  BuildContext context,
  String urlString, {
  String? fallbackSearch,
}) async {
  String urlToOpen = urlString;
  if (!urlToOpen.startsWith('http')) {
    urlToOpen = 'https://$urlToOpen';
  }
  final url = Uri.tryParse(urlToOpen);

  if (url != null && await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else if (fallbackSearch != null) {
    final searchUrl = Uri.parse(
      "https://www.google.com/search?tbm=shop&q=${Uri.encodeComponent(fallbackSearch)}",
    );
    await launchUrl(searchUrl, mode: LaunchMode.externalApplication);
  } else {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Bağlantı açılamadı!")));
  }
}

String googleShoppingUrl(String productName) {
  final encoded = Uri.encodeComponent(productName);
  return "https://www.google.com/search?tbm=shop&q=$encoded";
}

class GiftSuggestionPage extends StatefulWidget {
  const GiftSuggestionPage({super.key});

  @override
  State<GiftSuggestionPage> createState() => _GiftSuggestionPageState();
}

class _GiftSuggestionPageState extends State<GiftSuggestionPage> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _relationController = TextEditingController();
  final _hobbiesController = TextEditingController();
  final _personalityController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _suggestionCountController = TextEditingController(text: "3");

  bool _loading = false;
  List<Product> _products = [];
  String _error = '';

  Future<void> _getSuggestions() async {
    if (!_formKey.currentState!.validate()) return;

    final yas = int.tryParse(_ageController.text) ?? 0;
    final cinsiyet = _genderController.text.trim();
    final iliski = _relationController.text.trim();
    final hobiler = _hobbiesController.text
        .split(',')
        .map((e) => e.trim())
        .toList();
    final kisilik = _personalityController.text.trim();
    final minButce = int.tryParse(_budgetMinController.text) ?? 0;
    final maxButce = int.tryParse(_budgetMaxController.text) ?? 0;
    final onerilenSayi = int.tryParse(_suggestionCountController.text) ?? 3;

    final prompt = buildGiftPrompt(
      yas: yas,
      cinsiyet: cinsiyet,
      iliski: iliski,
      hobiler: hobiler,
      kisilik: kisilik,
      minButce: minButce,
      maxButce: maxButce,
      onerilenSayi: onerilenSayi,
    );

    setState(() {
      _loading = true;
      _products = [];
      _error = '';
    });

    try {
      final geminiResponse = await GeminiService.getGiftSuggestions(prompt);
      print("Gemini yanıtı:\n$geminiResponse"); // Debug için
      final suggestions = extractGeminiGiftSuggestions(geminiResponse);
      if (suggestions.isEmpty) {
        setState(() {
          _error = "Gemini'den anlamlı öneri alınamadı.";
          _products = [];
        });
        return;
      }
      List<Product> realProducts = [];
      for (final s in suggestions) {
        final result = await SerpApiService.searchFirstProduct(
          s.nameOrKeyword,
          s.description,
          minTL: minButce,
          maxTL: maxButce,
        );
        if (result != null) {
          realProducts.add(result);
        } else {
          realProducts.add(
            Product(
              title: s.nameOrKeyword,
              price: "Fiyat belirtilmemiş",
              link: googleShoppingUrl(s.nameOrKeyword),
              imageUrl: "",
              description: s.description,
            ),
          );
        }
      }
      setState(() {
        _products = realProducts;
      });
    } catch (e) {
      setState(() {
        _error = 'Hediye önerisi alınamadı: $e';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gerçek Ürün Linkli Hediye Öneri")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                "Hediye Bul",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: "Yaş"),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? "Yaş girin" : null,
              ),
              TextFormField(
                controller: _genderController,
                decoration: const InputDecoration(labelText: "Cinsiyet"),
                validator: (value) => value!.isEmpty ? "Cinsiyet girin" : null,
              ),
              TextFormField(
                controller: _relationController,
                decoration: const InputDecoration(
                  labelText: "İlişki türü (arkadaş, sevgili, aile vs.)",
                ),
                validator: (value) =>
                    value!.isEmpty ? "İlişki türü girin" : null,
              ),
              TextFormField(
                controller: _hobbiesController,
                decoration: const InputDecoration(
                  labelText: "Hobiler (virgülle ayır)",
                ),
                validator: (value) => value!.isEmpty ? "Hobiler girin" : null,
              ),
              TextFormField(
                controller: _personalityController,
                decoration: const InputDecoration(labelText: "Kişilik tipi"),
                validator: (value) =>
                    value!.isEmpty ? "Kişilik tipi girin" : null,
              ),
              TextFormField(
                controller: _budgetMinController,
                decoration: const InputDecoration(
                  labelText: "Minimum Bütçe (TL)",
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? "Minimum bütçe girin" : null,
              ),
              TextFormField(
                controller: _budgetMaxController,
                decoration: const InputDecoration(
                  labelText: "Maksimum Bütçe (TL)",
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? "Maksimum bütçe girin" : null,
              ),
              TextFormField(
                controller: _suggestionCountController,
                decoration: const InputDecoration(
                  labelText: "Kaç öneri istiyorsun?",
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? "Öneri sayısı girin" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _getSuggestions,
                child: const Text("Hediye Öner"),
              ),
              const SizedBox(height: 20),
              const Text(
                "Not: Fiyatlar ve satıcılar Google Shopping verisine göre çekildiği için güncel olmayabilir, ürüne tıkladığınızda farklı fiyat görebilirsiniz.",
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
              const SizedBox(height: 10),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_error.isNotEmpty)
                Text(_error, style: const TextStyle(color: Colors.red))
              else if (_products.isNotEmpty)
                ..._products.map(
                  (p) => Card(
                    child: ListTile(
                      leading: p.imageUrl.isNotEmpty
                          ? Image.network(
                              p.imageUrl,
                              width: 50,
                              height: 50,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image_not_supported),
                            )
                          : const Icon(Icons.image_not_supported),
                      title: Text(p.title, maxLines: 2),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.price),
                          Text(
                            p.description,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => openLink(
                                  context,
                                  p.link,
                                  fallbackSearch: p.title,
                                ),
                                icon: const Icon(Icons.open_in_new, size: 18),
                                label: Text("Ürüne Git"),
                                style: ElevatedButton.styleFrom(
                                  textStyle: const TextStyle(fontSize: 13),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                const Text("Henüz öneri yok."),
            ],
          ),
        ),
      ),
    );
  }
}
