String buildGiftPrompt({
  required int yas,
  required String cinsiyet,
  required String iliski,
  required List<String> hobiler,
  required String kisilik,
  required int minButce,
  required int maxButce,
  required int onerilenSayi,
}) {
  return """
Aşağıdaki kişiye hediye öner:
- Yaş: $yas
- Cinsiyet: $cinsiyet
- İlişki türü: $iliski
- Hobiler/ilgi alanları: ${hobiler.join(", ")}
- Kişilik tipi: $kisilik
- Bütçe aralığı: $minButce-$maxButce TL

Yalnızca $onerilenSayi adet ürün adı ve kısa açıklama öner. Her bir öneriyi aşağıdaki gibi sırala (başka hiçbir açıklama ekleme):

1. Ürün adı: ... | Kısa açıklama: ...
2. Ürün adı: ... | Kısa açıklama: ...
...
""";
}
