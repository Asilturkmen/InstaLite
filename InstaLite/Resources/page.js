// Sayfaya yerel uygulama hissi veren küçük ayarlar.
(function () {
  // Instagram kendi viewport etiketini koyar; iki parmakla yakınlaştırmayı kapatmak için üzerine yazılır.
  const viewport = 'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no';
  function lockViewport() {
    if (!document.head) return;
    let meta = document.head.querySelector('meta[name="viewport"]');
    if (!meta) {
      meta = document.createElement('meta');
      meta.name = 'viewport';
      document.head.appendChild(meta);
    }
    if (meta.content !== viewport) meta.content = viewport;
  }

  document.addEventListener('DOMContentLoaded', () => {
    lockViewport();
    new MutationObserver(lockViewport).observe(document.head, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ['content'],
    });
  });
})();
