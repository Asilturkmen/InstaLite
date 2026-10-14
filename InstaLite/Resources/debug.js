// Yalnız geliştirme sürümünde eklenir: her saniye kaydırma sırasındaki kare sürelerini ve
// sayfa durumunu uygulamaya yollar; DebugBridge bunları Documents/bridge/metrics.jsonl'a yazar.
(function () {
  const handler = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.instaliteDebug;
  if (!handler) return;

  let scrollAt = 0;
  let scrolls = 0;
  let previous = performance.now();
  let frames = [];

  addEventListener('scroll', () => {
    scrollAt = performance.now();
    scrolls++;
  }, { passive: true, capture: true });

  requestAnimationFrame(function tick(now) {
    if (now - scrollAt < 150) frames.push(Math.round((now - previous) * 10) / 10);
    previous = now;
    requestAnimationFrame(tick);
  });

  setInterval(() => {
    const articles = document.querySelectorAll('article');
    let hidden = 0;
    let reels = 0;
    for (const article of articles) {
      if (getComputedStyle(article).display === 'none') hidden++;
      if (article.querySelector('a[href*="/reel/"]')) reels++;
    }
    handler.postMessage({
      t: Date.now(),
      path: location.pathname,
      y: Math.round(scrollY),
      docH: document.documentElement.scrollHeight,
      articles: articles.length,
      hidden,
      reels,
      removedReels: globalThis.__instaLiteRemovedReels || 0,
      scrolls,
      frames,
    });
    scrolls = 0;
    frames = [];
  }, 1000);
})();
