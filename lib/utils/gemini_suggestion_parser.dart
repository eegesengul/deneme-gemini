class GeminiGiftSuggestion {
  final String nameOrKeyword;
  final String description;

  GeminiGiftSuggestion({
    required this.nameOrKeyword,
    required this.description,
  });
}

// Yeni parse fonksiyonu: "1. Ürün adı: ... | Kısa açıklama: ..." formatı için
List<GeminiGiftSuggestion> extractGeminiGiftSuggestions(String response) {
  final regex = RegExp(
    r'\d+\.\s*Ürün adı:\s*(.*?)\s*\|\s*Kısa açıklama:\s*(.*)',
    caseSensitive: false,
  );
  return regex.allMatches(response).map((m) {
    return GeminiGiftSuggestion(
      nameOrKeyword: m.group(1)?.trim() ?? '',
      description: m.group(2)?.trim() ?? '',
    );
  }).toList();
}
