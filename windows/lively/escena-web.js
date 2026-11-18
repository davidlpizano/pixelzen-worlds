(() => {
  const TEMAS_DISPONIBLES = ['fittoa', 'continente-demoniaco', 'hunter-x-hunter', 'black-clover', 'spiderman-miles-morales', 'solo-leveling', 'demon-slayer', 'stranger-things', 'harry-potter', 'naruto', 'jujutsu-kaisen', 'attack-on-titan', 'one-piece', 'dragon-ball-z', 'cyberpunk-edgerunners', 'terraza-michis', 'salon-noah-maggie'];
  const params = new URLSearchParams(window.location.search);
  const canvas = document.getElementById('lienzo');
  const d = new Date();
  let liveStats = null;
  let lastEstadoTxt = '';

  const STAT_KEYS = ['tiempo', 'clima', 'sistema', 'gpu', 'red', 'audio', 'dev', 'foco', 'grimorio'];
  const statsParam = params.get('stats');
  const hudStatsInit = {};
  for (const k of STAT_KEYS) {
    hudStatsInit[k] = statsParam ? statsParam.includes(k) : params.get(`hud_${k}`) !== '0';
  }

  const pArg = params.get('pantalla');
  const pantallaParam = pArg === 'secundaria' ? 'secundaria' : (pArg === 'bloqueo' ? 'bloqueo' : 'principal');
  const mostrarHudParam = params.has('hud')
    ? params.get('hud') !== '0'
    : pantallaParam !== 'secundaria';

  const modoToIdx = m => (m === 'real' ? 0 : (m === 'demo' ? 2 : (m === 'fija' ? 3 : 1)));

  const renderer = window.PixelZenCanvas.createRenderer(canvas, {
    initialState: {
      tema: params.get('tema') || 'fittoa',
      pantalla: pantallaParam,
      modoHora: modoToIdx(params.get('modo')),
      horaFija: parseFloat(params.get('hora') || '21.5'),
      fps: parseInt(params.get('fps') || '16', 10),
      mostrarHud: mostrarHudParam,
      hudStats: hudStatsInit,
      inicioHora: d.getHours() + d.getMinutes() / 60 + d.getSeconds() / 3600,
    },
    onTemaLoaded(tema) {
      document.body.style.background = tema.cielo_fondo || '#0a0c24';
    },
    onRender(fecha, T) {
      renderer.actualizaHud(fecha, T, { quoteIntervalMs: 90000, stats: liveStats });
    },
  });

  const { state } = renderer;
  let rafId = null;
  let animT0 = performance.now();
  let lastRender = 0;
  function step(now) {
    if (document.hidden) { rafId = null; return; }
    const fps = Math.max(4, Math.min(30, parseInt(state.fps, 10) || 16));
    const minInterval = 1000 / fps;
    if (!lastRender || (now - lastRender) >= minInterval * 0.92) {
      lastRender = now;
      state.tickFloat = (now - animT0) * 0.01;
      state.tick = Math.floor(state.tickFloat);
      renderer.render();
    }
    rafId = requestAnimationFrame(step);
  }
  function reprogramar() {
    if (rafId) { cancelAnimationFrame(rafId); rafId = null; }
    if (document.hidden) return;
    lastRender = 0;
    rafId = requestAnimationFrame(step);
  }
  document.addEventListener('visibilitychange', () => {
    if (document.hidden) {
      if (rafId) { cancelAnimationFrame(rafId); rafId = null; }
    } else {
      animT0 = performance.now() - ((state.tickFloat || state.tick || 0) * 100);
      renderer.render();
      reprogramar();
    }
  });

  async function aplicaEstadoJson(cfg) {
    if (!cfg || typeof cfg !== 'object') return;
    const nuevoTema = cfg.tema || state.tema;
    const nuevaPantalla = cfg.pantalla === 'secundaria' ? 'secundaria' : (cfg.pantalla === 'bloqueo' ? 'bloqueo' : 'principal');
    if (cfg.modo) {
      const mIdx = modoToIdx(cfg.modo);
      if (mIdx !== state.modoHora) {
        state.modoHora = mIdx;
        if (mIdx === 1) {
          state.inicioMs = Date.now();
          const now = new Date();
          state.inicioHora = now.getHours() + now.getMinutes() / 60 + now.getSeconds() / 3600;
        }
      }
    }
    if (cfg.horaFija !== undefined) state.horaFija = parseFloat(cfg.horaFija) || 21.5;
    if (cfg.fps !== undefined) {
      const nf = parseInt(cfg.fps, 10) || 16;
      if (nf !== state.fps) {
        state.fps = nf;
        if (rafId) reprogramar();
      }
    }
    if (cfg.hud !== undefined) state.mostrarHud = !!cfg.hud;
    if (cfg.clima !== undefined) state.clima = String(cfg.clima || 'normal');
    if (cfg.compactoHud !== undefined) state.hudCompacto = !!cfg.compactoHud;
    if (cfg.audioReactivo !== undefined) state.audioReactivo = !!cfg.audioReactivo;
    if (cfg.stats && typeof cfg.stats === 'object') {
      for (const k of STAT_KEYS) {
        if (cfg.stats[k] !== undefined) state.hudStats[k] = !!cfg.stats[k];
      }
    }
    if (cfg.live && typeof cfg.live === 'object') liveStats = cfg.live;
    if (nuevoTema !== state.tema || nuevaPantalla !== state.pantalla) {
      await renderer.cargarTema(nuevoTema, { pantalla: nuevaPantalla });
    }
    renderer.render();
  }

  let pendingSync = null;

  window.PixelZenRecibeEstado = cfg => {
    try {
      const txt = JSON.stringify(cfg);
      if (txt === lastEstadoTxt) return;
      lastEstadoTxt = txt;
      pendingSync = aplicaEstadoJson(cfg);
    } catch (_e) { /* estado invalido */ }
  };

  function sincronizaEstado() {
    if (params.has('tema')) return Promise.resolve();
    return new Promise(resolve => {
      const prev = document.getElementById('pz-sync-script');
      if (prev) prev.remove();
      const s = document.createElement('script');
      s.id = 'pz-sync-script';
      s.src = `pz_estado.js?t=${Date.now()}`;
      let done = false;
      const finish = () => {
        if (done) return;
        done = true;
        const p = pendingSync;
        pendingSync = null;
        if (p && typeof p.then === 'function') p.then(resolve, resolve);
        else resolve();
      };
      const tid = setTimeout(finish, 1200);
      s.onload = () => { clearTimeout(tid); finish(); };
      s.onerror = () => { clearTimeout(tid); finish(); };
      document.head.appendChild(s);
    });
  }

  async function refrescaStats() {
    if (window.location.protocol === 'file:') return;
    try {
      const res = await fetch('/api/stats');
      if (res.ok) liveStats = await res.json();
    } catch (_e) { /* servidor local opcional */ }
  }

  window.livelyPropertyListener = (name, val) => {
    if (name === 'tema') {
      const nuevo = typeof val === 'string' ? val : (TEMAS_DISPONIBLES[val] || TEMAS_DISPONIBLES[0]);
      if (nuevo !== state.tema) { renderer.cargarTema(nuevo).then(renderer.render); }
    } else if (name === 'pantalla') {
      const nueva = (val === 2 || val === 'bloqueo') ? 'bloqueo' : ((val === 1 || val === 'secundaria') ? 'secundaria' : 'principal');
      if (nueva !== state.pantalla) { renderer.cargarTema(state.tema, { pantalla: nueva }).then(renderer.render); }
    } else if (name === 'modoHora') {
      state.modoHora = typeof val === 'string' ? modoToIdx(val) : val;
      if (state.modoHora === 1) {
        state.inicioMs = Date.now();
        const now = new Date();
        state.inicioHora = now.getHours() + now.getMinutes() / 60 + now.getSeconds() / 3600;
      }
    } else if (name === 'horaFija') state.horaFija = val;
    else if (name === 'fps') { state.fps = val; reprogramar(); }
    else if (name === 'mostrarHud') state.mostrarHud = !!val;
    else if (name === 'hudTiempo') state.hudStats.tiempo = !!val;
    else if (name === 'hudClima') state.hudStats.clima = !!val;
    else if (name === 'hudSistema') state.hudStats.sistema = !!val;
    else if (name === 'hudGpu') state.hudStats.gpu = !!val;
    else if (name === 'hudRed') state.hudStats.red = !!val;
    else if (name === 'hudAudio') state.hudStats.audio = !!val;
    else if (name === 'hudDev') state.hudStats.dev = !!val;
    else if (name === 'hudFoco') state.hudStats.foco = !!val;
    else if (name === 'hudGrimorio') state.hudStats.grimorio = !!val;
    renderer.render();
  };

  window.livelyAudioListener = audioArray => {
    if (!audioArray || !audioArray.length) return;
    let sum = 0;
    const n = Math.min(24, audioArray.length);
    for (let i = 0; i < n; i++) sum += Math.abs(audioArray[i] || 0);
    renderer.audioCtrl.setExternalEnergy(Math.min(1, (sum / n) * 2.2));
  };

  window.addEventListener('pointermove', e => {
    if (!state.parallax) return;
    state.parallaxX = (e.clientX / Math.max(1, window.innerWidth) - 0.5) * 2;
    state.parallaxY = (e.clientY / Math.max(1, window.innerHeight) - 0.5) * 2;
  });

  const wireBtn = (id, fn) => {
    const el = document.getElementById(id);
    if (el) el.addEventListener('click', ev => { ev.stopPropagation(); fn(); renderer.render(); });
  };
  wireBtn('btn-audio-play', () => renderer.audioCtrl.toggleSynth());
  wireBtn('btn-audio-prev', () => renderer.audioCtrl.prevTrack());
  wireBtn('btn-audio-next', () => renderer.audioCtrl.nextTrack());
  wireBtn('btn-foco-toggle', () => renderer.toggleFoco());
  wireBtn('btn-foco-reset', () => renderer.resetFoco());
  wireBtn('btn-foco-mode', () => renderer.setFocoModo(!state.foco.descanso));

  sincronizaEstado().finally(() => {
    const yaCargado = state.D && state.T;
    const inicio = yaCargado
      ? Promise.resolve()
      : renderer.cargarTema(state.tema, { pantalla: state.pantalla });
    inicio.then(() => {
      renderer.render();
      reprogramar();
      refrescaStats();
      setInterval(() => { if (!document.hidden) sincronizaEstado(); }, 1800);
      setInterval(() => { if (!document.hidden) refrescaStats(); }, 2500);
    });
  });
})();
