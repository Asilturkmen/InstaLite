// Sayfaya yerel uygulama hissi veren küçük ayarlar. hide.css'teki yola bağlı kurallar
// için <html>'e sınıf koyar ve yakınlaştırmayı kapatır.
(function () {
  const root = document.documentElement;

  function updateClasses() {
    root.classList.toggle('instalite-home', location.pathname === '/');
  }
  updateClasses();
  window.addEventListener('instalite:navigate', updateClasses);

  // Akıştan gizlenen Reels videoları arka planda oynamasın.
  document.addEventListener('play', (event) => {
    const video = event.target;
    if (video instanceof HTMLVideoElement && video.closest('.instalite-home article:has(a[href*="/reel/"])')) {
      video.pause();
    }
  }, true);

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
