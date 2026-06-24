(function () {
  var grid = document.querySelector('.demo-grid');
  if (!grid) return;

  var cards = grid.querySelectorAll('.demo-card');

  // Replace each card's no-JS phone contents with the initial
  // loading state (spinner only, the iframe boots on intersection).
  for (var i = 0; i < cards.length; i++) {
    renderInitialLoading(cards[i]);
  }

  // A demo is considered successfully loaded only when the embedded
  // Flutter app explicitly tells us it is ready. The iframe's `load`
  // event is not enough, because a 404 page also fires `load`.
  window.addEventListener('message', function (e) {
    if (e.origin !== window.location.origin) return;
    if (!e.data || e.data.type !== 'resengi:flutter-demo-ready') return;
    if (!e.data.demo) return;

    var card = grid.querySelector('.demo-card[data-slug="' + e.data.demo + '"]');
    if (!card) return;
    if (card.dataset.state !== 'loading') return;

    clearTimer(card);
    renderLoaded(card);
  });

  // Click handler: only failed cards are clickable (for retry).
  // Pub.dev / GitHub <a> links inside the failed state must
  // navigate normally, so we let link clicks pass through.
  grid.addEventListener('click', function (e) {
    if (e.target.closest('a')) return;
    var phone = e.target.closest('.demo-phone');
    if (!phone) return;
    var card = phone.closest('.demo-card');
    if (!card) return;
    if (card.dataset.state !== 'failed') return;
    bootDemo(card);
  });

  // IntersectionObserver triggers the initial load of each card
  // as it scrolls within 200px of the viewport.
  if ('IntersectionObserver' in window) {
    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          bootDemo(entry.target);
          observer.unobserve(entry.target);
        }
      });
    }, { rootMargin: '200px' });
    for (var j = 0; j < cards.length; j++) {
      observer.observe(cards[j]);
    }
  } else {
    // Graceful degradation for very old browsers: load all at once.
    for (var k = 0; k < cards.length; k++) {
      bootDemo(cards[k]);
    }
  }

  // --- Render helpers: swap phone contents and update data-state. ---

  function renderInitialLoading(card) {
    var phone = card.querySelector('.demo-phone');
    phone.innerHTML =
      '<div class="demo-phone-content">' +
        '<span class="spinner-dot" aria-hidden="true"></span>' +
      '</div>';
    card.dataset.state = 'loading-initial';
    card._iframeWindow = null;
    card._failureTimer = null;
  }

  function renderLoading(card, iframe) {
    // Put the iframe in the DOM so the browser actually requests it,
    // but keep a loading overlay on top until the embedded Flutter
    // app explicitly reports that it is ready.
    var phone = card.querySelector('.demo-phone');
    phone.innerHTML = '';
    phone.appendChild(iframe);
    card._iframeWindow = iframe.contentWindow;

    var overlay = document.createElement('div');
    overlay.className = 'demo-phone-content demo-phone-overlay';
    overlay.innerHTML =
      '<span class="spinner-dot" aria-hidden="true"></span>';
    phone.appendChild(overlay);
    card.dataset.state = 'loading';
  }

  function renderLoaded(card) {
    // The iframe is already in the DOM from renderLoading. Just
    // remove the overlay so it becomes visible.
    var overlay = card.querySelector('.demo-phone-overlay');
    if (overlay) overlay.remove();
    card.dataset.state = 'loaded';
    card._failureTimer = null;
  }

  function renderFailed(card) {
    clearTimer(card);
    var phone = card.querySelector('.demo-phone');
    phone.innerHTML =
      '<div class="demo-phone-content">' +
        '<p class="demo-phone-action demo-phone-action-disabled">' +
          'Couldn&rsquo;t load the demo. ' +
          'See the readme on ' +
          '<a href="' + escapeAttr(card.dataset.pubdev) + '">pub.dev</a> or ' +
          '<a href="' + escapeAttr(card.dataset.github) + '">GitHub</a>.' +
        '</p>' +
        '<p class="demo-phone-retry-hint">Click to retry</p>' +
      '</div>';
    card.dataset.state = 'failed';
    card._iframeWindow = null;
  }

  // Creates a fresh iframe and starts a fresh failure timer.
  // Idempotent (safe to call on retry from the failed state).
  function bootDemo(card) {
    clearTimer(card);

    var iframe = document.createElement('iframe');
    iframe.src = '/flutter-examples/?demo=' + card.dataset.slug;
    iframe.title = card.dataset.name + ' interactive demo';

    // `load` only means some document loaded. That could still be a
    // 404 page or another failure page, so do not mark success here.
    iframe.addEventListener('load', function () {});

    // If the browser surfaces an iframe-level error, fail fast.
    iframe.addEventListener('error', function () {
      renderFailed(card);
    });

    // Inject the iframe (inside renderLoading, with an overlay on
    // top). Once the iframe is in the DOM, the browser fetches its
    // src and eventually fires load or error.
    renderLoading(card, iframe);

    // If the embedded Flutter app never sends the ready signal,
    // assume failure and show the fallback UI.
    card._failureTimer = setTimeout(function () {
      renderFailed(card);
    }, 8000);
  }

  function clearTimer(card) {
    if (card._failureTimer) {
      clearTimeout(card._failureTimer);
      card._failureTimer = null;
    }
  }

  // Escape helper: we inject card.dataset values into innerHTML,
  // so guard against any HTML-special characters that might sneak
  // in through future copy edits to the data-* attributes.
  function escapeHtml(s) {
    return String(s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }
  function escapeAttr(s) {
    return escapeHtml(s).replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }
})();