// Instagram tek sayfalık bir uygulama: sayfalar arası geçişler yeniden yükleme olmadan
// history API'siyle yapılır, bu yüzden yerel `decidePolicyFor` onları görmez.
// Bu betik `rules.js`'in hemen ardından, sayfa betiklerinden önce çalışır.
(function () {
  const rules = globalThis.__instaLiteRules;
  if (!rules) return;

  let current = location.pathname;

  function targetPath(url) {
    try {
      const target = new URL(url, location.href);
      return target.origin === location.origin ? target.pathname : null;
    } catch {
      return null;
    }
  }

  function notify() {
    current = location.pathname;
    window.dispatchEvent(new Event('instalite:navigate'));
  }

  // Ana akışa dönüşü uygulamanın kendi "Ana sayfa" bağlantısıyla yapar; yoksa yeniden yükler.
  function goSoftly(path) {
    const link = path === '/' && document.querySelector('a[href="/"]');
    if (link) link.click();
    else location.assign(path);
  }

  for (const name of ['pushState', 'replaceState']) {
    const original = history[name];
    history[name] = function (state, title, url) {
      const path = url == null ? null : targetPath(url);
      const redirect = path && rules.redirect(current, path);
      if (redirect) {
        // Sayfa yönlendiricisi engelli ekranı çizmeye başlamış olabilir; temiz yükleme en güvenlisi.
        location.replace(redirect);
        return;
      }
      const result = original.apply(this, arguments);
      notify();
      return result;
    };
  }

  window.addEventListener('popstate', () => {
    const redirect = rules.redirect(current, location.pathname);
    if (redirect) {
      location.replace(redirect);
      return;
    }
    notify();
  }, true);

  document.addEventListener('click', (event) => {
    const link = event.target instanceof Element && event.target.closest('a[href]');
    const path = link && targetPath(link.href);
    const redirect = path && rules.redirect(current, path);
    if (!redirect) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    goSoftly(redirect);
  }, true);

  const initial = rules.redirect(null, location.pathname);
  if (initial) location.replace(initial);
})();
