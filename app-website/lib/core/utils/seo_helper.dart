import 'package:web/web.dart' as web;

/// Helper untuk mengatur meta tag SEO secara dinamis per halaman.
/// Dipanggil saat halaman berganti (route change).
class SeoHelper {
  SeoHelper._();

  /// Update title dan meta description untuk halaman saat ini.
  static void updateMeta({
    required String title,
    required String description,
    String? canonical,
  }) {
    // Update document title
    web.document.title = title;

    // Update meta description
    _setMetaContent('name', 'description', description);
    _setMetaContent('property', 'og:title', title);
    _setMetaContent('property', 'og:description', description);
    _setMetaContent('property', 'twitter:title', title);
    _setMetaContent('property', 'twitter:description', description);

    // Update canonical jika ada
    if (canonical != null) {
      final link = web.document.querySelector('link[rel="canonical"]');
      if (link != null) {
        (link as web.HTMLLinkElement).href = canonical;
      }
    }
  }

  static void _setMetaContent(
    String attrName,
    String attrValue,
    String content,
  ) {
    final meta =
        web.document.querySelector('meta[$attrName="$attrValue"]');
    if (meta != null) {
      (meta as web.HTMLMetaElement).content = content;
    } else {
      final newMeta = web.document.createElement('meta') as web.HTMLMetaElement;
      if (attrName == 'name') {
        newMeta.name = attrValue;
      } else {
        newMeta.setAttribute(attrName, attrValue);
      }
      newMeta.content = content;
      web.document.head!.appendChild(newMeta);
    }
  }
}

