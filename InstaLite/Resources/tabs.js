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
    const profile = profileLink();
    if (profile) {
      const avatar = profile.querySelector('img');
      remember({ profile: profile.getAttribute('href'), avatar: avatar ? avatar.currentSrc || avatar.src : null });
    }
    const loginPage = location.pathname.startsWith('/accounts/login');
    const message = {
      path: location.pathname,
      loggedIn: !loginPage && !!(nav || account),
      profile: account ? account.profile : null,
      avatar: account ? account.avatar : null,
    };
    const serialized = JSON.stringify(message);
    if (serialized === lastMessage) return;
    lastMessage = serialized;
    post(message);
  }

  let scheduled = false;
  function scheduleReport() {
    if (scheduled) return;
    scheduled = true;
    requestAnimationFrame(() => {
      scheduled = false;
      report();
    });
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
    if (!path) return;
    if (location.pathname === path) {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    } else {
      go(path);
    }
  }

  globalThis.__instaLiteTabs = { open };

  window.addEventListener('instalite:navigate', scheduleReport);
  document.addEventListener('DOMContentLoaded', () => {
    report();
    new MutationObserver(scheduleReport).observe(document.body, { childList: true, subtree: true });
  });
})();
