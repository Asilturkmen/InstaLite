// Yerel sekme çubuğu ile sayfa arasındaki köprü. Instagram'ın web alt çubuğunu bulup
// gizlenmesi için işaretler, hangi sayfada olunduğunu uygulamaya bildirir ve uygulamadan
// gelen sekme dokunuşlarını sayfa içi geçişe çevirir. Sınıf adları otomatik üretildiği
// için çubuk, içindeki Keşfet bağlantısından bulunur.
(function () {
  const known = new Set(['/', '/explore/', '/reels/', '/direct/inbox/']);
  let nav = null;
  let lastMessage = '';
  // Bazı sayfalar (ör. Mesajlar) web alt çubuğunu hiç çizmez; profil son görüldüğü haliyle hatırlanır.
  let account = load();

  function load() {
    try {
      return JSON.parse(localStorage.getItem('instalite:account')) || null;
    } catch {
      return null;
    }
  }

  function forget() {
    account = null;
    try {
      localStorage.removeItem('instalite:account');
    } catch {}
  }

  // Instagram oturum açıkken sayfanın okuyabildiği ds_user_id çerezini koyar; çıkışta siler.
  function loggedIn() {
    return /(^|; )ds_user_id=/.test(document.cookie) && !location.pathname.startsWith('/accounts/login');
  }

  function remember(next) {
    if (account && account.profile === next.profile && account.avatar === next.avatar) return;
    account = next;
    try {
      localStorage.setItem('instalite:account', JSON.stringify(next));
    } catch {}
  }

  function post(message) {
    const handler = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.instalite;
    if (handler) handler.postMessage(message);
  }

  function fixedAncestor(element) {
    for (let node = element; node && node !== document.body; node = node.parentElement) {
      if (getComputedStyle(node).position === 'fixed') return node;
    }
    return null;
  }

  function findNav() {
    if (nav && nav.isConnected) return nav;
    nav = null;
    for (const link of document.querySelectorAll('a[href="/explore/"]')) {
      const box = fixedAncestor(link);
      if (box) {
        box.setAttribute('data-instalite-webnav', '');
        nav = box;
        break;
      }
    }
    return nav;
  }

  function profileLink() {
    if (!nav) return null;
    for (const link of nav.querySelectorAll('a[href]')) {
      const href = link.getAttribute('href');
      if (!known.has(href) && /^\/[^/]+\/$/.test(href)) return link;
    }
    return null;
  }

  function report() {
    findNav();
    const signedIn = loggedIn();
    const profile = signedIn && profileLink();
    if (profile) {
      const avatar = profile.querySelector('img');
      remember({ profile: profile.getAttribute('href'), avatar: avatar ? avatar.currentSrc || avatar.src : null });
    } else if (!signedIn && account) {
      forget();
    }
    const message = {
      path: location.pathname,
      loggedIn: signedIn,
      profile: account ? account.profile : null,
      avatar: account ? account.avatar : null,
    };
    const serialized = JSON.stringify(message);
    if (serialized === lastMessage) return;
    lastMessage = serialized;
    post(message);
  }

  // Akış kaydırılırken DOM her karede değişir; rapor en fazla 300 ms'de bir hazırlanır.
  let scheduled = false;
  function scheduleReport() {
    if (scheduled) return;
    scheduled = true;
    setTimeout(() => {
      scheduled = false;
      report();
    }, 300);
  }

  // Sekme seçimi uygulamada dokunuşla değişir; geçiş olmazsa doğru sekme yeniden bildirilsin.
  function resync() {
    lastMessage = '';
    scheduleReport();
  }

  // Sayfa içi geçiş: önce Instagram'ın kendi bağlantısı, yoksa yönlendiricisinin dinlediği popstate.
  function go(path) {
    const link = nav && nav.querySelector(`a[href="${path}"]`);
    if (link) {
      link.click();
    } else {
      history.pushState({}, '', path);
      dispatchEvent(new PopStateEvent('popstate', { state: {} }));
    }
  }

  // Uygulama sekme dokunuşunda çağırır. Aynı sekmenin kökündeyken başa kaydırır.
  function open(tab) {
    const path = { home: '/', search: '/explore/search/', messages: '/direct/inbox/' }[tab]
      || (tab === 'profile' && account && account.profile);
    if (path && location.pathname === path) {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    } else if (path) {
      go(path);
    }
    resync();
  }

  globalThis.__instaLiteTabs = { open };

  // Sayfa geçişi hemen bildirilir (sekme çubuğu gecikmeden gizlensin/görünsün); DOM değişiklikleri seyrek.
  window.addEventListener('instalite:navigate', report);
  document.addEventListener('DOMContentLoaded', () => {
    report();
    new MutationObserver(scheduleReport).observe(document.body, { childList: true, subtree: true });
  });
})();
