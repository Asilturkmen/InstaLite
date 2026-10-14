// Engellenen Instagram adresleri. Kurallar `Web/BlockRules.swift` ile aynıdır;
// ikisi de `Tests/rules-cases.json` ile test edilir, birini değiştirirsen ötekini de değiştir.
(function () {
  function segments(path) {
    return String(path || '/').split('/').filter(Boolean);
  }

  function reelId(parts) {
    if (parts[0] === 'reel') return parts[1] || null;
    if (parts[1] === 'reel') return parts[2] || null;
    return null;
  }

  // `from` yolundan `to` yoluna geçilirken gidilecek yeri döner; null ise geçiş serbesttir.
  function redirect(from, to) {
    const parts = segments(to);
    if (parts[0] === 'explore') {
      if (parts[1] === 'search') return null;
      return parts.length === 1 ? '/explore/search/' : '/';
    }
    if (parts[0] === 'reels' || parts[1] === 'reels') return '/';

    // DM'den açılan tek Reel serbest; bir Reel'den başka bir Reel'e geçiş değil.
    const toReel = reelId(parts);
    if (toReel && from != null) {
      const fromReel = reelId(segments(from));
      if (fromReel && fromReel !== toReel) return '/';
    }
    return null;
  }

  const api = { redirect };
  if (typeof module === 'object' && module.exports) {
    module.exports = api;
  } else {
    globalThis.__instaLiteRules = api;
  }
})();
