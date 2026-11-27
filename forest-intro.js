(() => {
  const root = document.documentElement;
  const dialog = document.getElementById('forest-film');
  const video = dialog.querySelector('video');
  const replay = document.querySelector('.film-replay');
  const skip = dialog.querySelector('.film-skip');
  const motion = matchMedia('(prefers-reduced-motion: reduce)');
  const autoStart = root.dataset.film === 'opening';
  clearTimeout(window.filmBootTimer);

  if (typeof dialog.showModal !== 'function' || !video.canPlayType('video/mp4')) {
    delete root.dataset.film;
    return;
  }

  let attempt = 0;
  let fromReplay = false;
  let stallTimer, exitTimer, entryTimer;
  function playing() {
    return dialog.open && root.dataset.film === 'playing';
  }
  function closeFilm(animate = true) {
    if (!dialog.open) return;
    clearTimeout(stallTimer);
    clearTimeout(exitTimer);
    video.pause();
    dialog.close();
    if (animate) root.classList.add('film-enter');
    delete root.dataset.film;
    if (animate) {
      entryTimer = setTimeout(() => root.classList.remove('film-enter'), 850);
      const target = fromReplay ? replay : document.querySelector('.hero h1');
      if (!fromReplay) target.tabIndex = -1;
      target.focus({ preventScroll: true });
    }
  }
  function leave() {
    if (!playing()) return;
    ++attempt;
    clearTimeout(stallTimer);
    video.pause();
    root.dataset.film = 'leaving';
    if (motion.matches) closeFilm();
    else exitTimer = setTimeout(closeFilm, 580);
  }
  function armTimeout() {
    clearTimeout(stallTimer);
    if (playing() && !document.hidden) stallTimer = setTimeout(leave, 6500);
  }
  function resume() {
    if (!playing() || document.hidden) return;
    const current = attempt;
    armTimeout();
    video.play().catch(() => { if (attempt === current && !document.hidden) leave(); });
  }
  function start(manual) {
    if (dialog.open) return;
    fromReplay = manual;
    ++attempt;
    clearTimeout(entryTimer);
    root.classList.remove('film-enter');
    root.dataset.film = 'playing';
    dialog.showModal();
    video.muted = true;
    const source = matchMedia('(max-width: 820px) and (orientation: portrait)').matches
      ? 'media/forest-intro-mobile.mp4' : 'media/forest-intro.mp4';
    if (video.getAttribute('src') !== source || video.error) {
      video.poster = 'media/forest-intro.webp';
      video.src = source;
      video.load();
    } else video.currentTime = 0;
    resume();
  }

  skip.addEventListener('click', leave);
  replay.addEventListener('click', () => start(true));
  dialog.addEventListener('cancel', event => { event.preventDefault(); leave(); });
  video.addEventListener('ended', leave);
  video.addEventListener('error', leave);
  video.addEventListener('timeupdate', armTimeout);
  document.addEventListener('visibilitychange', () => {
    if (document.hidden) { clearTimeout(stallTimer); video.pause(); }
    else resume();
  });
  motion.addEventListener('change', () => { if (motion.matches) leave(); });
  window.addEventListener('pagehide', () => {
    ++attempt;
    closeFilm(false);
  });
  replay.hidden = false;
  if (autoStart && !motion.matches) start(false);
  else delete root.dataset.film;
})();
