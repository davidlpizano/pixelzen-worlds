(() => {
  function lcg(seed) {
    let s = seed;
    return () => { s = (s * 16807) % 2147483647; return s / 2147483647; };
  }
  const clamp01 = v => (v < 0 ? 0 : v > 1 ? 1 : v);
  const suave = t => { t = clamp01(t); return t * t * (3 - 2 * t); };

  function loadImage(src) {
    return new Promise((res, rej) => {
      const im = new Image();
      im.onload = () => res(im);
      im.onerror = rej;
      im.src = src;
    });
  }

  function createRenderer(canvas, opts = {}) {
    const ctx = canvas.getContext('2d');
    ctx.imageSmoothingEnabled = false;

    let rng = lcg(7);
    const olas = Array.from({ length: 44 }, () => [
      300 + Math.floor(rng() * 260),
      286 + Math.floor(rng() * 108),
      3 + Math.floor(rng() * 11),
      rng() * 6.28,
      0.03 + rng() * 0.05,
      rng() < 0.35,
    ]);
    rng = lcg(21);
    const hojas = Array.from({ length: 42 }, () => [
      rng() * 640,
      rng() * 400,
      0.30 + rng() * 0.42,
      0.06 + rng() * 0.12,
      rng() * 6.28,
      Math.floor(rng() * 4),
    ]);

    const state = {
      tema: 'fittoa',
      pantalla: 'principal',
      modoHora: 1,
      horaFija: 21.5,
      fps: 16,
      mostrarHud: true,
      hudCompacto: false,
      clima: 'normal',
      audioReactivo: true,
      audioEnergy: 0,
      parallax: true,
      parallaxX: 0,
      parallaxY: 0,
      evento: null,
      _lastHourEvent: -1,
      foco: {
        activo: true,
        descanso: false,
        cicloSec: 25 * 60,
        restSec: 25 * 60,
        sesionSec: 0,
        ciclo: 1,
        lastTickMs: Date.now(),
      },
      hudStats: {
        tiempo: true,
        clima: true,
        sistema: true,
        gpu: true,
        red: true,
        audio: true,
        dev: true,
        foco: true,
        grimorio: true,
      },
      astro: null,
      _gpuName: '',
      lat: 40.4,
      lon: -3.7,
      tick: 0,
      tickFloat: null,
      inicioMs: Date.now(),
      inicioHora: 12.0,
      D: null,
      T: null,
      img: {},
      brillantes: [],
      ...(opts.initialState || {}),
    };

    const GOTAS_CLIMA = Array.from({ length: 84 }, (_, i) => [
      (i * 53 + 17) % 640,
      (i * 89 + 31) % 390,
      5 + (i % 4) * 2,
      6 + (i % 3),
    ]);
    const COPOS_CLIMA = Array.from({ length: 68 }, (_, i) => [
      (i * 61 + 29) % 640,
      (i * 97 + 13) % 390,
      0.75 + (i % 4) * 0.35,
      i * 0.7,
      i % 5 === 0 ? 2 : 1,
    ]);

    const px = (hex, op, ax, ay, aw = 1, ah = 1) => {
      if (op <= 0.004) return;
      ctx.globalAlpha = clamp01(op);
      ctx.fillStyle = hex;
      ctx.fillRect(Math.round(ax), Math.round(ay), aw, ah);
    };
    const osc = (f, p) => 0.5 + 0.5 * Math.sin(((typeof state.tickFloat === 'number') ? state.tickFloat : state.tick) * f + p);
    const heroes = (typeof createPixelZenHeroes === 'function')
      ? createPixelZenHeroes((_cr, hex, op, ax, ay, aw = 1, ah = 1) => px(hex, op, ax, ay, aw, ah))
      : { ALAS_GRULLA: [], ALAS_WYVERN: [], MOTAS_MANA: [], pintaHeroeAtras: () => {}, pintaHeroe: () => {} };
    const { ALAS_GRULLA, ALAS_WYVERN, MOTAS_MANA } = heroes;

    function fechaEfectiva() {
      const d = new Date();
      if (state.modoHora === 1) {
        const elapsedS = (Date.now() - state.inicioMs) / 1000;
        const h = (state.inicioHora + (elapsedS / 5400) * 24) % 24;
        d.setHours(Math.floor(h), Math.floor((h % 1) * 60), Math.floor((h * 3600) % 60), 0);
      } else if (state.modoHora === 2) {
        const h = ((Date.now() / 1000) % 90) / 90 * 24;
        d.setHours(Math.floor(h), Math.floor((h % 1) * 60), Math.floor((h * 3600) % 60), 0);
      } else if (state.modoHora === 3) {
        const h = state.horaFija;
        d.setHours(Math.floor(h), Math.round((h % 1) * 60), 0, 0);
      }
      return d;
    }

    function sol(fecha) {
      const rad = Math.PI / 180;
      const nn = fecha.getTime() / 86400000 + 2440587.5 - 2451545.0;
      const L = (280.460 + 0.9856474 * nn) % 360;
      const g = ((357.528 + 0.9856003 * nn) % 360) * rad;
      const lam = (L + 1.915 * Math.sin(g) + 0.020 * Math.sin(2 * g)) * rad;
      const eps = (23.439 - 0.0000004 * nn) * rad;
      const ra = Math.atan2(Math.cos(eps) * Math.sin(lam), Math.cos(lam));
      const dec = Math.asin(Math.sin(eps) * Math.sin(lam));
      const gmst = (18.697374558 + 24.06570982441908 * nn) % 24;
      let Hh = (gmst * 15 + state.lon) * rad - ra;
      Hh = Math.atan2(Math.sin(Hh), Math.cos(Hh));
      const phi = state.lat * rad;
      const e = Math.asin(Math.sin(phi) * Math.sin(dec) + Math.cos(phi) * Math.cos(dec) * Math.cos(Hh));
      const A = Math.atan2(Math.sin(Hh), Math.cos(Hh) * Math.sin(phi) - Math.tan(dec) * Math.cos(phi)) + Math.PI;
      const c0 = Math.max(-1, Math.min(1, -Math.tan(phi) * Math.tan(dec)));
      return { e: e / rad, az: (A / rad) % 360, H: Hh, H0: Math.acos(c0) };
    }

    function climaEfectivo(T, fecha) {
      const m = state.clima || 'normal';
      if (m !== 'auto') return m;
      const tid = state.tema || '';
      const h = fecha ? fecha.getHours() : 21;
      if ((tid === 'spiderman-miles-morales' && (h >= 20 || h < 5)) || tid === 'cyberpunk-edgerunners') return 'lluvia';
      if (tid === 'stranger-things' && h % 2 === 1) return 'tormenta';
      if (tid === 'dragon-ball-z' && h % 3 === 0) return 'tormenta';
      if (tid === 'attack-on-titan') return 'ceniza';
      if (tid === 'demon-slayer' || tid === 'harry-potter' || tid === 'jujutsu-kaisen') return 'niebla';
      if (tid === 'fittoa' && (h < 7 || h >= 22)) return 'niebla';
      return 'normal';
    }

    function pintaClima(t, wB, nf, fecha) {
      const modo = climaEfectivo(state.T, fecha);
      state._climaActivo = modo;
      if (modo === 'normal') return;
      const aBoost = state.audioReactivo ? (state.audioEnergy || 0) * 0.35 : 0;

      if (modo === 'lluvia' || modo === 'tormenta') {
        const pesado = modo === 'tormenta';
        const wind = pesado ? -2.2 : -1.0;
        const vyBase = pesado ? 1.55 : 1.0;
        const col = pesado ? '#bae6fd' : '#7dd3fc';
        const alphaBase = (pesado ? 0.56 : 0.42) * (1 - 0.15 * wB) + aBoost * 0.25;

        for (let i = 0; i < GOTAS_CLIMA.length; i++) {
          if (!pesado && i % 3 === 2) continue;
          const g = GOTAS_CLIMA[i];
          const gx = (((g[0] + t * wind * 2.2) % 640) + 640) % 640;
          const gy = ((g[1] + t * g[3] * vyBase) % 390);
          const len = Math.round(g[2] * (pesado ? 1.35 : 1.0));
          for (let d = 0; d < len; d++) {
            px(col, alphaBase * (1 - d * 0.08), gx + (wind < -1.5 ? -Math.floor(d * 0.4) : 0), gy + d, 1, 1);
          }
          if (gy > 282 && gy < 386 && i % 7 === 0) {
            const rw = 2 + (((t | 0) + i) % 3);
            px('#e0f2fe', 0.30 * alphaBase, gx - rw, gy + 1, rw * 2, 1);
          }
        }
        if (pesado) {
          const ti = t | 0;
          const flash = ((ti * 17 + 13) % 131);
          if (flash < 2) {
            px('#e0f2fe', flash === 0 ? 0.22 : 0.10, 0, 0, 640, 280);
            const lx = 110 + ((ti * 97) % 420);
            for (let y = 8; y < 230; y += 4) {
              const jx = lx + Math.round(Math.sin(y * 0.18 + t) * 7);
              px('#f8fafc', 0.92, jx, y, 2, 4);
              px('#7dd3fc', 0.45, jx - 1, y, 4, 4);
            }
          }
        }
      } else if (modo === 'nieve') {
        const alphaBase = 0.72 + 0.2 * nf;
        for (let i = 0; i < COPOS_CLIMA.length; i++) {
          const c = COPOS_CLIMA[i];
          const sx = (((c[0] + Math.sin(t * 0.04 + c[3]) * 14 + t * 0.15) % 640) + 640) % 640;
          const sy = (c[1] + t * c[2]) % 394;
          px(i % 4 === 0 ? '#e0f2fe' : '#ffffff', alphaBase, sx, sy, c[4], c[4]);
        }
      } else if (modo === 'ceniza') {
        const alphaBase = 0.64 + 0.25 * nf;
        for (let i = 0; i < COPOS_CLIMA.length; i++) {
          const c = COPOS_CLIMA[i];
          const sx = (((c[0] + t * 0.45 + Math.sin(t * 0.05 + c[3]) * 10) % 640) + 640) % 640;
          const sy = (((c[1] - t * c[2] * 0.85) % 394) + 394) % 394;
          px(i % 5 === 0 ? '#fb923c' : (i % 2 === 0 ? '#fed7aa' : '#94a3b8'), alphaBase, sx, sy, c[4], 1);
        }
      } else if (modo === 'niebla') {
        const col = wB > 0.5 ? '#f8fafc' : '#cbd5e1';
        for (let i = 0; i < 6; i++) {
          const mx = (((i * 120 + t * (0.25 + (i % 3) * 0.12)) % 760) + 760) % 760 - 120;
          const my = 252 + i * 14;
          const mw = 95 + (i % 3) * 45;
          px(col, 0.09 + 0.06 * nf, mx, my, mw, 5);
          px(col, 0.05 + 0.04 * nf, mx + 16, my - 2, mw - 32, 2);
        }
      }
    }

    function dispararEvento(tipo) {
      const opciones = ['cometa', 'invocacion', 'anomalia'];
      const elegido = opciones.includes(tipo)
        ? tipo
        : opciones[Math.floor(Math.random() * opciones.length)];
      state.evento = {
        tipo: elegido,
        inicioTick: state.tick,
        duracion: 96,
      };
      return elegido;
    }

    function pintaEventoEspecial(t) {
      const ev = state.evento;
      if (!ev) return;
      const age = t - ev.inicioTick;
      if (age < 0 || age > ev.duracion) {
        state.evento = null;
        return;
      }
      const p = age / ev.duracion;
      const env = p < 0.15 ? p / 0.15 : p > 0.8 ? (1 - p) / 0.2 : 1;

      if (ev.tipo === 'cometa') {
        const cx = 60 + p * 520;
        const cy = 28 + p * 125 + Math.sin(p * Math.PI) * -18;
        for (let k = 0; k < 18; k++) {
          const tx = cx - k * 3.6;
          const ty = cy - k * 1.1;
          const a = (1 - k / 18) * 0.85 * env;
          px(k < 4 ? '#ffffff' : k < 10 ? '#fde047' : '#38bdf8', a, tx, ty, k < 5 ? 3 : 2, k < 5 ? 2 : 1);
          if (k % 3 === 0) px('#fdf4ff', a * 0.8, tx - 2, ty + ((k % 2 === 0) ? 2 : -2), 1, 1);
        }
        px('#ffffff', 0.98 * env, cx - 1, cy - 1, 4, 4);
      } else if (ev.tipo === 'invocacion') {
        const col = '#facc15';
        const col2 = '#38bdf8';
        for (let a = 0; a < 16; a++) {
          const ang = (a * Math.PI * 2) / 16 + t * 0.08;
          const rx = Math.round(Math.cos(ang) * 34);
          const ry = Math.round(Math.sin(ang) * 14);
          px(a % 2 === 0 ? col : col2, 0.82 * env, 320 + rx, 224 + ry, 2, 2);
        }
        for (const pxCol of [302, 320, 338]) {
          px(col, 0.22 * env, pxCol - 1, 56, 3, 224);
          px('#ffffff', 0.50 * env, pxCol, 76, 1, 204);
        }
        px(col2, 0.35 * env, 296, 314, 48, 3);
      } else if (ev.tipo === 'anomalia') {
        for (let i = -24; i <= 24; i += 2) {
          const y = 148 + i;
          const x = 320 + Math.round(Math.sin(i * 0.35 + t * 0.25) * 6);
          px('#09090b', 0.85 * env, x - 2, y, 5, 2);
          px(i % 4 === 0 ? '#e11d48' : '#a855f7', 0.90 * env, x - 3, y, 2, 2);
          px('#f43f5e', 0.90 * env, x + 2, y, 2, 2);
        }
        for (let r = 0; r < 10; r++) {
          const ang = r * 0.62 + t * 0.14;
          const rad = 14 + (age % 22);
          px(r % 2 === 0 ? '#f43f5e' : '#c084fc', 0.72 * env, 320 + Math.round(Math.cos(ang) * rad), 148 + Math.round(Math.sin(ang) * rad * 0.7), 2, 1);
        }
      }
    }

    function toggleFoco() {
      state.foco.activo = !state.foco.activo;
      state.foco.lastTickMs = Date.now();
      return state.foco.activo;
    }

    function resetFoco() {
      state.foco.restSec = state.foco.descanso ? 5 * 60 : 25 * 60;
      state.foco.cicloSec = state.foco.restSec;
      state.foco.lastTickMs = Date.now();
    }

    function setFocoModo(esDescanso) {
      state.foco.descanso = !!esDescanso;
      resetFoco();
    }

    const TRACK_POOL = [
      ['Lullaby of Fittoa · OST', '84 BPM · FLACO LO-FI', 220.0],
      ['Kaikai Kitan · Domain OST', '128 BPM · CURSED SYNTH', 196.0],
      ['Silhouette · Baryon OST', '132 BPM · TAIKO & SHAMISEN', 246.94],
      ['DARK ARIA <LV2> · Sawano', '116 BPM · SINFÓNICO', 185.0],
      ['Sunflower · Brooklyn Mix', '90 BPM · BOOM-BAP LO-FI', 261.63],
      ["Kids / Synthwave '83", '104 BPM · ANALÓGICO', 207.65],
      ['Kamado Tanjiro no Uta', '78 BPM · SHAKUHACHI', 233.08],
      ["Hedwig's Theme · Celesta", '88 BPM · CELESTA', 293.66],
    ];

    const audioState = {
      ctx: null,
      analyser: null,
      data: null,
      masterGain: null,
      playing: false,
      timerId: null,
      step: 0,
      trackOffset: 0,
      externalMs: 0,
      externalVal: 0,
    };

    const audioCtrl = {
      isPlaying() {
        return !!audioState.playing;
      },
      startSynth() {
        if (typeof window === 'undefined') return false;
        const AC = window.AudioContext || window.webkitAudioContext;
        if (!AC) return false;
        if (!audioState.ctx) {
          audioState.ctx = new AC();
          audioState.analyser = audioState.ctx.createAnalyser();
          audioState.analyser.fftSize = 64;
          audioState.data = new Uint8Array(audioState.analyser.frequencyBinCount);
          audioState.masterGain = audioState.ctx.createGain();
          audioState.masterGain.gain.value = 0.08;
          audioState.masterGain.connect(audioState.analyser);
          audioState.analyser.connect(audioState.ctx.destination);
        }
        if (audioState.ctx.state === 'suspended') {
          audioState.ctx.resume().catch(() => {});
        }
        if (audioState.playing) return true;
        audioState.playing = true;
        const playStep = () => {
          if (!audioState.playing || !audioState.ctx) return;
          const now = audioState.ctx.currentTime;
          const baseHz = TRACK_POOL[(audioState.trackOffset % TRACK_POOL.length + TRACK_POOL.length) % TRACK_POOL.length][2];
          const scale = [1, 1.189, 1.335, 1.498, 1.782, 2.0];
          const ratio = scale[(audioState.step * 2 + (audioState.step % 3)) % scale.length];
          const oscNode = audioState.ctx.createOscillator();
          const filt = audioState.ctx.createBiquadFilter();
          const g = audioState.ctx.createGain();
          oscNode.type = audioState.step % 4 === 0 ? 'triangle' : 'sine';
          oscNode.frequency.setValueAtTime(baseHz * ratio, now);
          filt.type = 'lowpass';
          filt.frequency.setValueAtTime(920, now);
          g.gain.setValueAtTime(0.001, now);
          g.gain.exponentialRampToValueAtTime(0.32, now + 0.08);
          g.gain.exponentialRampToValueAtTime(0.001, now + 0.85);
          oscNode.connect(filt);
          filt.connect(g);
          g.connect(audioState.masterGain);
          oscNode.start(now);
          oscNode.stop(now + 0.9);
          audioState.step++;
        };
        playStep();
        audioState.timerId = setInterval(playStep, 520);
        return true;
      },
      stopSynth() {
        audioState.playing = false;
        if (audioState.timerId) {
          clearInterval(audioState.timerId);
          audioState.timerId = null;
        }
        state.audioEnergy = 0;
        return false;
      },
      toggleSynth() {
        return audioState.playing ? audioCtrl.stopSynth() : audioCtrl.startSynth();
      },
      nextTrack() {
        audioState.trackOffset++;
        if (audioState.playing) audioState.step = 0;
      },
      prevTrack() {
        audioState.trackOffset--;
        if (audioState.playing) audioState.step = 0;
      },
      setExternalEnergy(v) {
        audioState.externalVal = Math.max(0, Math.min(1, Number(v) || 0));
        audioState.externalMs = Date.now();
      },
      sampleEnergy() {
        if (audioState.playing && audioState.analyser && audioState.data) {
          audioState.analyser.getByteFrequencyData(audioState.data);
          let sum = 0;
          const bins = Math.min(12, audioState.data.length);
          for (let i = 0; i < bins; i++) sum += audioState.data[i];
          const val = Math.min(1, (sum / (bins * 255)) * 2.2);
          state.audioEnergy = state.audioEnergy * 0.45 + val * 0.55;
          return state.audioEnergy;
        }
        if (Date.now() - audioState.externalMs < 1500) {
          state.audioEnergy = state.audioEnergy * 0.4 + audioState.externalVal * 0.6;
          return state.audioEnergy;
        }
        state.audioEnergy = state.audioEnergy * 0.85;
        return state.audioEnergy;
      },
    };

    async function cargarTema(id, { pantalla } = {}) {
      state.tema = id;
      if (pantalla) state.pantalla = pantalla;
      const modo = state.pantalla === 'secundaria'
        ? 'secundario'
        : state.pantalla === 'bloqueo'
          ? 'bloqueo'
          : 'principal';
      const basePrim = `temas/${id}`;
      const base = modo === 'secundario'
        ? `${basePrim}/secundario`
        : modo === 'bloqueo'
          ? `${basePrim}/bloqueo`
          : basePrim;
      const names = [
        'cielo-noche', 'cielo-dorado', 'cielo-dia',
        'escena-noche', 'escena-dorado', 'escena-dia',
        'nubes-noche', 'nubes-dorado', 'nubes-dia',
        'sol', 'luna',
      ];
      const bundle = (typeof window !== 'undefined' && window.PIXELZEN_BUNDLE) ? window.PIXELZEN_BUNDLE : null;
      const fbBase = 'file:///C:/Users/david/.gemini/antigravity-cli/brain/8747b389-799a-4632-897a-f7f55a4233c0/scratch/out_root/docs/';
      const rawBases = (typeof window !== 'undefined' && Array.isArray(window.PIXELZEN_ASSET_BASES) && window.PIXELZEN_ASSET_BASES.length)
        ? window.PIXELZEN_ASSET_BASES
        : [''];
      const bases = rawBases.indexOf(fbBase) === -1 ? rawBases.concat([fbBase]) : rawBases;

      async function loadImageFallback(rel) {
        let lastErr;
        for (const prefix of bases) {
          try {
            return await loadImage(`${prefix}${rel}`);
          } catch (err) { lastErr = err; }
        }
        throw lastErr || new Error(`No image: ${rel}`);
      }

      async function readJsonFallback(rel) {
        let lastErr;
        for (const prefix of bases) {
          try {
            const res = await fetch(`${prefix}${rel}`);
            if (!res.ok) throw new Error(`HTTP ${res.status}`);
            return await res.json();
          } catch (err) { lastErr = err; }
        }
        throw lastErr || new Error(`No json: ${rel}`);
      }

      async function intentaCarga(dir, keySuffix) {
        const bKey = keySuffix ? `${id}/${keySuffix}` : id;
        const [datosPack, ...imgs] = await Promise.all([
          (async () => {
            if (bundle && bundle[bKey]) return bundle[bKey];
            const [datos, tema] = await Promise.all([
              readJsonFallback(`${dir}/datos.json`),
              readJsonFallback(`${dir}/tema.json`),
            ]);
            return { datos, tema };
          })(),
          ...names.map(f => loadImageFallback(`${dir}/images/${f}.png`)),
        ]);
        return { datos: datosPack.datos, tema: datosPack.tema, imgs };
      }

      let cargado;
      try {
        cargado = await intentaCarga(base, modo === 'principal' ? '' : modo);
      } catch (_err) {
        if (modo === 'principal') throw _err;
        cargado = await intentaCarga(basePrim, '');
      }
      if (state.tema !== id) return null;
      const { datos, tema, imgs } = cargado;
      const map = {};
      names.forEach((k, i) => { map[k] = imgs[i]; });
      state.D = datos;
      state.T = tema;
      state.img = map;
      state.brillantes = datos.estrellas.filter(e => e[3] === 1);
      if (opts.onTemaLoaded) opts.onTemaLoaded(tema, id);
      return tema;
    }

    function render() {
      if (!state.D || !state.T) return;
      const D = state.D, T = state.T, I = state.img;
      const tf = (typeof state.tickFloat === 'number') ? state.tickFloat : state.tick;
      const t = Math.floor(tf);
      const fecha = fechaEfectiva();
      audioCtrl.sampleEnergy();
      if (state.modoHora === 0 && opts.autoHourlyEvent !== false) {
        const hNow = fecha.getHours();
        if (fecha.getMinutes() === 0 && fecha.getSeconds() < 4 && state._lastHourEvent !== hNow) {
          state._lastHourEvent = hNow;
          dispararEvento();
        }
      }
      const pOn = !!state.parallax;
      const pxSky = pOn ? Math.round((state.parallaxX || 0) * 2) : 0;
      const pySky = pOn ? Math.round((state.parallaxY || 0) * 1.5) : 0;
      const pxCloud = pOn ? Math.round((state.parallaxX || 0) * 3.5) : 0;
      const aBoost = state.audioReactivo ? (state.audioEnergy || 0) * 0.45 : 0;

      const s = sol(fecha);
      const wA = s.e <= -14 ? 0 : s.e >= 0 ? 1 : suave((s.e + 14) / 14);
      const wB = s.e <= 0 ? 0 : s.e >= 16 ? 1 : suave(s.e / 16);
      const nf = clamp01((4 - s.e) / 10);
      const ef = clamp01((-6 - s.e) / 8);
      const solX = Math.max(30, Math.min(610, 320 + (s.az - 180) * 2.3));
      const solY = Math.max(24, 272 - Math.max(s.e, -9) * 3.6);
      const solOp = clamp01((s.e + 6) / 6);
      let f = -1;
      if (s.H >= s.H0) f = (s.H - s.H0) / (2 * Math.PI - 2 * s.H0);
      else if (s.H <= -s.H0) f = (s.H + 2 * Math.PI - s.H0) / (2 * Math.PI - 2 * s.H0);
      const lunaX = f >= 0 ? 110 + f * 420 : 320;
      const lunaY = f >= 0 ? 272 - 56 * Math.sin(Math.PI * f) * 3.6 : 300;
      const lunaOp = f >= 0 ? clamp01((-s.e - 1) / 5) : 0;
      state.astro = {
        elev: s.e,
        az: s.az,
        nf,
        ef,
        wA,
        wB,
        lunaVisible: lunaOp > 0.05,
        fase: s.e < -6 ? 'NOCHE' : s.e < 4 ? 'DORADA' : 'DÍA',
      };
      const cuerpoX = s.e > -1 ? solX : lunaX;
      const cuerpoOp = s.e > -1 ? clamp01((s.e + 2) / 6) : lunaOp;
      const conAstro = state.pantalla !== 'secundaria';

      ctx.globalAlpha = 1;
      if (wB >= 0.996) {
        ctx.drawImage(I['cielo-dia'], 0, 0);
      } else if (wA >= 0.996 && wB <= 0.01) {
        ctx.drawImage(I['cielo-dorado'], 0, 0);
      } else {
        ctx.drawImage(I['cielo-noche'], 0, 0);
        if (wA > 0.01) { ctx.globalAlpha = wA; ctx.drawImage(I['cielo-dorado'], 0, 0); }
        if (wB > 0.01) { ctx.globalAlpha = wB; ctx.drawImage(I['cielo-dia'], 0, 0); }
      }

      if (ef > 0.01) {
        D.estrellas.forEach((e, i) => {
          const o = i % 3 === 0 ? 0.3 + 0.7 * osc(0.10 + (i % 7) * 0.02, i * 1.3) : 1;
          px(e[2], Math.min(1, ef * o * (1 + aBoost * 0.5)), e[0] + pxSky, e[1] + pySky);
        });
        state.brillantes.forEach((e, i) => {
          const o = Math.min(1, ef * (0.8 + aBoost * 0.4) * Math.max(0, osc(0.07 + (i % 5) * 0.01, i * 2.1) - 0.55) / 0.45);
          if (o <= 0.004) return;
          const sx = e[0] + pxSky, sy = e[1] + pySky;
          px('#c7ccff', o, sx - 1, sy); px('#c7ccff', o, sx + 1, sy);
          px('#c7ccff', o, sx, sy - 1); px('#c7ccff', o, sx, sy + 1);
        });
      }
      const alas = T.modo_pajaros === 'wyverns' ? ALAS_WYVERN : ALAS_GRULLA;
      const cuadro = [0, 1, 2, 1][Math.floor(tf / 5) % 4];
      for (const [cx, cy] of [
        [((tf * 0.22 + 40) % 760) - 60 + pxCloud, 126 + 4 * Math.sin(tf * 0.03) + pySky],
        [((tf * 0.22 + 22) % 760) - 60 + pxCloud, 116 + 4 * Math.sin(tf * 0.03 + 1) + pySky],
        [((tf * 0.20 + 5) % 760) - 60 + pxCloud, 138 + 4 * Math.sin(tf * 0.025 + 2) + pySky],
      ]) {
        for (const [dx, dy] of alas[cuadro]) px(T.color_pajaros, 1, cx + dx, cy + dy);
        px(T.color_pajaros, 1, cx, cy + 1);
      }

      if (conAstro && solOp > 0.01) { ctx.globalAlpha = solOp; ctx.drawImage(I.sol, Math.round(solX - 104 + pxSky), Math.round(solY - 104 + pySky)); }
      if (conAstro && lunaOp > 0.01) { ctx.globalAlpha = lunaOp; ctx.drawImage(I.luna, Math.round(lunaX - 104 + pxSky), Math.round(lunaY - 104 + pySky)); }

      const noche = s.e < 0;
      const opNub = [noche ? 1 - wA : 0, noche ? wA : 1 - wB, wB];
      const fasesN = ['nubes-noche', 'nubes-dorado', 'nubes-dia'];
      D.nubes.forEach((nb, i) => {
        const v = 0.11 + (i % 4) * 0.035;
        const cx = Math.round(((nb[0] + nb[2] + tf * v) % (640 + nb[2])) - nb[2] + pxCloud);
        for (let k = 0; k < 3; k++) {
          if (opNub[k] <= 0.01) continue;
          ctx.globalAlpha = opNub[k];
          ctx.drawImage(I[fasesN[k]], 0, nb[4], nb[2], nb[3], cx, nb[1] + pySky, nb[2], nb[3]);
        }
      });

      heroes.pintaHeroeAtras(ctx, T.modo_heroe, tf, nf);

      ctx.globalAlpha = 1;
      ctx.drawImage(I['escena-noche'], 0, 0);
      if (wA > 0.01) { ctx.globalAlpha = wA; ctx.drawImage(I['escena-dorado'], 0, 0); }
      if (wB > 0.01) { ctx.globalAlpha = wB; ctx.drawImage(I['escena-dia'], 0, 0); }

      heroes.pintaHeroe(ctx, T.modo_heroe, tf, nf, state.audioReactivo ? (state.audioEnergy || 0) : 0);
      if (D.chimenea) {
        const [hx, hy] = D.chimenea;
        for (let i = 0; i < 9; i++) {
          const fase = ((tf * 0.25 + i * 5) % 45) / 45;
          const sx = hx + Math.sin(tf * 0.06 + i * 1.4) * (1.5 + fase * 5) + fase * 4;
          const sy = hy - fase * 26;
          const sz = fase < 0.35 ? 2 : 3;
          px(wB > 0.5 ? T.color_humo_dia : T.color_humo_noche, (1 - fase) * (0.28 + 0.16 * nf), sx, sy, sz, sz - 1);
        }
      }
      if (nf > 0.02) {
        D.ventanas.forEach((v, i) => {
          const p = nf * (((Math.floor(t / 24) + i) % 13 === 0) ? 0.25 : 0.7 + 0.3 * Math.sin(tf * 0.09 * (1 + (i % 4) * 0.15) + i * 2.1));
          px(T.color_ventanas, 0.12 * p, v[0] - 1, v[1] - 1, 4, 6);
          px(T.color_ventanas, p, v[0], v[1], 2, 4);
        });
        D.faroles.forEach((fr, i) => {
          const p = nf * (0.65 + 0.35 * Math.sin(tf * 0.11 + i * 1.7));
          const g = Math.max(2, Math.round(fr[2] / 3));
          px(T.color_faroles_halo, 0.06 * p, fr[0] - g * 2, fr[1] - g * 2, g * 4 + 1, g * 4 + 1);
          px(T.color_faroles_halo, 0.14 * p, fr[0] - g, fr[1] - g, g * 2 + 1, g * 2 + 1);
          px(T.color_faroles_centro, p, fr[0], fr[1], 1, 2);
        });
        if (D.runas) {
          const pr = (0.35 + 0.65 * nf) * (0.65 + 0.35 * Math.sin(tf * 0.08));
          D.runas.forEach((rn, i) => {
            const pulse = pr * (0.75 + 0.25 * Math.sin(tf * 0.12 + i * 0.4));
            px(T.color_runas_halo, 0.14 * pulse, rn[0] - 1, rn[1] - 1, 3, 3);
            px(T.color_runas_centro, pulse, rn[0], rn[1], 1, 1);
          });
        }
      }
      if (!T.sin_lago) {
        for (const o of olas) {
          px(o[5] ? T.color_olas[0] : T.color_olas[1],
            (0.08 + 0.55 * Math.max(0, Math.sin(tf * 0.04 + o[3]))) * (1 - 0.6 * wB),
            o[0] + 6 * Math.sin(tf * o[4] + o[3]), o[1], o[2], 1);
        }
        if (conAstro && cuerpoOp > 0.02) {
          const col = s.e > -1 ? T.color_reflejo_sol : T.color_reflejo_luna;
          for (let i = 0; i < 38; i++) {
            const d = 8 + i * 3, w = Math.max(3, 46 - d * 0.30);
            px(col, cuerpoOp * (0.75 - d * 0.005) * osc(0.07, i * 1.7),
              cuerpoX - w / 2 + 3 * Math.sin(tf * 0.05 + i * 1.3), 280 + d, w * (0.45 + 0.55 * osc(0.09, i * 2.2)), 1);
          }
          const dx = cuerpoX - 352;
          D.destellos.forEach((ds, i) => {
            const o = cuerpoOp * Math.pow(Math.max(0, Math.sin(tf * 0.16 + i * 0.9)), 3);
            if (o > 0.004) px(T.color_destello, o, ds[0] + dx, ds[1], 2, 1);
          });
        }
      }
      const esBrasas = T.modo_particulas === 'brasas_mana';
      hojas.forEach((p, i) => {
        const esMana = p[5] === 3;
        const ax = (p[0] + tf * p[3] + 18 * Math.sin(tf * 0.03 + p[4])) % 660 - 10;
        const dirY = (esMana || esBrasas) ? -p[2] * 0.45 : p[2];
        const ay = ((p[1] + tf * dirY) % 420 + 420) % 420 - 10;
        if (ay >= 395) return;
        if (esMana) {
          const mOp = (0.25 + 0.75 * nf) * (0.45 + 0.55 * Math.sin(tf * 0.11 + i));
          px(T.color_mana_halo, 0.25 * mOp, ax - 1, ay - 1, 3, 3);
          px(T.color_mana_centro, mOp, ax, ay, 1, 1);
        } else if (esBrasas) {
          const bOp = (0.35 + 0.65 * nf) * (0.5 + 0.5 * Math.sin(tf * 0.13 + i));
          px(T.colores_hojas[p[5] % T.colores_hojas.length], bOp, ax, ay, 1, 1);
        } else {
          const h = Math.floor(tf / 7 + i) % 2;
          px(T.colores_hojas[p[5] % T.colores_hojas.length], 0.92, ax, ay, h ? 2 : 1, h ? 1 : 2);
        }
      });
      if (nf > 0.25) {
        MOTAS_MANA.forEach((lc, i) => {
          const fx = lc[0] + 9 * Math.sin(tf * (0.021 + i * 0.002) + i * 2.3) + pxSky;
          const fy = lc[1] + 5 * Math.sin(tf * (0.017 + i * 0.0015) + i * 1.1) + pySky;
          const b = Math.min(1, nf * (1 + aBoost) * Math.pow(Math.max(0, Math.sin(tf * (0.05 + i * 0.004) + i * 1.9)), 2));
          px(T.color_fuegos_halo[i % T.color_fuegos_halo.length], 0.28 * b, fx - 1, fy - 1, 3, 3);
          px(T.color_fuegos_centro[i % T.color_fuegos_centro.length], 0.2 + 0.8 * b, fx, fy, 1, 1);
        });
      }
      if (state.hudStats && state.hudStats.foco && state.foco && state.foco.activo) {
        const zCol = state.foco.descanso ? '#38bdf8' : '#e6c06e';
        for (let z = 0; z < 4; z++) {
          const zx = 320 + Math.round(Math.sin(tf * 0.04 + z * 1.57) * 58);
          const zy = 356 + Math.round(Math.cos(tf * 0.05 + z * 1.57) * 8);
          const zo = 0.25 + 0.35 * Math.sin(tf * 0.09 + z);
          px(zCol, zo, zx, zy, 2, 1);
        }
      }
      pintaEventoEspecial(tf);
      pintaClima(tf, wB, nf, fecha);
      ctx.globalAlpha = 1;

      if (opts.onRender) opts.onRender(fecha, T);
    }

    const WORLD_THEMES = {
      'fittoa': ['#e6c06e', '#72c48c', 'rgba(230, 192, 110, 0.34)'],
      'continente-demoniaco': ['#ff7854', '#f4a261', 'rgba(255, 120, 84, 0.34)'],
      'hunter-x-hunter': ['#72c48c', '#f3c65f', 'rgba(114, 196, 140, 0.34)'],
      'black-clover': ['#b888ff', '#ef4444', 'rgba(184, 136, 255, 0.36)'],
      'spiderman-miles-morales': ['#f43f5e', '#38bdf8', 'rgba(244, 63, 94, 0.38)'],
      'solo-leveling': ['#a855f7', '#38bdf8', 'rgba(168, 85, 247, 0.42)'],
      'demon-slayer': ['#fb923c', '#22d3ee', 'rgba(251, 146, 60, 0.38)'],
      'stranger-things': ['#ef4444', '#a855f7', 'rgba(239, 68, 68, 0.40)'],
      'harry-potter': ['#eab308', '#38bdf8', 'rgba(234, 179, 8, 0.36)'],
      'naruto': ['#ff9b38', '#38bdf8', 'rgba(255, 155, 56, 0.40)'],
      'jujutsu-kaisen': ['#e11d48', '#c084fc', 'rgba(225, 29, 72, 0.40)'],
      'attack-on-titan': ['#f97316', '#22c55e', 'rgba(249, 115, 22, 0.40)'],
      'one-piece': ['#f43f5e', '#facc15', 'rgba(244, 63, 94, 0.40)'],
      'dragon-ball-z': ['#38bdf8', '#facc15', 'rgba(56, 189, 248, 0.42)'],
      'cyberpunk-edgerunners': ['#facc15', '#22d3ee', 'rgba(250, 204, 21, 0.42)'],
      'terraza-michis': ['#72c48c', '#facc15', 'rgba(114, 196, 140, 0.38)'],
      'salon-noah-maggie': ['#fbbf24', '#4ade80', 'rgba(251, 191, 36, 0.38)'],
    };

    const WORLD_AUDIO = {
      'fittoa': ['Lullaby of Fittoa · OST', '84 BPM · FLACO LO-FI', 'VOL 68%'],
      'continente-demoniaco': ['Rikarisu Wasteland · OST', '92 BPM · SYNTH AMBIENT', 'VOL 64%'],
      'hunter-x-hunter': ['Departure! (Acoustic)', '96 BPM · GUITARRA LO-FI', 'VOL 72%'],
      'black-clover': ['Haruka Mirai (Piano)', '108 BPM · ORQUESTA', 'VOL 76%'],
      'spiderman-miles-morales': ['Sunflower · Brooklyn Mix', '90 BPM · BOOM-BAP LO-FI', 'VOL 80%'],
      'solo-leveling': ['DARK ARIA <LV2> · Sawano', '116 BPM · SINFÓNICO', 'VOL 78%'],
      'demon-slayer': ['Kamado Tanjiro no Uta', '78 BPM · SHAKUHACHI', 'VOL 70%'],
      'stranger-things': ["Kids / Synthwave '83", '104 BPM · ANALÓGICO', 'VOL 74%'],
      'harry-potter': ["Hedwig's Theme · Celesta", '88 BPM · CELESTA', 'VOL 66%'],
      'naruto': ['Silhouette · Baryon OST', '132 BPM · TAIKO & SHAMISEN', 'VOL 82%'],
      'jujutsu-kaisen': ['Kaikai Kitan · Domain OST', '128 BPM · CURSED SYNTH', 'VOL 84%'],
      'attack-on-titan': ['Atæk on Titan · Sawano OST', '138 BPM · CORO ÉPICO', 'VOL 86%'],
      'one-piece': ['Drums of Liberation · Nika', '126 BPM · TAMBORES', 'VOL 85%'],
      'dragon-ball-z': ['Ultimate Battle · UI OST', '145 BPM · ROCK SINFÓNICO', 'VOL 88%'],
      'cyberpunk-edgerunners': ['I Really Want to Stay · OST', '124 BPM · SYNTHWAVE', 'VOL 84%'],
      'terraza-michis': ['Purr & Sunbeam · Terrace Mix', '76 BPM · PURR LO-FI', 'VOL 72%'],
      'salon-noah-maggie': ['Noah & Maggie · Cozy Living', '72 BPM · LIVING LO-FI', 'VOL 70%'],
    };

    function detectarGpu() {
      if (state._gpuName) return state._gpuName;
      let nombre = 'CANVAS 2D · PIXEL';
      try {
        if (typeof document !== 'undefined') {
          const glc = document.createElement('canvas');
          const gl = glc.getContext('webgl') || glc.getContext('experimental-webgl');
          if (gl) {
            const dbg = gl.getExtension('WEBGL_debug_renderer_info');
            const raw = dbg ? gl.getParameter(dbg.UNMASKED_RENDERER_WEBGL) : '';
            if (raw) {
              nombre = String(raw).replace(/ANGLE \((?:[^,]+, )?([^)]+)\).*/, '$1').replace(/Direct3D.*|OpenGL.*/i, '').trim().slice(0, 26) || 'WEBGL ACCEL';
            } else {
              nombre = 'WEBGL 2D ACCEL';
            }
          }
        }
      } catch (_e) {}
      state._gpuName = nombre;
      return nombre;
    }

    function actualizaHud(fecha, T, { quoteIntervalMs = 90000, stats = null, hudStats = null, force = false } = {}) {
      const hudEl = document.getElementById('hud');
      if (!hudEl) return;
      const nowMs = Date.now();
      const hudKey = `${state.mostrarHud}|${state.tema}|${state.hudCompacto}|${state.modoHora}|${state.clima}`;
      if (!force && state._lastHudKey === hudKey && state._lastHudMs && (nowMs - state._lastHudMs) < 950) {
        return;
      }
      state._lastHudKey = hudKey;
      state._lastHudMs = nowMs;
      const hs = hudStats || state.hudStats || {};
      const vis = {
        tiempo: hs.tiempo !== false,
        clima: !!hs.clima,
        sistema: !!hs.sistema,
        gpu: !!hs.gpu,
        red: !!hs.red,
        audio: !!hs.audio,
        dev: !!hs.dev,
        foco: !!hs.foco,
        grimorio: hs.grimorio !== false,
      };
      const visibles = Object.values(vis).filter(Boolean).length;
      const activo = state.mostrarHud && visibles > 0;
      if (!activo) {
        hudEl.style.display = 'none';
        hudEl.classList.remove('is-multicol');
        return;
      }
      hudEl.style.removeProperty('display');
      hudEl.classList.remove('is-multicol');
      hudEl.classList.toggle('is-compact', !!state.hudCompacto);

      const themeCols = WORLD_THEMES[state.tema] || WORLD_THEMES['fittoa'];
      if (themeCols) {
        hudEl.style.setProperty('--hud-accent', themeCols[0]);
        hudEl.style.setProperty('--hud-accent-2', themeCols[1]);
        hudEl.style.setProperty('--hud-border', themeCols[2]);
        if (opts.themeRoot !== false && typeof document !== 'undefined' && document.documentElement) {
          document.documentElement.style.setProperty('--hud-accent', themeCols[0]);
          document.documentElement.style.setProperty('--hud-accent-2', themeCols[1]);
          document.documentElement.style.setProperty('--hud-border', themeCols[2]);
        }
      }

      const toggleCard = (id, visible) => {
        const el = document.getElementById(id);
        if (el) el.style.display = visible ? '' : 'none';
      };
      const setTxt = (id, val) => {
        const el = document.getElementById(id);
        if (el) el.textContent = val;
      };
      const setBar = (id, pct) => {
        const el = document.getElementById(id);
        if (el) el.style.width = `${Math.max(4, Math.min(100, pct))}%`;
      };

      toggleCard('card-tiempo', vis.tiempo);
      toggleCard('card-clima', vis.clima);
      toggleCard('card-sistema', vis.sistema);
      toggleCard('card-gpu', vis.gpu);
      toggleCard('card-red', vis.red);
      toggleCard('card-audio', vis.audio);
      toggleCard('card-dev', vis.dev);
      toggleCard('card-foco', vis.foco);
      toggleCard('card-grimorio', vis.grimorio);

      const p2 = v => String(v).padStart(2, '0');
      setTxt('hud-hm', `${p2(fecha.getHours())}:${p2(fecha.getMinutes())}`);
      setTxt('hud-s', p2(fecha.getSeconds()));
      setTxt('hud-modo', ['REAL', 'CICLO 90M', 'DEMO 90S', 'FIJA'][state.modoHora]);
      setTxt('hud-fecha', fecha.toLocaleDateString('es-ES', {
        weekday: 'long', day: 'numeric', month: 'short',
      }));
      setTxt('hud-tema', (T && T.nombre) || state.tema);

      if (vis.clima) {
        const cl = (stats && stats.clima) || {};
        const astro = state.astro || sol(fecha);
        const elev = astro.elev !== undefined ? astro.elev : astro.e;
        const az = astro.az || 0;
        const faseTxt = cl.fase || astro.fase || (elev < -6 ? 'NOCHE' : elev < 4 ? 'DORADA' : 'DÍA');
        const cAct = state._climaActivo && state._climaActivo !== 'normal' ? ` · ${state._climaActivo.toUpperCase()}` : '';
        const condTxt = (cl.cond || (elev < -6 ? (astro.lunaVisible ? 'LUNA Y ESTRELLAS' : 'NOCHE PROFUNDA') : elev < 4 ? 'SOL RASANTE · DORADO' : 'CIELO DESPEJADO')) + cAct;
        const luzPct = Math.round(clamp01((elev + 18) / 68) * 100);
        setTxt('hud-clima-meta', state.clima === 'auto' ? `${faseTxt} · AUTO` : faseTxt);
        setTxt('hud-clima-elev', `${elev >= 0 ? '+' : ''}${elev.toFixed(1)}°`);
        setTxt('hud-clima-az', `${Math.round(az)}°`);
        setTxt('hud-clima-luz', condTxt);
        setBar('hud-clima-bar', luzPct);
      }

      if (vis.sistema) {
        const sis = (stats && stats.sistema) || {};
        const cpu = sis.cpu ?? Math.round(14 + 9 * Math.abs(Math.sin(state.tick * 0.08)));
        const ramTxt = sis.ram ?? `${(6.2 + 0.4 * Math.sin(state.tick * 0.03)).toFixed(1)}/16G`;
        const disco = sis.disco ?? '58%';
        const bat = sis.bat ?? 'AC';
        setTxt('hud-sys-meta', sis.up || 'EN LÍNEA');
        setTxt('hud-cpu', `${cpu}%`);
        setTxt('hud-ram', ramTxt);
        setTxt('hud-disco', disco);
        setTxt('hud-bat', bat);
        setBar('hud-cpu-bar', parseFloat(cpu) || 0);
        if (sis.ramPct !== undefined) setBar('hud-ram-bar', sis.ramPct);
      }

      if (vis.gpu) {
        const g = (stats && stats.gpu) || {};
        const uso = g.uso ?? Math.round(18 + 8 * Math.abs(Math.sin(state.tick * 0.06 + 1.1)));
        setTxt('hud-gpu-meta', g.meta || `${state.fps} FPS`);
        setTxt('hud-gpu-nombre', g.nombre || detectarGpu());
        setTxt('hud-gpu-uso', `${uso}%`);
        setTxt('hud-gpu-res', g.res || (stats && stats.gpu_vram) || '640×400 PIXEL');
        setTxt('hud-gpu-temp', g.temp || (stats && stats.gpu_temp) || `${Math.round(49 + 3 * Math.sin(state.tick * 0.04))}°C`);
        setBar('hud-gpu-bar', parseFloat(uso) || 0);
      }

      if (vis.red) {
        const red = (stats && stats.red) || {};
        const conn = typeof navigator !== 'undefined' && navigator.connection ? navigator.connection : null;
        setTxt('hud-net-iface', red.iface || (conn && conn.effectiveType ? `WEB ${conn.effectiveType.toUpperCase()}` : 'ETHERNET / WIFI'));
        setTxt('hud-ip', red.ip || (typeof location !== 'undefined' && location.hostname ? location.hostname : '127.0.0.1'));
        setTxt('hud-rx', red.rx || (conn && conn.downlink ? `${conn.downlink} Mbps` : '1.4 MB/s'));
        setTxt('hud-tx', red.tx || '240 KB/s');
      }

      if (vis.audio) {
        const au = (stats && stats.audio) || {};
        const baseInfo = WORLD_AUDIO[state.tema] || ['Ambient Pixel · OST', '90 BPM · STEREO', 'VOL 70%'];
        const off = ((audioState.trackOffset % TRACK_POOL.length) + TRACK_POOL.length) % TRACK_POOL.length;
        const info = audioState.trackOffset === 0 ? baseInfo : [TRACK_POOL[off][0], TRACK_POOL[off][1], baseInfo[2] || 'VOL 75%'];
        const synthOn = audioCtrl.isPlaying();
        const estado = au.estado || (stats && stats.audio_meta) || (synthOn ? 'SYNTH EN VIVO' : 'AMBIENT OST');
        const paused = /PAUSA/i.test(estado);
        const nivel = au.nivel ?? (synthOn ? Math.round(28 + (state.audioEnergy || 0) * 72) : paused ? 18 : Math.round(48 + 38 * Math.abs(Math.sin(state.tick * 0.24) * Math.cos(state.tick * 0.11))));
        setTxt('hud-audio-meta', estado);
        setTxt('hud-audio-track', au.pista || (stats && stats.audio_track) || info[0]);
        setTxt('hud-audio-bpm', au.detalle || (stats && stats.audio_artist) || info[1]);
        setTxt('hud-audio-vol', au.vol || (au.pista ? (paused ? 'PAUSA' : 'LIVE') : (synthOn ? 'SYNTH ON' : info[2])));
        setBar('hud-audio-bar', nivel);
        const eq = document.getElementById('hud-eq');
        if (eq && eq.children.length) {
          for (let b = 0; b < eq.children.length; b++) {
            const hPct = paused ? 15 : synthOn
              ? Math.max(15, Math.min(100, Math.round(25 + (state.audioEnergy || 0) * 65 * (0.5 + 0.5 * Math.abs(Math.sin(state.tick * 0.4 + b))))))
              : Math.round(20 + 68 * Math.abs(Math.sin(state.tick * 0.28 + b * 0.85)));
            eq.children[b].style.height = `${hPct}%`;
          }
        }
      }

      if (vis.dev) {
        const dev = (stats && stats.dev) || {};
        setTxt('hud-dev-host', dev.host || 'pixelzen-worlds');
        setTxt('hud-repo', dev.repo || 'pixelzen-worlds · main');
        setTxt('hud-tc', dev.tc || 'PY 3.12 · JS ES6 · C# GDI+');
      }

      if (vis.foco) {
        const fc = (stats && stats.foco) || {};
        const nowMs = Date.now();
        const delta = Math.max(0, Math.floor((nowMs - (state.foco.lastTickMs || nowMs)) / 1000));
        if (delta >= 1) {
          state.foco.lastTickMs += delta * 1000;
          if (state.foco.activo) {
            state.foco.sesionSec += delta;
            state.foco.restSec -= delta;
            if (state.foco.restSec <= 0) {
              state.foco.descanso = !state.foco.descanso;
              if (!state.foco.descanso) state.foco.ciclo += 1;
              state.foco.cicloSec = state.foco.descanso ? 5 * 60 : 25 * 60;
              state.foco.restSec = state.foco.cicloSec;
            }
          }
        }
        const rest = Math.max(0, state.foco.restSec);
        const tot = Math.max(1, state.foco.cicloSec);
        const mm = p2(Math.floor(rest / 60)), ss = p2(rest % 60);
        const sm = Math.floor(state.foco.sesionSec / 60), ssec = p2(state.foco.sesionSec % 60);
        const modoTxt = state.foco.descanso ? 'DESCANSO' : 'ZEN';
        const pausaTxt = state.foco.activo ? '' : ' · PAUSA';
        setTxt('hud-foco-meta', fc.meta || `CICLO ${state.foco.ciclo} · ${modoTxt}${pausaTxt}`);
        setTxt('hud-foco-timer', fc.timer || `${mm}:${ss}`);
        setTxt('hud-foco-sesion', fc.sesion || `${sm}m ${ssec}s activa`);
        setBar('hud-foco-bar', ((tot - rest) / tot) * 100);
        const btnFoco = document.getElementById('btn-foco-toggle');
        if (btnFoco) btnFoco.textContent = state.foco.activo ? '⏸' : '▶';
      }

      const citas = (T && T.citas) || [];
      if (citas.length && vis.grimorio) {
        const hk = citas[Math.floor(Date.now() / quoteIntervalMs) % citas.length];
        setTxt('hud-au', hk.au || '');
        setTxt('hud-qsub', hk.sub || '');
        setTxt('hud-qtxt', hk.es || '');
      }
    }

    return {
      state,
      cargarTema,
      render,
      actualizaHud,
      dispararEvento,
      audioCtrl,
      toggleFoco,
      resetFoco,
      setFocoModo,
      WORLD_THEMES,
      WORLD_AUDIO,
    };
  }

  window.PixelZenCanvas = { createRenderer };
})();
