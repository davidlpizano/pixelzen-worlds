// Animaciones de personajes y efectos heroicos compartidos entre GNOME Shell y Web/Lively Canvas.
// Se instancia pasando px(cr, hex, op, ax, ay, aw, ah).

function createPixelZenHeroes(px) {
  const ALAS_GRULLA = [
    [[-5, -2], [-4, -2], [-3, -1], [-2, -1], [-1, 0], [0, 0], [1, 0], [2, -1], [3, -1], [4, -2], [5, -2]],
    [[-5, 1], [-4, 1], [-3, 1], [-2, 0], [-1, 0], [0, 0], [1, 0], [2, 0], [3, 1], [4, 1], [5, 1]],
    [[-5, 2], [-4, 1], [-3, 1], [-2, 0], [-1, 0], [0, 1], [1, 0], [2, 0], [3, 1], [4, 1], [5, 2]],
  ];
  const ALAS_WYVERN = [
    [[-7, -3], [-6, -3], [-5, -2], [-4, -2], [-3, -1], [-2, -1], [-1, 0], [0, 0], [1, 0], [2, -1], [3, -1], [4, -2], [5, -2], [6, -3], [7, -3], [0, 2]],
    [[-7, 1], [-6, 1], [-5, 1], [-4, 0], [-3, 0], [-2, 0], [-1, 0], [0, 0], [1, 0], [2, 0], [3, 0], [4, 0], [5, 1], [6, 1], [7, 1], [0, 2]],
    [[-7, 3], [-6, 2], [-5, 2], [-4, 1], [-3, 1], [-2, 0], [-1, 0], [0, 1], [1, 0], [2, 0], [3, 1], [4, 1], [5, 2], [6, 2], [7, 3], [0, 2]],
  ];
  const MOTAS_MANA = [
    [70, 300], [95, 330], [130, 290], [565, 310], [590, 340],
    [20, 345], [470, 296], [160, 355], [248, 318], [520, 352],
  ];
  const MILES_FRAMES = [
    {
      hc: 23, hr: 0, rows: [
        '......................RRK.', '.....................RRKK.', '....................KKK...',
        '..........KKKKKK...KKK....', '.........KKKKKKKK.KKK.....', '........KKWWKKWWKKKR......',
        '........KKWWKKWWKKK.......', '.........KKKKKKKKK........', '......KKKKKRRRRKK.........',
        '.....KKRRKKRRRRK..........', '....KKR.KKRKKRRKKKKKKKK...', '...KKK..KKRRRRKKKKKKSSK...',
        '..KK....KKRRKK...KKK..KK..', '..K.....KK.KK.....KK....K.', '.......KK...KK............',
        '......KK.....RR...........', '.....RR......WW...........', '.....WW...................',
      ],
    },
    {
      hc: 19, hr: 0, rows: [
        '..................RRK.....', '.................RRKK.....', '................KKK.......',
        '.........KKKKKK.KKK.......', '........KKKKKKKKKK........', '.......KKWWKKWWKKK........',
        '.......KKWWKKWWKKK........', '........KKKKKKKKK.........', '.....KKKKKKRRRKK..........',
        '....KKRKKRRRRRKK..........', '....KK.KKRKKRRKKKKKKKK....', '...KK..KKRRRRKKKKKKSSK....',
        '...K...KKRRKK...KKK..KK...', '......KK..KK.....KK.......', '.....KK....RR.............',
        '....RRR....WW.............', '....WWW...................', '..........................',
      ],
    },
    {
      hc: 16, hr: 0, rows: [
        '...............RRK........', '..............RRKK........', '.............KKK..........',
        '.......KKKKKKKR...........', '......KKKKKKKKK...........', '.....KKWWKKWWKKK..........',
        '.....KKWWKKWWKKK..........', '......KKKKKKKKK...........', '....KKKKKRRRKK............',
        '...KKRKKRRRRKK............', '...KK.KKRKKRRKKKKKKK......', '..KK..KKRRRRKKKKSSKK......',
        '..K...KKRRKK..KKK..KK.....', '.....KK..KK....KK.........', '....KK....RR..............',
        '...RRR....WW..............', '...WWW....................', '..........................',
      ],
    },
    {
      hc: 22, hr: 2, rows: [
        '.........KKKKKK...........', '........KKKKKKKK..........', '.......KKWWKKWWKKK..RRK...',
        '.......KKWWKKWWKKK.RRKK...', '........KKKKKKKKK.KKK.....', '......KKKKKKKKKKK.KK......',
        '.....KKRRKKRRRRKKKK.......', '....KKR.KKRKKRRKKRRKK.....', '...KKK..KKRRRRKK..SSKK....',
        '...KK...KKRRKK.....KK.K...', '.......KK..KK.............', '......KK....RR............',
        '.....RRR....WW............', '.....WWW..................', '..........................',
        '..........................', '..........................', '..........................',
      ],
    },
  ];
  const MILES_HANG_ROWS = [
    [
      '......BRB......', '.....BKKKB.....', '....BKK.KKB....', '...BKK...KKB...',
      '...BRK...KRB...', '....BKKKKKB....', '...BKKRRRKKB...', '..BKKRRRRRKKB..',
      '..BRKRRRRRKRB..', '.BKK.KKKKK.KKB.', '.BK...KRK...KB.', '....BKKKKKB....',
      '...BKKKKKKKB...', '..BKKWKKKWKKB..', '..BKWWKKKWWKB..', '..BKKWKKKWKKB..',
      '...BKKRRRKKB...', '....BKKKKKB....',
    ],
    [
      '......BRB......', '.....BKKKB.....', '....BKK.KKB....', '...BKK...KKB...',
      '...BRK...KRB...', '....BKKKKKB....', '...BKKRRRKKB...', '..BKKRRRRRKKB..',
      '..BRKRRRRRKRB..', '..BK.KKKKK.KKB.', '.....BKRK...KB.', '....BKKKKKB....',
      '...BKKKKKKKB...', '..BKKKKKKKKKB..', '..BKKWKKKWKKB..', '..BKKKKKKKKKB..',
      '...BKKRRRKKB...', '....BKKKKKB....',
    ],
  ];
  const MILES_COLS = {
    K: '#151521', S: '#2e3358', R: '#eb2d3c', H: '#ff5470', W: '#e4eeff', B: '#4a527a', E: '#00e5ff',
  };
  const osc = (t, f, p) => 0.5 + 0.5 * Math.sin(t * f + p);

  function pintaMiles(cr, t, nf) {
    const P = 340, mitad = 170;
    const fase = ((t % P) + P) % P;
    const der = fase < mitad;
    const u = der ? fase / mitad : (fase - mitad) / mitad;
    const flip = !der;
    const x = der ? -24 + u * 688 : 664 - u * 688;
    const arcW = 688 / 3;
    const arcIdx = Math.min(2, Math.floor(u * 3));
    const su = u * 3 - arcIdx;
    const tieneRed = su >= 0.08 && su <= 0.86;
    const fIdx = !tieneRed ? 3 : su < 0.34 ? 0 : su < 0.64 ? 1 : 2;
    let y = (der ? 62 : 76) + 52 * Math.sin(su * Math.PI);
    if (!tieneRed) {
      const j = su > 0.86 ? (su - 0.86) / 0.22 : (su + 0.14) / 0.22;
      y -= 7 * Math.sin(Math.min(1, Math.max(0, j)) * Math.PI);
    }
    const mx = Math.round(x), my = Math.round(y);
    const fr = MILES_FRAMES[fIdx];

    if (tieneRed) {
      const arcStart = der ? -24 + arcIdx * arcW : 664 - arcIdx * arcW;
      const ax = Math.round(der ? arcStart + arcW * 0.62 : arcStart - arcW * 0.62);
      const hx = mx + (flip ? 13 - fr.hc : fr.hc - 13);
      const hy = my + fr.hr - 10;
      const steps = Math.max(1, Math.max(Math.abs(ax - hx), Math.abs(hy)));
      for (let i = 0; i <= steps; i++) {
        const wx = Math.round(hx + (ax - hx) * i / steps);
        const wy = Math.round(hy * (1 - i / steps));
        px(cr, '#dceaff', (i % 2 === 0 ? 0.88 : 0.68) * (1 - 0.12 * nf), wx, wy, 1, 1);
      }
    }

    for (let r = 0; r < fr.rows.length; r++) {
      const row = fr.rows[r];
      for (let c = 0; c < row.length; c++) {
        const ch = row[c];
        if (ch !== '.') px(cr, MILES_COLS[ch] || MILES_COLS.K, 1, mx + (flip ? 13 - c : c - 13), my + r - 10, 1, 1);
      }
    }

    const ti = t | 0;
    const tailDir = der ? -1 : 1;
    for (let k = 0; k < 3; k++) {
      if ((ti + k) % 3 !== 0) continue;
      const sx = mx + tailDir * (10 + k * 4) + Math.round(Math.sin(t * 0.6 + k * 2) * 2);
      const sy = my + 2 + Math.round(Math.cos(t * 0.5 + k * 1.7) * 3);
      px(cr, k === 1 ? '#ffd840' : '#00e5ff', 0.85, sx, sy, 1, 1);
    }
  }

  function pintaMilesColgado(cr, t, nf) {
    const CYCLE = 220;
    const xs = [108, 224, 348, 418, 162, 578];
    const dropYs = [96, 82, 108, 88, 76, 94];
    const slot = Math.floor(t / CYCLE);
    const idx = ((slot % xs.length) + xs.length) % xs.length;
    const u = (((t % CYCLE) + CYCLE) % CYCLE) / CYCLE;
    if (u < 0.14 || u >= 0.88) return;

    const anchorX = xs[idx], targetY = dropYs[idx];
    let yTop, swayAmp = 0;
    if (u < 0.30) {
      const p = (u - 0.14) / 0.16;
      const ease = 1 - Math.pow(1 - p, 2);
      yTop = Math.round(-20 + (targetY + 20) * ease + Math.sin(p * Math.PI) * 5);
      swayAmp = 1;
    } else if (u < 0.72) {
      yTop = Math.round(targetY + Math.sin(t * 0.22));
      swayAmp = 2;
    } else {
      const p = (u - 0.72) / 0.16;
      yTop = Math.round(targetY - (targetY + 22) * (p * p));
      swayAmp = 1;
    }

    const mx = anchorX + Math.round(Math.sin(t * 0.14) * swayAmp);
    const footY = yTop + 1;
    if (footY > 0) {
      const steps = Math.max(1, footY);
      for (let i = 0; i <= steps; i++) {
        const wx = Math.round(anchorX + (mx - anchorX) * i / steps);
        const wy = Math.round(footY * i / steps);
        if (wy >= 0) px(cr, '#dceaff', (i % 2 === 0 ? 0.86 : 0.64) * (1 - 0.12 * nf), wx, wy, 1, 1);
      }
    }

    const fIdx = (u >= 0.30 && u < 0.72 && ((t | 0) % 64) < 5) ? 1 : 0;
    const rows = MILES_HANG_ROWS[fIdx];
    for (let r = 0; r < rows.length; r++) {
      const ry = yTop + r;
      if (ry < 0) continue;
      const row = rows[r];
      for (let c = 0; c < row.length; c++) {
        const ch = row[c];
        if (ch !== '.') px(cr, MILES_COLS[ch] || MILES_COLS.K, 1, mx + c - 7, ry, 1, 1);
      }
    }
  }

  function pintaFerry(cr, t, nf) {
    const P = 1800, mitad = 900;
    const f = ((t % P) + P) % P;
    const der = f < mitad;
    const u = der ? f / mitad : (f - mitad) / mitad;
    const fx = Math.round(der ? 180 + u * 320 : 500 - u * 320);
    const fy = 295 + (Math.sin(t * 0.08) > 0.6 ? 1 : 0);
    const dir = der ? 1 : -1;
    px(cr, '#141a2e', 0.95, fx - 10, fy, 20, 2);
    px(cr, '#e65c28', 0.95, fx - 9, fy - 1, 18, 1);
    px(cr, '#dce6f2', 0.95, fx - 7, fy - 3, 14, 2);
    px(cr, '#f0682c', 0.95, fx - 6, fy - 4, 12, 1);
    px(cr, '#dce6f2', 0.95, fx - 3, fy - 6, 6, 2);
    px(cr, '#1e2438', 0.95, fx - dir * 1, fy - 8, 2, 2);
    if (nf > 0.15) {
      for (let wx = -5; wx <= 5; wx += 2) px(cr, '#ffe088', 0.85 * nf, fx + wx, fy - 3, 1, 1);
      px(cr, '#ff3658', 0.9 * nf, fx - dir * 9, fy - 2, 1, 1);
      px(cr, '#54ff98', 0.9 * nf, fx + dir * 9, fy - 2, 1, 1);
    }
    for (let k = 1; k <= 7; k++) {
      if ((Math.floor(t / 2) + k) % 2 === 0) px(cr, '#d4ecff', 0.45 * (1 - k / 8), fx - dir * (10 + k * 2), fy + 1, 2, 1);
    }
  }

  function pintaTormentaStranger(cr, t, nf, modo) {
    const pulse = 0.04 + 0.05 * osc(t, 0.08, 0.5);
    px(cr, '#ff1e3c', pulse * (0.6 + 0.4 * nf), 0, 0, 640, 276);
    const slot = Math.floor(t / 44);
    const age = (t | 0) % 44;
    if (age >= 6) return;
    const alpha = (1 - age / 6) * (age % 2 === 0 ? 1 : 0.55);
    px(cr, '#ff2a48', alpha * 0.14, 0, 0, 640, 272);
    const anchors = modo === 'stranger_demogorgon'
      ? [385, 428, 472, 340]
      : modo === 'stranger_reloj'
        ? [276, 364, 240, 400]
        : [132, 174, 212, 154];
    const bx0 = anchors[slot % anchors.length];
    let lx = bx0;
    const yIni = modo === 'stranger_azotamentes' ? 54 : 26;
    for (let i = 0; i < 120; i += 2) {
      const jit = Math.sin(slot * 7.3 + i * 0.47) > 0.25 ? 2 : (Math.cos(slot * 3.1 + i * 0.61) < -0.25 ? -2 : 0);
      lx += jit;
      const ly = yIni + i;
      if (ly > 268) break;
      px(cr, '#ff2848', alpha * 0.72, lx - 1, ly, 3, 2);
      px(cr, '#ffd8e2', alpha, lx, ly, 1, 2);
      if (i === 44 || i === 82) {
        const dir = (slot + i) % 2 === 0 ? 1 : -1;
        for (let b = 0; b < 22; b += 2) {
          px(cr, '#ff3454', alpha * 0.68, lx + dir * b, ly + b, 2, 2);
        }
      }
    }
  }

  function pintaStrangerPrincipal(cr, t, nf) {
    for (let i = 0; i < 12; i++) {
      const ang = t * 0.07 + i * 0.52;
      const wx = 168 + Math.round(Math.cos(ang) * (24 + (i % 4) * 14));
      const wy = 148 + Math.round(Math.sin(ang * 0.8) * 32 - ((t * 0.4 + i * 5) % 18));
      px(cr, i % 2 === 0 ? '#ff304c' : '#2a0814', 0.48 + 0.35 * nf, wx, wy, 2, 2);
    }

    const riders = [
      [0, 344, '#2c5ca8', '#e64242'],
      [-42, 338, '#d43c44', '#1b2030'],
      [-84, 346, '#e28832', '#263826'],
      [-126, 340, '#3e8a5c', '#543884'],
    ];
    const leadX = ((t * 1.65) % 860) - 70;
    const spoke = Math.floor(t / 2) % 2;
    for (let idx = 0; idx < riders.length; idx++) {
      const [ox, by, coat, hat] = riders[idx];
      const cx = Math.round(leadX + ox);
      if (cx < -35 || cx > 665) continue;
      const bob = Math.sin(t * 0.45 + idx * 1.4) > 0.35 ? -1 : 0;
      for (const wx of [cx - 6, cx + 6]) {
        px(cr, '#1d202c', 0.95, wx - 4, by - 7, 8, 2);
        px(cr, '#1d202c', 0.95, wx - 4, by - 1, 8, 2);
        px(cr, '#1d202c', 0.95, wx - 4, by - 6, 2, 6);
        px(cr, '#1d202c', 0.95, wx + 2, by - 6, 2, 6);
        px(cr, '#a8b4cc', 0.9, wx + (spoke ? 0 : -1), by - 4, 1, 1);
        px(cr, '#a8b4cc', 0.85, wx + (spoke ? 1 : 0), by - 5, 1, 1);
      }
      px(cr, '#3a4052', 0.95, cx - 6, by - 6, 13, 1);
      px(cr, '#7c8498', 0.95, cx + 4, by - 10, 1, 4);
      px(cr, coat, 0.96, cx - 2, by - 14 + bob, 5, 6);
      px(cr, '#181a24', 0.96, cx - 3, by - 13 + bob, 2, 4);
      px(cr, '#deb292', 0.96, cx - 1, by - 16 + bob, 3, 2);
      px(cr, hat, 0.96, cx - 2, by - 18 + bob, 5, 2);
      for (let i = 1; i <= 22; i += 2) {
        const rad = Math.max(1, Math.floor(i / 5));
        const opBeam = Math.max(0.04, (0.34 - i * 0.013) * (0.45 + 0.55 * nf));
        px(cr, '#fff0b8', opBeam, cx + 7 + i, by - 9 - rad + 1, 2, rad * 2 - 1);
      }
      px(cr, '#fff8d4', 0.95, cx + 6, by - 9, 2, 1);
    }
  }

  function pintaStrangerDemogorgon(cr, t, nf) {
    const mawP = 0.45 + 0.55 * osc(t, 0.14, 0.2);
    px(cr, '#ff2448', 0.22 * mawP, 412, 314, 13, 13);
    px(cr, '#ffc8d4', 0.65 * mawP, 417, 319, 3, 3);
    for (let i = 0; i < 10; i++) {
      const sx = 392 + ((i * 19 + Math.round(t * 0.5)) % 56);
      const sy = 342 - ((t * 0.55 + i * 9) % 44);
      px(cr, i % 2 === 0 ? '#ff3a5e' : '#ffd0d8', 0.55, sx, sy, 1, 1);
    }
    const cols = ['#ff2e6a', '#48e8ff', '#ffd448', '#52ff88'];
    const active = Math.floor(t / 6) % 8;
    for (let i = 0; i < 8; i++) {
      const lx = 78 + i * 10;
      const ly = 292 + (i % 2) * 5;
      const isLit = i === active || ((Math.floor(t / 14) + i) % 5 === 0);
      const op = (isLit ? 0.95 : 0.30) * (0.55 + 0.45 * nf);
      const col = cols[i % 4];
      px(cr, col, 0.24 * op, lx - 1, ly - 1, 4, 3);
      px(cr, col, op, lx, ly, 2, 1);
    }
  }

  function pintaStrangerReloj(cr, t, nf) {
    const ang = 0.14 * Math.sin(t * 0.14);
    const px0 = 320, py0 = 232, len = 56;
    for (let r = 0; r <= len; r += 2) {
      const rx = Math.round(px0 + Math.sin(ang) * r);
      const ry = Math.round(py0 + Math.cos(ang) * r);
      px(cr, '#e6bc58', 0.96, rx, ry, 1, 2);
    }
    const bx = Math.round(px0 + Math.sin(ang) * len);
    const by = Math.round(py0 + Math.cos(ang) * len);
    px(cr, '#f2ca62', 0.98, bx - 3, by - 3, 7, 7);
    px(cr, '#fff4be', 0.90, bx - 1, by - 1, 3, 3);
    for (let k = 0; k < 6; k++) {
      const cy = 172 + ((t * 2 + k * 33) % 180);
      const cx = 320 + Math.round(Math.sin(cy * 0.15 + t * 0.08) * 14);
      px(cr, '#ff4868', 0.55 + 0.35 * nf, cx, cy, 2, 2);
    }
  }

  function pintaDemonRengoku(cr, t, nf) {
    const ti = t | 0;
    const imp = Math.pow(Math.max(0, Math.sin(t * 0.28)), 4);
    const clashTick = ti % 24;
    const clash = clashTick < 5 ? 1 - clashTick / 5 : 0;
    const env = 0.65 + 0.35 * nf;

    px(cr, '#ff5820', (0.07 + 0.11 * imp) * env, 286, 266, 94, 46);
    px(cr, '#38d8ff', (0.07 + 0.11 * imp) * env, 404, 268, 96, 46);
    if (clash > 0.05) {
      const rC = Math.round(14 + (1 - clash) * 18);
      px(cr, '#ffe8a0', 0.16 * clash * env, 418 - rC, 284 - Math.round(rC * 0.7), rC * 2, Math.round(rC * 1.4));
    }

    for (let i = 0; i < 8; i++) {
      const fx = 306 + i * 3;
      const wave = Math.sin(t * 0.55 + i * 0.85);
      const fy = 287 + Math.round(i * 0.3 + wave * 1.8);
      const fh = 5 + ((Math.floor(t * 0.6) + i * 3) % 5);
      px(cr, '#ff3624', 0.82, fx, fy + fh - 3, 2, 3);
      px(cr, '#ff7e24', 0.88, fx, fy + 2, 2, 3);
      px(cr, '#ffd84c', 0.90, fx, fy, 2, 2);
    }
    for (let k = 0; k < 6; k++) {
      const lift = ((t * 1.6 + k * 7) % 18);
      const ax = 324 + ((k * 7) % 21) + Math.round(Math.sin(t * 0.4 + k) * 2);
      const ay = 294 - Math.round(lift);
      px(cr, k % 2 === 0 ? '#ffd84c' : '#ff5e24', Math.max(0.15, (1 - lift / 18) * 0.85), ax, ay, 2, 2);
    }
    const bPos = (t * 2) % 20;
    px(cr, '#fff8d8', 0.95, 342 + bPos, 292 - Math.floor(bPos / 4), 3, 1);

    for (let step = 0; step < 19; step++) {
      const u = step / 18;
      const pulseU = ((t * 0.11 + u * 2.2) % 1.0);
      const bx = Math.round(356 + u * 64);
      const by = Math.round(288 - Math.sin(u * Math.PI * 0.85) * 18 + Math.sin(u * 9.0 - t * 0.65) * 3.2);
      const rad = 3 + ((step + Math.floor(t * 0.5)) % 3);
      px(cr, '#ff2a18', 0.42, bx - rad - 1, by - rad - 1, (rad + 1) * 2, (rad + 1) * 2);
      px(cr, '#ff7e24', 0.84, bx - rad, by - rad, rad * 2, rad * 2);
      px(cr, pulseU > 0.62 ? '#fff8c8' : '#ffd84c', 0.94, bx - 1, by - 1, 3, 3);
      const angR = t * 0.5 + step * 0.8;
      px(cr, '#ffe888', 0.80, bx + Math.round(Math.cos(angR) * 4), by + Math.round(Math.sin(angR) * 6), 2, 2);
    }
    const jaw = Math.sin(t * 0.45) > 0 ? 1 : 0;
    px(cr, '#fff8d0', 0.96, 417, 281 - jaw, 6, 3);
    px(cr, '#ff7e24', 0.92, 421, 278 - jaw, 5, 2);
    px(cr, '#ff3624', 0.90, 421, 286 + jaw, 5, 2);

    const rot = t * 0.065;
    for (let p = 0; p < 12; p++) {
      const ang = rot + (p * Math.PI * 2) / 12;
      const cA = Math.cos(ang), sA = Math.sin(ang);
      for (let r = 14; r <= 42; r += 4) {
        const rx = Math.round(456 + cA * r);
        const ry = Math.round(312 + sA * (r * 0.18));
        const esPunta = r >= 36;
        px(cr, esPunta ? '#ffffff' : (r >= 26 ? '#92f0ff' : '#38d8ff'), esPunta ? 0.95 : 0.78, rx, ry, esPunta ? 2 : 1, 1);
      }
    }
    px(cr, '#ffd84c', 0.95, 450, 284, 1, 1);
    px(cr, '#ffd84c', 0.95, 454, 284, 1, 1);
    for (let k = 0; k < 4; k++) {
      const prog = ((t * 0.13 + k * 0.25) % 1.0);
      const ax = Math.round(446 - prog * 28);
      const ay = Math.round(288 + ((k % 2 === 0 ? -1 : 1) * 5) + Math.sin(t * 0.4 + k) * 2);
      px(cr, '#38d8ff', 0.85, ax, ay - 3, 4, 7);
      px(cr, '#d8385c', 0.72, ax + 2, ay - 2, 3, 5);
      px(cr, '#ffffff', 0.95, ax - 1, ay - 1, 2, 3);
    }

    for (let rIdx = 0; rIdx < 2; rIdx++) {
      const rad = 4 + ((t * 2 + rIdx * 7) % 14);
      const opRing = Math.max(0.15, (1 - (rad - 4) / 14) * 0.9);
      for (let i = 0; i < 16; i++) {
        const a = (i * Math.PI * 2) / 16 + t * 0.08;
        const sx = Math.round(418 + Math.cos(a) * rad);
        const sy = Math.round(284 + Math.sin(a) * rad * 0.75);
        px(cr, sx < 418 ? '#ffd84c' : '#38d8ff', opRing, sx, sy, 2, 1);
      }
    }
    for (let b = 0; b < 6; b++) {
      if ((ti + b) % 3 === 0) continue;
      const ba = t * 0.37 + b * 1.05;
      const bl = 7 + ((ti * 3 + b * 5) % 10);
      const colB = b % 2 === 0 ? '#ffe898' : '#78ecff';
      for (let s = 2; s <= bl; s += 2) {
        const jx = Math.round(Math.sin(s + t + b) * 1.4);
        px(cr, colB, 0.88, 418 + Math.round(Math.cos(ba) * s) + jx, 284 + Math.round(Math.sin(ba) * s * 0.8), 1, 1);
      }
    }
    if (clash > 0.2) px(cr, '#ffffff', 0.98 * clash, 416, 282, 5, 5);

    const fPulse = 0.7 + 0.3 * osc(t, 0.22, 0.4);
    px(cr, '#ff8438', 0.22 * fPulse * env, 141, 222, 14, 9);
    for (let i = 1; i <= 34; i += 2) {
      const rh = 1 + Math.floor(i / 6);
      px(cr, '#ffe898', Math.max(0.03, (0.36 - i * 0.009) * fPulse * env), 225 + i, 238 - rh, 2, rh * 2);
    }
  }

  function pintaDemonTokito(cr, t, nf) {
    const ti = t | 0;
    const env = 0.65 + 0.35 * nf;

    for (let i = 0; i < 6; i++) {
      const span = 350;
      const bx = 185 + ((Math.round(t * (1.2 + (i % 3) * 0.5)) + i * 64) % span);
      const by = 288 + (i % 3) * 11 + Math.round(Math.sin(t * 0.12 + i) * 2);
      const bw = 28 + (i % 3) * 14;
      px(cr, '#54e8cc', 0.16 * env, bx, by, bw, 3);
      px(cr, '#b8fff4', 0.22 * env, bx + 6, by + 1, Math.round(bw * 0.6), 1);
    }

    for (let h = 0; h < 5; h++) {
      const hx = 259 + h * 3;
      const hy = 283 + h + Math.round(Math.sin(t * 0.45 + h) * 1.4);
      px(cr, h > 2 ? '#d8fff8' : '#74f0dc', 0.85, hx, hy, 2, 2);
    }
    const bladeS = (t * 2) % 18;
    px(cr, '#e8fffc', 0.95, 287 + bladeS, 285 - Math.floor(bladeS / 4), 3, 1);

    for (let a = 0; a < 3; a++) {
      const prog = ((t * 0.10 + a * 0.33) % 1.0);
      const sx = Math.round(304 + prog * 144);
      const sy = Math.round(284 + Math.sin(prog * Math.PI * 2 + a) * 9);
      for (let dy = -6; dy <= 6; dy += 2) {
        const arch = Math.round((dy * dy) / 7);
        px(cr, '#54e8cc', 0.72, sx - arch, sy + dy, 3, 2);
        if (Math.abs(dy) <= 3) px(cr, '#e8fffc', 0.92, sx - arch + 1, sy + dy, 2, 1);
      }
    }

    const flashTick = ti % 28;
    if (flashTick < 9) {
      const fAl = 1 - flashTick / 9;
      px(cr, '#54e8cc', 0.18 * fAl * env, 424, 260, 56, 42);
      for (let d = -14; d <= 14; d += 2) {
        px(cr, '#74f8e8', 0.86 * fAl, 444 + d, 280 + Math.round(d * 0.65), 2, 2);
        px(cr, '#ffffff', 0.95 * fAl, 444 + d, 280 - Math.round(d * 0.65), 2, 2);
      }
    }

    for (const side of [-1, 1]) {
      for (let seg = 0; seg < 12; seg++) {
        const u = seg / 11;
        const wave = Math.sin(t * 0.42 + u * 4.5 + side) * (2.5 + u * 3.5);
        const tx = Math.round(468 + side * (13 + seg * 2.5));
        const ty = Math.round(294 - Math.sin(u * 3.6) * 14 - u * 9 + wave);
        const rt = u < 0.5 ? 2 : 1;
        px(cr, '#2898a8', 0.75, tx - rt, ty - rt, rt * 2 + 1, rt * 2 + 1);
        px(cr, '#98fff0', 0.86, tx, ty, rt, rt);
      }
      if ((ti + (side > 0 ? 1 : 0)) % 2 === 0) {
        const sxp = 468 + side * (36 + (ti % 5));
        const syp = 266 + Math.round(Math.cos(t * 0.5 + side) * 4);
        px(cr, '#d8fffc', 0.88, sxp, syp, 2, 2);
      }
    }
    px(cr, '#ff4878', 0.92, 467, 270, 2, 2);
    px(cr, '#ffd858', 0.90, 467, 275, 2, 1);

    for (let j = 0; j < 3; j++) {
      const gp = ((t * 0.12 + j * 0.33) % 1.0);
      const gx = Math.round(452 - gp * 60);
      const gy = Math.round(278 + (j - 1) * 5 + Math.sin(t * 0.5 + j) * 2);
      px(cr, '#54e4d4', 0.86, gx, gy, 5, 1);
      px(cr, '#ff5488', 0.80, gx + 4, gy, 2, 1);
    }
    if (ti % 3 !== 0) {
      px(cr, '#ffffff', 0.90, 391, 279, 3, 3);
      px(cr, '#ff6494', 0.80, 394 + (ti % 4) - 2, 275 + ((ti * 2) % 6), 2, 2);
    }
  }

  function pintaDemonGlicinias(cr, t, nf) {
    const env = 0.65 + 0.35 * nf;
    const wCols = ['#c884ff', '#f0d8ff', '#9248e8', '#e6b8ff'];
    for (let i = 0; i < 20; i++) {
      const speedY = 0.45 + (i % 4) * 0.18;
      const speedX = 0.25 + (i % 3) * 0.12;
      const py = 116 + ((Math.round(t * speedY) + i * 19) % 218);
      const px0 = 36 + ((Math.round(t * speedX + Math.sin(t * 0.08 + i) * 14) + i * 31) % 568);
      const horiz = (Math.floor(t / 5) + i) % 2 === 0;
      px(cr, wCols[i % 4], 0.82 * env, px0, py, horiz ? 2 : 1, horiz ? 1 : 2);
    }
    for (let g = 0; g < 10; g++) {
      const gx = g < 4 ? (52 + g * 44) : g < 8 ? (418 + (g - 4) * 44) : (276 + (g - 8) * 86);
      const gy = g < 8 ? (136 + (g % 3) * 14) : 150;
      const op = (0.35 + 0.65 * osc(t, 0.16, g * 1.3)) * env;
      px(cr, '#f0d8ff', op, gx, gy, 2, 2);
    }

    const pulseF = 0.72 + 0.28 * osc(t, 0.24, 0.7);
    px(cr, '#ff7828', 0.16 * pulseF * env, 300, 266, 50, 24);
    for (let k = 0; k < 9; k++) {
      const kx = 307 + k * 4;
      const kyBase = 285 - Math.floor((k * 4 + 13) / 5);
      const fh = 3 + ((Math.floor(t * 0.7) + k * 3) % 7);
      const sway = Math.round(Math.sin(t * 0.5 + k * 0.9) * 1.2);
      px(cr, '#ff3820', 0.78, kx + sway, kyBase - fh, 2, 3);
      px(cr, '#ff9428', 0.88, kx, kyBase - Math.max(2, fh - 2), 2, 3);
      px(cr, '#fff4b8', 0.95, kx, kyBase - 1, 2, 2);
    }
    for (let e = 0; e < 5; e++) {
      const rise = ((t * 1.2 + e * 9) % 34);
      const ex = 310 + ((e * 11) % 30) + Math.round(Math.sin(t * 0.2 + e * 1.7) * 4);
      const ey = 280 - Math.round(rise);
      px(cr, e % 2 === 0 ? '#ffe888' : '#ff9838', Math.max(0.1, (1 - rise / 34) * 0.88), ex, ey, 1, 2);
    }
  }

  function pintaNarutoBaryon(cr, t, nf) {
    const ti = t | 0;
    const env = 0.68 + 0.32 * nf;
    const kPulse = 0.5 + 0.5 * Math.sin(t * 0.26);

    for (const ex of [121, 154]) {
      px(cr, '#ff2c18', 0.48 * kPulse * env, ex - 4, 173, 8, 5);
      px(cr, '#ff9430', 0.88, ex - 2, 174, 5, 3);
      px(cr, '#fff0a8', 0.96, ex, 174, 2, 2);
    }
    for (let w = 0; w < 4; w++) {
      const wy = 192 + w * 4 - ((ti + w * 2) % 6);
      px(cr, '#ff5a24', 0.36 * env, 130 + ((w * 7) % 16), wy, 2, 3);
    }

    for (let k = 0; k < 9; k++) {
      const baseAng = -2.42 + k * 0.24;
      const len = 64 + (k % 3) * 18;
      for (let s = 2; s < 10; s++) {
        const u = s / 10;
        const sway = Math.sin(t * 0.34 + k * 0.9 + u * 3.1) * (4 + u * 8);
        const tx = Math.round(192 + Math.cos(baseAng) * (len * u) + sway * 0.45);
        const ty = Math.round(314 + Math.sin(baseAng) * (len * u) + sway * 0.3);
        if (tx < 48 || tx > 258 || ty < 178 || ty > 342) continue;
        const tip = s > 7;
        px(cr, tip ? '#ffd068' : (s % 2 === 0 ? '#ff3c24' : '#ff7c2c'), (0.28 + 0.36 * (1 - u)) * env, tx, ty, tip ? 2 : 3, 2);
      }
    }

    for (let p = 0; p < 7; p++) {
      const rise = ((t * 1.7 + p * 5) % 28);
      const ax = 188 + ((p * 5) % 20) + Math.round(Math.sin(t * 0.45 + p) * 2);
      const ay = 340 - Math.round(rise);
      px(cr, rise > 18 ? '#ff2c1c' : '#ff9c38', Math.max(0.12, (1 - rise / 28) * 0.78), ax, ay, 2, 2);
    }
    px(cr, '#ffe088', 0.85, 188, 300 + (ti % 2), 1, 2);
    px(cr, '#ffe088', 0.85, 204, 300 + ((ti + 1) % 2), 1, 2);

    const rPulse = 0.65 + 0.35 * Math.sin(t * 0.65);
    px(cr, '#ff4020', 0.35 * rPulse, 214, 314, 13, 13);
    px(cr, '#ff9e3c', 0.80, 217, 317, 7, 7);
    px(cr, '#fff6dc', 0.96, 219, 319, 3, 3);
    for (let r = 0; r < 4; r++) {
      const ra = t * 0.55 + r * (Math.PI / 2);
      const rx = 220 + Math.round(Math.cos(ra) * 5.2);
      const ry = 320 + Math.round(Math.sin(ra) * 5.2);
      px(cr, r % 2 === 0 ? '#ffe898' : '#ff4c28', 0.92, rx, ry, 2, 2);
    }

    if (ti % 4 !== 0) {
      const cxm = 258 + ((t * 7) % 48);
      const cym = 304 - Math.round((cxm - 258) * 0.4) + Math.round(Math.sin(t * 0.9) * 5);
      px(cr, '#ffd878', 0.90, cxm, cym, 3, 1);
      px(cr, '#ff4828', 0.72, cxm - 2, cym + 1, 2, 1);
    }

    const cubos = [[322, 280, 7], [290, 294, 5], [346, 266, 4]];
    for (let i = 0; i < cubos.length; i++) {
      const bob = Math.round(Math.sin(t * 0.24 + i * 2.1) * 3);
      const cx = cubos[i][0], cy = cubos[i][1] + bob, sz = cubos[i][2];
      const flash = ((ti + i * 11) % 36) < 4;
      px(cr, flash ? '#ffb8ff' : '#c044ff', (flash ? 0.78 : 0.46) * env, cx - sz, cy - sz, sz * 2, 1);
      px(cr, '#8828c8', 0.36 * env, cx - sz, cy + sz - 1, sz * 2, 1);
    }

    for (let s = 0; s < 8; s++) {
      const wa = t * 0.14 + (s * Math.PI) / 4;
      const wx = Math.round(394 + Math.cos(wa) * 23);
      const wy = Math.round(282 + Math.sin(wa) * 23);
      px(cr, s % 2 === 0 ? '#ffe878' : '#ffffff', 0.75 * env, wx, wy, 2, 2);
    }
    px(cr, '#c848ff', 0.42 * kPulse * env, 387, 308, 5, 3);
  }

  function pintaNarutoKonoha(cr, t, nf) {
    const env = 0.60 + 0.40 * nf;
    const flagBob = Math.round(Math.sin(t * 0.35) * 1.2);
    px(cr, '#d84030', 0.85, 220, 224 + flagBob, 5, 2);
    px(cr, '#f8e8c8', 0.65 * env, 217, 228, 3, 1);

    const sway = Math.round(Math.sin(t * 0.22) * 1.1);
    for (const lx of [46, 66, 88]) {
      px(cr, '#ff5232', 0.75 * env, lx + sway, 255, 3, 4);
      px(cr, '#ffe8a0', 0.50 * env, lx + sway, 256, 1, 2);
    }
    for (let v = 0; v < 4; v++) {
      const vr = ((t * 1.1 + v * 6) % 20);
      px(cr, '#f0f4f8', Math.max(0.08, (1 - vr / 20) * 0.42), 66 + Math.round(Math.sin(t * 0.2 + v) * 2), 248 - Math.round(vr), 2, 2);
    }

    const cloakW = Math.round(Math.sin(t * 0.30) * 1.4);
    px(cr, '#ff7828', 0.82, 338 + cloakW, 265, 3, 4);
    px(cr, '#fff4e4', 0.78, 344 + cloakW, 261, 3, 3);
    px(cr, '#383058', 0.80, 372 - cloakW, 263, 3, 5);
    if (nf > 0.3) px(cr, '#c870ff', 0.70 * env, 368, 256, 1, 1);

    for (let i = 0; i < 7; i++) {
      const lx = 36 + ((Math.round(t * (1.3 + (i % 3) * 0.45)) + i * 59) % 404);
      const ly = 135 + (i % 4) * 32 + Math.round(Math.sin(t * 0.18 + i * 1.4) * 7);
      const lCol = nf > 0.55 ? '#4ca868' : (i % 2 === 0 ? '#74d05c' : '#e89844');
      px(cr, lCol, 0.72, lx, ly, 2, 2);
    }

    const ti = t | 0;
    for (let r = 0; r < 10; r++) {
      if ((ti + r) % 3 === 0) continue;
      const rx = 44 + ((r * 39 + t * 2) % 390);
      const ry = 287 + (r % 5) * 9;
      px(cr, nf > 0.55 ? '#98c8ff' : '#fff0b8', 0.42 * env, rx, ry, 4 + (r % 3) * 2, 1);
    }
  }

  function pintaNarutoValle(cr, t, nf) {
    const ti = t | 0;
    const env = 0.65 + 0.35 * nf;

    for (let l = 0; l < 6; l++) {
      const wx = 250 + l * 13;
      const off = (t * 4 + l * 21) % 120;
      for (let k = 0; k < 3; k++) {
        const wy = 154 + ((off + k * 42) % 120);
        px(cr, k === 0 ? '#ffffff' : '#b8eeff', 0.62 * env, wx, wy, 2, 6);
      }
    }
    for (let m = 0; m < 8; m++) {
      const mx = 242 + m * 11 + Math.round(Math.sin(t * 0.25 + m) * 2);
      const my = 275 + ((ti + m * 3) % 5);
      px(cr, '#e8fbff', 0.52 * env, mx, my, 5, 3);
    }

    const clash = 0.6 + 0.4 * Math.sin(t * 0.6);
    px(cr, '#48c4ff', 0.32 * clash, 271, 242, 12, 12);
    px(cr, '#d8f8ff', 0.90, 275, 246, 5, 5);
    for (let s = 0; s < 4; s++) {
      const sa = t * 0.65 + s * (Math.PI / 2);
      px(cr, '#80e4ff', 0.92, 277 + Math.round(Math.cos(sa) * 4), 248 + Math.round(Math.sin(sa) * 4), 2, 2);
    }

    px(cr, '#a8d4ff', 0.32 * clash, 285, 241, 14, 14);
    for (let b = 0; b < 5; b++) {
      if ((ti + b) % 3 === 0) continue;
      const ba = t * 0.48 + b * 1.25;
      const bl = 5 + ((ti * 2 + b * 3) % 8);
      for (let d = 2; d <= bl; d += 2) {
        const j = Math.round(Math.sin(d + t + b) * 1.4);
        px(cr, b % 2 === 0 ? '#ffffff' : '#b8b0ff', 0.92, 291 + Math.round(Math.cos(ba) * d) + j, 248 + Math.round(Math.sin(ba) * d), 1, 1);
      }
    }

    px(cr, '#ffffff', 0.96 * clash, 282, 246, 5, 5);
    const ringR = 5 + ((t * 2) % 20);
    const ringAl = Math.max(0.08, (1 - (ringR - 5) / 20) * 0.72);
    for (let a = 0; a < 12; a++) {
      const ang = (a * Math.PI * 2) / 12 + t * 0.1;
      px(cr, a % 2 === 0 ? '#88e8ff' : '#ffffff', ringAl, 284 + Math.round(Math.cos(ang) * ringR), 248 + Math.round(Math.sin(ang) * ringR * 0.8), 2, 2);
    }

    px(cr, '#ff9838', 0.65 * clash, 253, 255 - (ti % 3), 2, 3);
    px(cr, '#9880ff', 0.65 * clash, 314, 255 - ((ti + 1) % 3), 2, 3);

    const poolW = 10 + ((t * 2) % 18);
    px(cr, '#90e8ff', 0.40 * clash, 284 - poolW, 315, poolW * 2, 2);
    px(cr, '#ffffff', 0.55 * clash, 279, 316, 10, 1);
  }

  function pintaJujutsu(cr, t, nf, aE) {
    const ti = t | 0;
    const aBoost = aE * 0.35;
    const al = Math.min(1, 0.55 + 0.45 * nf + aBoost);
    const pulse = 0.72 + 0.28 * Math.sin(t * 0.14);

    for (let a = 0; a < 10; a++) {
      const ang = (a * Math.PI * 2) / 10 + t * 0.06;
      const rX = 36 + Math.round(Math.sin(t * 0.1 + a) * 2);
      px(cr, a % 2 === 0 ? '#7dd3fc' : '#c084fc', 0.68 * al, 446 + Math.round(Math.cos(ang) * rX), 146 + Math.round(Math.sin(ang) * 12), 2, 1);
    }
    px(cr, '#ffffff', 0.42 * al * pulse, 444, 145, 4, 2);

    const eyeAl = Math.min(1, (0.55 + 0.45 * Math.sin(t * 0.16)) * al);
    px(cr, '#fb7185', 0.88 * eyeAl, 125, 189, 2, 2);
    px(cr, '#fb7185', 0.88 * eyeAl, 139, 189, 2, 2);
    px(cr, '#ff2848', 0.55 * al, 120, 232 + (ti % 3 === 0 ? -1 : 0), 24, 2);
    for (let s = 0; s < 5; s++) {
      const sy = 188 + ((s * 17 + t * 3) % 68);
      const sx = 98 + ((s * 29) % 68);
      px(cr, s % 2 === 0 ? '#ff4468' : '#fda4af', 0.72 * al, sx, sy, 5, 1);
    }

    px(cr, '#fb7185', 0.60 * al, 214, 314 - (ti % 3), 2, 4);
    px(cr, '#ef4444', 0.60 * al, 224, 318 - ((ti + 1) % 3), 2, 4);
    for (let k = 0; k < 4; k++) {
      const prog = ((t * 3 + k * 7) % 36);
      const sx0 = 242 + prog;
      const sy0 = 294 + ((k * 7) % 18) - Math.round(prog * 0.18);
      for (let d = 0; d < 7; d++) {
        px(cr, d > 4 ? '#ffffff' : '#ff3355', 0.88 * al, sx0 + d, sy0 + (k % 2 === 0 ? d >> 1 : -(d >> 1)), 1, 1);
      }
    }

    px(cr, '#38bdf8', 0.68 * al, 396, 316 - ((ti + 2) % 3), 2, 4);
    const rOrb = 10 + Math.round(Math.sin(t * 0.2) * 2);
    const rAng = t * 0.22;
    px(cr, '#fb7185', 0.90 * al, 306 + Math.round(Math.cos(rAng) * rOrb), 298 + Math.round(Math.sin(rAng) * rOrb * 0.6), 3, 3);
    px(cr, '#38bdf8', 0.90 * al, 306 - Math.round(Math.cos(rAng) * rOrb), 298 - Math.round(Math.sin(rAng) * rOrb * 0.6), 3, 3);

    const coreR = Math.round(4 + 3 * pulse + aBoost * 8);
    px(cr, '#9333ea', 0.40 * al, 306 - coreR - 4, 298 - coreR - 2, coreR * 2 + 8, coreR * 2 + 4);
    px(cr, '#e879f9', 0.72 * al, 306 - coreR, 298 - coreR, coreR * 2, coreR * 2);
    px(cr, '#fdf4ff', 0.96 * al, 304, 296, 5, 5);

    const wave = 8 + ((t * 2) % 24);
    const wAl = Math.max(0.08, (1 - (wave - 8) / 24) * 0.75 * al);
    for (let a = 0; a < 12; a++) {
      const ang = (a * Math.PI * 2) / 12 + t * 0.08;
      px(cr, a % 2 === 0 ? '#e879f9' : '#7dd3fc', wAl, 306 + Math.round(Math.cos(ang) * wave), 298 + Math.round(Math.sin(ang) * wave * 0.7), 2, 2);
    }
    const rw = 12 + Math.round(4 * pulse);
    px(cr, '#c084fc', 0.42 * al, 306 - rw, 342, rw * 2, 2);
  }

  function pintaJujutsuSec(cr, t, nf, aE) {
    const ti = t | 0;
    const al = Math.min(1, 0.58 + 0.42 * nf + aE * 0.35);
    const bob = Math.round(Math.sin(t * 0.12) * 2);

    px(cr, '#eab308', 0.45 * al, 306, 274 + bob, 16, 16);
    if (ti % 29 !== 0) {
      px(cr, '#fff8e8', 0.92 * al, 312, 280 + bob, 4, 4);
      px(cr, '#e11d48', 0.95 * al, 313, 281 + bob, 2, 2);
    }
    for (let c = 0; c < 4; c++) {
      const ang = c * Math.PI * 0.5 + t * 0.07;
      px(cr, '#facc15', 0.78 * al, 314 + Math.round(Math.cos(ang) * 14), 282 + bob + Math.round(Math.sin(ang) * 11), 2, 2);
    }

    const bfPulse = (ti % 16) < 4;
    px(cr, '#09090b', 0.90, 184, 320, 7, 7);
    px(cr, bfPulse ? '#ffffff' : '#fb7185', 0.92 * al, 186, 322, 3, 3);
    for (let b = 0; b < 6; b++) {
      const ang = t * 0.45 + b * 1.05;
      const dist = 5 + ((t * 2 + b * 3) % 10);
      px(cr, b % 2 === 0 ? '#e11d48' : '#111827', 0.88, 187 + Math.round(Math.cos(ang) * dist), 323 + Math.round(Math.sin(ang) * dist), 2, 1);
    }

    for (let s = 0; s < 5; s++) {
      const sy = 342 - ((t * 2 + s * 6) % 24);
      const sx = 398 + Math.round(Math.sin(t * 0.1 + s) * 8) + (s - 2) * 4;
      px(cr, s % 2 === 0 ? '#38bdf8' : '#1e293b', 0.72 * al, sx, sy, 2, 2);
    }
    px(cr, '#38bdf8', 0.90 * al, 446, 314, 2, 1);
    if ((ti % 14) < 3) px(cr, '#bae6fd', 0.86 * al, 388 + (ti % 5), 202, 2, 14);
  }

  function pintaJujutsuBloq(cr, t, nf, aE) {
    const ti = t | 0;
    const al = Math.min(1, 0.58 + 0.42 * nf + aE * 0.35);
    const sway = Math.round(Math.sin(t * 0.09) * 1.5);

    for (const ox of [284, 298, 312, 328, 342, 356]) {
      px(cr, '#fef3c7', 0.88 * al, ox + sway, 162, 2, 5);
      px(cr, '#ef4444', 0.78 * al, ox + sway, 164, 1, 2);
    }
    const pulse = 0.65 + 0.35 * Math.sin(t * 0.14);
    px(cr, '#e11d48', 0.38 * al * pulse, 313, 283, 14, 14);
    px(cr, '#fb7185', 0.88 * al * pulse, 318, 287 + (ti % 6 < 3 ? 0 : -1), 4, 7);
    px(cr, '#fef2f2', 0.88 * al, 319, 288, 2, 2);

    for (let w = 0; w < 6; w++) {
      const prog = (t * 1.2 + w * 9) % 42;
      const wx = 290 + w * 12 + Math.round(Math.sin(t * 0.08 + w) * 3);
      const wy = 306 - Math.round(prog);
      px(cr, w % 2 === 0 ? '#a855f7' : '#f43f5e', Math.max(0.15, (1 - prog / 42) * 0.80 * al), wx, wy, 2, 2);
    }
    for (const [fx, fy] of [[228, 236], [412, 236], [182, 310], [458, 310]]) {
      px(cr, '#fef08a', 0.65 * al * (0.7 + 0.3 * Math.sin(t * 0.2 + fx)), fx - 1, fy - 1, 3, 3);
    }
  }

  function pintaAotRumbling(cr, t, nf, aE) {
    const ti = t | 0;
    const al = Math.min(1, 0.58 + 0.42 * nf + aE * 0.35);
    const pulse = 0.70 + 0.30 * Math.sin(t * 0.14);

    px(cr, '#4ade80', 0.92 * al * pulse, 289, 134, 2, 2);
    px(cr, '#4ade80', 0.92 * al * pulse, 297, 134, 2, 2);
    for (let i = 0; i < 6; i++) {
      const tx = [48, 124, 218, 376, 450, 174][i];
      const py = 248 - ((t * 2 + i * 11) % 52);
      const pxX = tx + Math.round(Math.sin(t * 0.08 + i) * 6);
      px(cr, i % 2 === 0 ? '#fb923c' : '#cbd5e1', 0.55 * al, pxX, py, 3, 2);
    }
    for (let a = 0; a < 8; a++) {
      const ang = (a * Math.PI * 2) / 8 + t * 0.42;
      px(cr, a % 2 === 0 ? '#f8fafc' : '#38bdf8', 0.85 * al, 392 + Math.round(Math.cos(ang) * 18), 322 + Math.round(Math.sin(ang) * 14), 3, 2);
    }
    px(cr, '#ef4444', 0.85 * al, 206 + (ti % 3) - 1, 315, 6, 2);
  }

  function pintaAotShiganshina(cr, t, nf, aE) {
    const ti = t | 0;
    const al = Math.min(1, 0.60 + 0.40 * nf + aE * 0.35);
    const pulse = 0.65 + 0.35 * Math.sin(t * 0.18);

    px(cr, '#fef08a', 0.92 * al * pulse, 190, 116, 3, 2);
    px(cr, '#fef08a', 0.92 * al * pulse, 212, 116, 3, 2);
    if ((ti % 18) < 5) {
      for (let k = 0; k < 8; k++) {
        px(cr, k % 2 === 0 ? '#fef08a' : '#f97316', 0.88 * al, 200 + Math.round(Math.sin(t + k) * 6), 24 + k * 9, 2, 7);
      }
    }
    for (let s = 0; s < 5; s++) {
      const sy = 194 - ((t + s * 9) % 34);
      px(cr, '#e2e8f0', 0.40 * al, 148 + s * 28 + Math.round(Math.sin(t * 0.06 + s) * 4), sy, 6, 3);
    }
    px(cr, '#ef4444', 0.80 * al, 320 + Math.round(Math.sin(t * 0.2) * 3), 270 - (ti % 8), 2, 4);
  }

  function pintaAotPaths(cr, t, nf, aE) {
    const al = Math.min(1, 0.60 + 0.40 * nf + aE * 0.35);
    const pulse = 0.70 + 0.30 * Math.sin(t * 0.11);

    px(cr, '#e0f2fe', 0.45 * al * pulse, 316, 134, 8, 120);
    for (let i = 0; i < 8; i++) {
      const gy = 250 - ((t * 2 + i * 16) % 140);
      const gx = 320 + Math.round(Math.sin(t * 0.09 + i * 1.3) * (gy < 140 ? 38 : 7));
      px(cr, i % 2 === 0 ? '#fde047' : '#67e8f9', 0.82 * al, gx, gy, 2, 2);
    }
    px(cr, '#f8fafc', 0.72 * al * pulse, 319, 312, 2, 6);
  }

  function pintaOpGear5(cr, t, nf, aE) {
    const aBoost = aE * 0.35;
    const al = Math.min(1, 0.60 + 0.40 * nf + aBoost);
    const pulse = 0.68 + 0.32 * Math.sin(t * 0.16);

    for (let h = 0; h < 6; h++) {
      const ang = t * 0.32 + h * 1.04;
      const dist = 8 + ((t * 2 + h * 4) % 16);
      px(cr, h % 2 === 0 ? '#f43f5e' : '#09090b', 0.90 * al, 212 + Math.round(Math.cos(ang) * dist), 322 + Math.round(Math.sin(ang) * dist), 2, 2);
    }
    const r = Math.round(5 + 3 * pulse + aBoost * 8);
    px(cr, '#fb923c', 0.65 * al, 308 - r, 276 - r, r * 2, r * 2);
    px(cr, '#ffffff', 0.94 * al, 306, 274, 4, 4);
    px(cr, '#fef08a', 0.90 * al * pulse, 352, 199, 2, 2);
    for (let f = 0; f < 5; f++) {
      const u = ((t * 0.12 + f * 0.2) % 1.0);
      px(cr, u < 0.5 ? '#ef4444' : '#fde047', 0.88 * al, Math.round(338 - u * 30), Math.round(214 + u * 62), 3, 3);
    }
  }

  function pintaOpSunny(cr, t, nf, aE) {
    const al = Math.min(1, 0.55 + 0.45 * nf + aE * 0.30);
    const bob = Math.round(Math.sin(t * 0.08));

    for (const lx of [276, 332]) px(cr, '#fef08a', 0.78 * al, lx - 1, 233 + bob, 3, 3);
    px(cr, '#4ade80', 0.85 * al, 291, 215 + bob, 3, 3);
    px(cr, '#38bdf8', 0.85 * al, 313, 215 + bob, 3, 3);
    px(cr, '#e0f2fe', 0.50 * al, 256 + ((t * 2) % 92), 282, 12, 1);
  }

  function pintaOpPoneglyph(cr, t, nf, aE) {
    const ti = t | 0;
    const al = Math.min(1, 0.58 + 0.42 * nf + aE * 0.35);

    for (let g = 0; g < 6; g++) {
      const idx = (ti + g * 5) % 24;
      px(cr, '#fde047', 0.85 * al, 180 + (idx % 5) * 7, 248 + Math.floor(idx / 5) * 14, 2, 2);
    }
    for (let m = 0; m < 4; m++) {
      const ang = t * 0.16 + m * 1.57;
      px(cr, '#e879f9', 0.82 * al, 404 + Math.round(Math.cos(ang) * 13), 318 + Math.round(Math.sin(ang) * 9), 2, 2);
    }
  }

  function pintaDbzUi(cr, t, nf, aE) {
    const aBoost = aE * 0.35;
    const al = Math.min(1, 0.62 + 0.38 * nf + aBoost);
    const pulse = 0.70 + 0.30 * Math.sin(t * 0.2);

    for (let u = 0; u < 6; u++) {
      const uy = 344 - ((t * 2 + u * 7) % 36);
      const ux = 202 + Math.round(Math.sin(t * 0.25 + u) * 14);
      px(cr, u % 2 === 0 ? '#e0f2fe' : '#38bdf8', 0.85 * al, ux, uy, 2, 3);
    }
    px(cr, '#38bdf8', 0.78 * al * pulse, 232 + (t % 12) * 5, 315 - (t % 12) * 1.4, 8, 3);
    const sr = Math.round(5 + 3 * pulse + aBoost * 6);
    px(cr, '#f97316', 0.65 * al, 386 - sr, 296 - sr, sr * 2, sr * 2);
    px(cr, '#fef08a', 0.92 * al * pulse, 302, 296, 5, 5);
  }

  function pintaDbzNamek(cr, t, nf, aE) {
    const al = Math.min(1, 0.58 + 0.42 * nf + aE * 0.35);
    const activeIdx = Math.floor(t / 4) % 7;

    for (let b = 0; b < 7; b++) {
      px(cr, b === activeIdx ? '#ffffff' : '#fde047', (b === activeIdx ? 0.95 : 0.55) * al, 240 + b * 16 - 1, 274, 3, 3);
    }
    px(cr, '#ef4444', 0.90 * al, 282, 120, 2, 2);
    for (let k = 0; k < 5; k++) {
      const ky = 250 - ((t * 3 + k * 24) % 160);
      px(cr, '#fde047', 0.72 * al, 278 + Math.round(Math.sin(t * 0.1 + k) * 18), ky, 2, 5);
    }
  }

  function pintaDbzKame(cr, t, nf, aE) {
    const al = Math.min(1, 0.55 + 0.45 * nf + aE * 0.30);

    px(cr, '#fef3c7', 0.78 * al, 185, 213, 4, 4);
    const rGlow = 0.6 + 0.4 * Math.sin(t * 0.14);
    px(cr, '#fde047', 0.85 * al * rGlow, 421, 255, 3, 3);
    const sy = 176 - (t % 20);
    px(cr, '#fce7f3', Math.max(0.15, (1 - (t % 20) / 20) * 0.50), 206 + Math.round(Math.sin(t * 0.2) * 3), sy, 3, 2);
    px(cr, '#fde68a', 0.65 * al, 234 + (t % 16), 130, 2, 2);
  }

  function pintaCyberSandevistan(cr, t, nf, aE) {
    const ti = t | 0;
    const al = Math.min(1, 0.60 + 0.40 * nf + aE * 0.35);
    const cols = ['#4ade80', '#22d3ee', '#f43f5e'];

    for (let s = 0; s < 3; s++) {
      px(cr, cols[s], 0.52 * al, 178 + s * 16 - ((ti + s) % 3), 314, 10, 14);
    }
    px(cr, '#22d3ee', 0.90 * al, 227, 316 + (ti % 4), 2, 6);
    const mU = ((t * 3) % 40) / 40;
    px(cr, '#fde047', 0.92 * al, Math.round(370 - mU * 82), Math.round(328 - Math.sin(mU * Math.PI * 1.35) * 26), 3, 2);
    px(cr, '#ef4444', 0.80 * al * (0.7 + 0.3 * Math.sin(t * 0.25)), 40, 319, 6, 2);
    px(cr, '#38bdf8', 0.82 * al, (92 + (t * 2)) % 460, 116, 4, 2);
  }

  function pintaCyberMoon(cr, t, nf, aE) {
    const ti = t | 0;
    const al = Math.min(1, 0.58 + 0.42 * nf + aE * 0.30);

    px(cr, '#38bdf8', 0.85 * al, ((96 + t * 2) % 440), 221, 18, 3);
    for (const bx of [42, 148, 240, 396]) {
      px(cr, (ti + bx) % 16 < 8 ? '#38bdf8' : '#f472b6', 0.88 * al, bx, 259, 2, 2);
    }
    for (let p = 0; p < 4; p++) {
      const gy = 290 - ((t + p * 8) % 30);
      px(cr, '#bae6fd', 0.72 * al, 300 + p * 10 + Math.round(Math.sin(t * 0.1 + p) * 4), gy, 2, 2);
    }
  }

  function pintaCyberBloq(cr, t, nf, aE) {
    const ti = t | 0;
    const al = Math.min(1, 0.60 + 0.40 * nf + aE * 0.35);

    const activeSeg = Math.floor(t / 2) % 7;
    for (let s = 0; s < 7; s++) {
      px(cr, s === activeSeg ? '#ffffff' : (s % 2 === 0 ? '#22d3ee' : '#4ade80'), (s === activeSeg ? 0.96 : 0.68) * al, 286 + s * 11 - 1, 315, 3, 5);
    }
    if ((ti % 19) !== 0) px(cr, '#f43f5e', 0.78 * al, 96, 166, 72, 1);
    px(cr, '#4ade80', 0.60 * al * (0.6 + 0.4 * Math.sin(t * 0.15)), 316, 194, 8, 8);
  }

  function pintaMichiTerraza(cr, t, nf, aE) {
    const ti = t | 0;
    const al = Math.min(1, 0.62 + 0.38 * nf + aE * 0.30);
    // Parpadeo periodico del Michi Gris (ojos en 344,260 y 352,264)
    if ((ti % 38) >= 35) {
      px(cr, '#6e7181', 0.96, 344, 260, 5, 5);
      px(cr, '#6e7181', 0.96, 352, 264, 5, 5);
      px(cr, '#14171d', 0.95, 344, 262, 5, 1);
      px(cr, '#14171d', 0.95, 352, 266, 5, 1);
    } else if (nf > 0.35) {
      px(cr, '#fef08a', 0.55 * al, 345, 262, 1, 1);
      px(cr, '#fef08a', 0.55 * al, 353, 266, 1, 1);
    }
    // Destello en la pelotita multicolor y motitas de luz
    if ((ti % 16) < 4) px(cr, '#ffffff', 0.85, 122, 296, 2, 2);
    for (let i = 0; i < 6; i++) {
      const fx = (110 + i * 62 + Math.round(Math.sin(t * 0.08 + i * 1.4) * 14));
      const fy = 248 + ((i * 11) % 34) + Math.round(Math.cos(t * 0.11 + i) * 7);
      px(cr, nf > 0.35 ? '#fde047' : (i % 2 === 0 ? '#fef08a' : '#a3e635'), (0.45 + 0.45 * Math.abs(Math.sin(t * 0.2 + i))) * al, fx, fy, 2, 2);
    }
  }

  function pintaMichiRascador(cr, t, nf, aE) {
    const ti = t | 0;
    const al = Math.min(1, 0.62 + 0.38 * nf + aE * 0.30);
    // Pompon colgando balanceandose
    const sw = Math.round(Math.sin(t * 0.16) * 3);
    px(cr, '#fef08a', 0.90, 259 + sw, 232, 6, 6);
    // Parpadeo del Michi Gris arriba en el rascador (168,111 y 180,111)
    if ((ti % 42) >= 39) {
      px(cr, '#6e7181', 0.96, 168, 111, 7, 5);
      px(cr, '#6e7181', 0.96, 180, 111, 7, 5);
      px(cr, '#14171d', 0.95, 168, 113, 7, 1);
      px(cr, '#14171d', 0.95, 180, 113, 7, 1);
    }
    for (let i = 0; i < 6; i++) {
      const fx = 90 + i * 64 + Math.round(Math.sin(t * 0.09 + i) * 12);
      const fy = 244 + ((i * 13) % 36) + Math.round(Math.cos(t * 0.1 + i) * 6);
      px(cr, nf > 0.35 ? '#fef08a' : '#86efac', (0.5 + 0.45 * Math.sin(t * 0.2 + i)) * al, fx, fy, 2, 2);
    }
  }

  function pintaMichiBloqueo(cr, t, nf, aE) {
    const al = Math.min(1, 0.60 + 0.40 * nf + aE * 0.30);
    const pulse = 0.65 + 0.35 * Math.sin(t * 0.16);
    // Brillo del farol calido y de las huellitas runicas alrededor del cojin
    px(cr, '#fef08a', 0.85 * al * pulse, 172, 320, 9, 12);
    for (const [hx, hy] of [[280, 328], [360, 328], [320, 344]]) {
      px(cr, '#fef9c3', 0.82 * al * pulse, hx - 1, hy - 1, 3, 3);
    }
    for (let i = 0; i < 5; i++) {
      const fx = 210 + i * 54 + Math.round(Math.sin(t * 0.08 + i) * 10);
      const fy = 264 + ((i * 9) % 24) + Math.round(Math.cos(t * 0.12 + i) * 5);
      px(cr, '#fde047', 0.72 * al, fx, fy, 2, 2);
    }
  }

  function pintaSalonBreakingBad(cr, t, nf, aE) {
    const ti = t | 0;
    const al = Math.min(1, 0.62 + 0.38 * nf + aE * 0.30);
    // Brillo sutil de la TV de Breaking Bad + LEDs del router
    const tvPulse = 0.55 + 0.45 * Math.sin(t * 0.18);
    px(cr, '#4ade80', 0.16 * al * tvPulse, 246, 72, 204, 118);
    if ((ti % 10) < 5) px(cr, '#86efac', 0.90, 532 + ((ti % 4) * 8), 374, 2, 1);
    // Parpadeo de Maggie (418,265 y 436,274) y de Noah (115,235 y 132,236)
    if ((ti % 40) >= 37) {
      px(cr, '#484e5a', 0.96, 418, 265, 7, 6);
      px(cr, '#484e5a', 0.96, 436, 274, 6, 4);
      px(cr, '#14171d', 0.95, 418, 268, 7, 1);
      px(cr, '#14171d', 0.95, 436, 276, 6, 1);
    }
    if ((ti % 54) >= 51) {
      px(cr, '#bfa99b', 0.96, 115, 235, 5, 3);
      px(cr, '#bfa99b', 0.96, 132, 236, 5, 3);
      px(cr, '#14171d', 0.95, 115, 236, 5, 1);
      px(cr, '#14171d', 0.95, 132, 237, 5, 1);
    }
  }

  function pintaSalonMiro(cr, t, nf, aE) {
    const ti = t | 0;
    const al = Math.min(1, 0.62 + 0.38 * nf + aE * 0.30);
    // Pulso calido de la lampara de pinza sobre el cuadro Miro
    const pulse = 0.70 + 0.30 * Math.sin(t * 0.15);
    if (nf > 0.25) px(cr, '#fef08a', 0.55 * al * pulse, 286, 79, 8, 6);
    // Parpadeo de Maggie (334,205 y 349,205) y parpadeo lento de Noah (204,211 y 220,211)
    if ((ti % 36) >= 33) {
      px(cr, '#484e5a', 0.96, 334, 205, 6, 4);
      px(cr, '#484e5a', 0.96, 349, 205, 6, 4);
      px(cr, '#14171d', 0.95, 334, 207, 6, 1);
      px(cr, '#14171d', 0.95, 349, 207, 6, 1);
    }
    if ((ti % 60) >= 55) {
      px(cr, '#b7a396', 0.96, 204, 211, 5, 2);
      px(cr, '#b7a396', 0.96, 220, 211, 5, 2);
      px(cr, '#14171d', 0.95, 204, 212, 5, 1);
      px(cr, '#14171d', 0.95, 220, 212, 5, 1);
    }
  }

  function pintaSalonSiesta(cr, t, nf, aE) {
    const al = Math.min(1, 0.60 + 0.40 * nf + aE * 0.30);
    for (let i = 0; i < 6; i++) {
      const fx = 60 + i * 74 + Math.round(Math.sin(t * 0.08 + i) * 10);
      const fy = 172 + ((i * 11) % 36) + Math.round(Math.cos(t * 0.1 + i) * 6);
      px(cr, '#fde047', (0.45 + 0.45 * Math.abs(Math.sin(t * 0.2 + i))) * al, fx, fy, 2, 2);
    }
  }

  const HEROES = {
    miles_morales: (cr, t, nf) => { pintaFerry(cr, t, nf); pintaMiles(cr, t, nf); },
    miles_colgado: (cr, t, nf) => { pintaFerry(cr, t, nf); pintaMilesColgado(cr, t, nf); },
    stranger_azotamentes: pintaStrangerPrincipal,
    stranger_demogorgon: pintaStrangerDemogorgon,
    stranger_reloj: pintaStrangerReloj,
    demon_rengoku: pintaDemonRengoku,
    demon_tokito: pintaDemonTokito,
    demon_glicinias: pintaDemonGlicinias,
    naruto_baryon: pintaNarutoBaryon,
    naruto_konoha: pintaNarutoKonoha,
    naruto_valle: pintaNarutoValle,
    jujutsu: pintaJujutsu,
    jujutsu_sec: pintaJujutsuSec,
    jujutsu_bloq: pintaJujutsuBloq,
    aot_rumbling: pintaAotRumbling,
    aot_shiganshina: pintaAotShiganshina,
    aot_paths: pintaAotPaths,
    op_gear5: pintaOpGear5,
    op_sunny: pintaOpSunny,
    op_poneglyph: pintaOpPoneglyph,
    dbz_ui: pintaDbzUi,
    dbz_namek: pintaDbzNamek,
    dbz_kame: pintaDbzKame,
    cyber_sandevistan: pintaCyberSandevistan,
    cyber_moon: pintaCyberMoon,
    cyber_bloq: pintaCyberBloq,
    michi_terraza: pintaMichiTerraza,
    michi_rascador: pintaMichiRascador,
    michi_bloqueo: pintaMichiBloqueo,
    salon_breaking_bad: pintaSalonBreakingBad,
    salon_miro: pintaSalonMiro,
    salon_siesta: pintaSalonSiesta,
  };

  function pintaHeroeAtras(cr, modo, t, nf) {
    if (modo && modo.startsWith('stranger_')) pintaTormentaStranger(cr, t, nf, modo);
  }

  function pintaHeroe(cr, modo, t, nf, audioEnergy = 0) {
    const fn = modo && HEROES[modo];
    if (fn) fn(cr, t, nf, audioEnergy);
  }

  return { ALAS_GRULLA, ALAS_WYVERN, MOTAS_MANA, pintaHeroeAtras, pintaHeroe };
}

if (typeof globalThis !== 'undefined') globalThis.createPixelZenHeroes = createPixelZenHeroes;
if (typeof window !== 'undefined') window.createPixelZenHeroes = createPixelZenHeroes;
