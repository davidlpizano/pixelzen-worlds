#!/usr/bin/env python3
"""Detalles arquitectonicos, ambientales y de lore para las 30 escenas de PixelZen Worlds."""
import math
import os
import random
import sys

from pz_lib import HOR, W, H, dith, en_zona, mix


class _Ctx:
    """Contexto extraido del script de escena activo (__main__)."""

    def __init__(self, lz, hor=HOR):
        main = sys.modules.get('__main__')
        path = os.path.normpath(getattr(main, '__file__', '') or '')
        parts = path.replace('\\', '/').lower().split('/')
        self.tema = ''
        self.modo = ''
        if 'escenas' in parts:
            idx = len(parts) - 1 - parts[::-1].index('escenas')
            if idx + 2 < len(parts):
                self.tema = parts[idx + 1]
                sub = parts[idx + 2]
                self.modo = 'principal' if sub == 'generar.py' else sub

        self.lz = lz
        self.main = main
        self.hor = hor
        self.w = lz.w
        self.h = lz.h
        self.fase = getattr(main, 'FASE', os.environ.get('PZ_FASE', 'noche'))
        self.anim = bool(getattr(main, 'ANIM', '--anim' in sys.argv))
        self.skym = getattr(main, 'SKYM', os.environ.get('PZ_SKY', 'normal'))
        self.pal = getattr(main, 'PAL', {}) or {}
        self.ventanas = getattr(main, 'VENTANAS', None)
        self.faroles = getattr(main, 'FAROLES', None)
        self.runas = getattr(main, 'RUNAS', None)
        self.destellos = getattr(main, 'DESTELLOS', None)

    def key(self):
        return (self.tema, self.modo)

    def put(self, x, y, col, check_hud=False):
        xi, yi = int(round(x)), int(round(y))
        if 0 <= xi < self.w and 0 <= yi < self.h:
            if check_hud and en_zona(xi, yi, 8):
                return
            self.lz.put(xi, yi, col)

    def over(self, x, y, col, alpha, check_hud=False):
        xi, yi = int(round(x)), int(round(y))
        if 0 <= xi < self.w and 0 <= yi < self.h:
            if check_hud and en_zona(xi, yi, 8):
                return
            self.lz.over(xi, yi, col, alpha)

    def disc(self, cx, cy, r, col, check_hud=False):
        cxi, cyi = int(round(cx)), int(round(cy))
        ri = int(r)
        for dy in range(-ri, ri + 1):
            for dx in range(-ri, ri + 1):
                if dx * dx + dy * dy <= ri * ri:
                    self.put(cxi + dx, cyi + dy, col, check_hud=check_hud)

    def glow(self, cx, cy, r, col, alpha=0.5, check_hud=True):
        if check_hud and en_zona(int(cx), int(cy), 8):
            return
        self.lz.glow(int(cx), int(cy), int(r), col, alpha)

    def col(self, clave, idx=0, default='#3c4258'):
        val = self.pal.get(clave)
        if val is None:
            return default
        if isinstance(val, dict):
            return next(iter(val.values()), default)
        if isinstance(val, (list, tuple)):
            return val[min(idx, len(val) - 1)] if val else default
        return val

    def warm(self):
        return '#ffe088' if self.fase == 'dorado' else ('#ffd270' if self.fase == 'noche' else '#98b4d0')


# --- Primitivas pixel art compartidas ---

def _line(ctx, x0, y0, x1, y1, col, alpha=1.0, check_hud=True):
    dx = x1 - x0
    dy = y1 - y0
    steps = max(1, int(max(abs(dx), abs(dy))))
    for i in range(steps + 1):
        u = i / float(steps)
        px = int(round(x0 + dx * u))
        py = int(round(y0 + dy * u))
        if alpha >= 0.99:
            ctx.put(px, py, col, check_hud=check_hud)
        else:
            ctx.over(px, py, col, alpha, check_hud=check_hud)


def _add_ventana(ctx, x, y, col_dim, col_lit='#ffd474', w=2, h=4):
    xi, yi = int(x), int(y)
    if en_zona(xi, yi, 8):
        return
    use_lit = (not ctx.anim) and ctx.fase != 'dia'
    fill = col_lit if use_lit else col_dim
    for dy in range(h):
        for dx in range(w):
            ctx.put(xi + dx, yi + dy, fill, check_hud=True)
    if ctx.anim and ctx.ventanas is not None:
        ctx.ventanas.append([xi, yi])
    elif use_lit:
        ctx.glow(xi, yi + h // 2, 4, col_lit, 0.34, check_hud=True)


def _add_farol(ctx, x, y, r, col_core='#fff4c4', col_halo='#ffa044'):
    xi, yi = int(x), int(y)
    if en_zona(xi, yi, 8):
        return
    ctx.put(xi, yi, col_core if ctx.fase != 'dia' else '#d8e4ec', check_hud=True)
    if ctx.anim and ctx.faroles is not None:
        ctx.faroles.append([xi, yi, int(r)])
    elif ctx.fase != 'dia':
        ctx.glow(xi, yi, int(r), col_halo, 0.50, check_hud=True)


def _add_runa(ctx, x, y, col_core, col_halo):
    xi, yi = int(x), int(y)
    if en_zona(xi, yi, 8):
        return
    ctx.put(xi, yi, col_core, check_hud=True)
    if ctx.anim and ctx.runas is not None:
        ctx.runas.append([xi, yi])
    else:
        ctx.glow(xi, yi, 4, col_halo, 0.45, check_hud=True)


def _stone_courses(ctx, x0, y0, x1, y1, col_hi, col_lo, step_x=10, step_y=6, seed=1):
    rng = random.Random(seed)
    for y in range(max(0, y0), min(ctx.h, y1), step_y):
        offset = (y // step_y % 2) * (step_x // 2)
        for x in range(max(0, x0), min(ctx.w, x1)):
            if en_zona(x, y, 8):
                continue
            if (x + offset) % step_x == 0 or rng.random() < 0.08:
                ctx.over(x, y, col_lo, 0.38)
            elif y + 1 < ctx.h and rng.random() < 0.14:
                ctx.over(x, y + 1, col_hi, 0.25)


def _banner(ctx, cx, y0, h, hw, col_main, col_trim):
    if en_zona(cx, y0, 8):
        return
    for dx in range(-hw - 1, hw + 2):
        ctx.put(cx + dx, y0, col_trim, check_hud=True)
    for dy in range(1, h):
        notch = max(0, dy - (h - hw - 1))
        for dx in range(-hw, hw + 1):
            if abs(dx) < notch:
                continue
            col = col_trim if abs(dx) == hw or (dy == h // 2 and abs(dx) <= 1) else col_main
            ctx.put(cx + dx, y0 + dy, col, check_hud=True)


def _tuft_band(ctx, x0, x1, y_base_fn, count, h_min, h_max, cols, seed):
    rng = random.Random(seed)
    for _ in range(count):
        bx = rng.randint(x0, x1)
        by = int(y_base_fn(bx)) if callable(y_base_fn) else int(y_base_fn)
        bh = rng.randint(h_min, h_max)
        lean = rng.uniform(-0.32, 0.32)
        c_stem = rng.choice(cols)
        for i in range(bh):
            px = int(round(bx + lean * i * 0.65))
            py = by - i
            if 0 <= px < ctx.w and 0 <= py < ctx.h and not en_zona(px, py, 8):
                ctx.put(px, py, c_stem if i < bh - 2 else cols[0])


def _rocks(ctx, specs, col_hi, col_mid, col_dk):
    for cx, cy, rx, ry in specs:
        for dy in range(-ry, ry + 1):
            for dx in range(-rx, rx + 1):
                if (dx / float(max(1, rx))) ** 2 + (dy / float(max(1, ry))) ** 2 <= 1.0:
                    if dy < -ry // 3 and dx < rx // 3:
                        c = col_hi
                    elif dx > rx // 3 or dy > ry // 2:
                        c = col_dk
                    else:
                        c = col_mid
                    ctx.put(cx + dx, cy + dy, c, check_hud=True)


def _flowers(ctx, pts, col_petal, col_stem, col_center='#fff2b4'):
    for fx, fy in pts:
        for k in range(1, 5):
            ctx.put(fx, fy + k, col_stem, check_hud=True)
        for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            ctx.put(fx + dx, fy + dy, col_petal, check_hud=True)
        ctx.put(fx, fy, col_center or col_petal, check_hud=True)


def _sparks(ctx, cx, cy, rx, ry, count, col_core, col_halo, seed, runa_stride=2):
    rng = random.Random(seed)
    for i in range(count):
        sx = int(round(cx + rng.uniform(-rx, rx)))
        sy = int(round(cy + rng.uniform(-ry, ry)))
        if not (0 <= sx < ctx.w and 0 <= sy < ctx.h) or en_zona(sx, sy, 8):
            continue
        if i % runa_stride == 0:
            _add_runa(ctx, sx, sy, col_core, col_halo)
        else:
            ctx.over(sx, sy, col_core, 0.72, check_hud=True)


def _birds(ctx, pts, col):
    for bx, by in pts:
        if en_zona(bx, by, 10):
            continue
        for dx, dy in ((-2, -1), (-1, 0), (0, 1), (1, 0), (2, -1)):
            ctx.put(bx + dx, by + dy, col, check_hud=True)


def _icicles(ctx, x0, x1, y_top, step, max_len, col_hi, col_sh, seed):
    rng = random.Random(seed)
    for x in range(x0, x1, step):
        if rng.random() < 0.35 or en_zona(x, y_top, 8):
            continue
        ln = rng.randint(2, max_len)
        for dy in range(ln):
            ctx.put(x, y_top + dy, col_hi if dy < ln - 1 else col_sh, check_hud=True)
            if ln >= 4 and dy == 0:
                ctx.put(x + 1, y_top, col_sh, check_hud=True)


def _railing(ctx, x0, x1, y_top, post_h, post_step, col_hi, col_dk):
    for x in range(max(0, x0), min(ctx.w, x1)):
        ctx.put(x, y_top, col_hi, check_hud=True)
        ctx.put(x, y_top + 1, col_dk, check_hud=True)
        if x % post_step == 0:
            for dy in range(1, post_h + 1):
                ctx.put(x, y_top + dy, col_dk, check_hud=True)


def _ground_cracks(ctx, cx, cy, branches, col_edge, col_core, check_hud=True):
    rng = random.Random(abs(cx * 31 + cy * 17))
    for ang, ln in branches:
        fx, fy = float(cx), float(cy)
        for i in range(ln):
            fx += math.cos(ang) * 1.1 + rng.uniform(-0.35, 0.35)
            fy += math.sin(ang) * 0.65 + rng.uniform(-0.2, 0.2)
            al = max(0.22, 1.0 - i / float(max(1, ln)))
            ctx.over(int(round(fx)), int(round(fy)), col_edge if i > 3 else col_core, al * 0.78, check_hud=check_hud)


# =====================================================================
# 1. DEMON SLAYER (principal, secundario, bloqueo)
# =====================================================================

def _ds_principal_post(ctx):
    tr_dk, tr_md, tr_hi, tr_r, tr_gl = ctx.pal['train']
    fl0, fl1, fl2, _ = ctx.pal['flame']
    ak0, ak1, ak2 = ctx.pal['akaza']
    g0, g1, g2, g3 = ctx.pal['ground']

    def rail_y(rx):
        return 254 + int((rx / 640.0) * 60 + 2.5 * math.sin(rx * 0.015))

    # Remaches, marcos dorados, carbon del tender, rejilla de caldera y haz frontal del Tren Infinito
    for vx0, vx1, tilt_v in ((0, 56, 0.02), (60, 128, 0.03)):
        for x in range(vx0 + 3, vx1 - 2, 8):
            top_v = 226 + int((x - vx0) * tilt_v)
            bot_v = rail_y(x) - 6
            ctx.put(x, top_v + 5, tr_hi)
            ctx.put(x, bot_v - 3, '#484c60')
            ctx.put(x + 1, top_v + 2, tr_dk)
        for x in range(vx0 + 4, vx1 - 3, 16):
            top_v = 226 + int((x - vx0) * tilt_v)
            for dx in range(-1, 8):
                ctx.put(x + dx, top_v + 11, tr_hi)
                ctx.put(x + dx, top_v + 24, tr_dk)

    for x in range(138, 160):
        drop = int((x - 132) * 0.06)
        ctx.put(x, 212 + drop - 1, '#101218' if (x % 3) else '#282c38')
    for x in range(166, 220):
        drop = int((x - 132) * 0.06)
        ctx.put(x, 222 + drop + 6, '#9098ae' if (x % 4 == 0) else '#586074')
    for rx in (176, 186, 196, 206):
        drop = int((rx - 132) * 0.06)
        for dy in range(3):
            ctx.put(rx, 222 + drop + 18 + dy, tr_r if dy == 1 else tr_gl)
    for k in range(1, 24):
        al = 0.26 * (1.0 - k / 24.0)
        for dy in range(-k // 6, k // 5 + 1):
            ctx.over(227 + k, 238 + dy + k // 5, tr_gl, al)

    _sparks(ctx, 182, 188, 32, 14, 14, fl2, fl0, seed=112)
    for x in range(12, 628, 7):
        ry = rail_y(x)
        if x % 14 == 0:
            ctx.over(x, ry, '#dce4f4', 0.55)
        ctx.put(x + 2, ry + 5, '#2c303e' if (x % 2) else '#1a1e28')

    # Hito y farol ferroviario junto a las vias izquierdas
    for dy in range(18):
        ctx.put(44, 294 - dy, '#2a1c14')
        ctx.put(45, 294 - dy, '#3c281c')
    for dx in range(-3, 4):
        ctx.put(44 + dx, 276, '#4c3424')
        ctx.put(44 + dx, 277, '#644430')
    _add_farol(ctx, 49, 281, 7, '#ffe69a', fl1)

    # Grietas ardientes del duelo + rocas + hierbas en bordes
    _ground_cracks(ctx, 304, 314, [(2.8, 16), (2.4, 12), (0.3, 14)], fl0, fl2)
    _ground_cracks(ctx, 488, 314, [(0.25, 16), (0.7, 13), (2.9, 12)], ak2, ak0)
    _sparks(ctx, 332, 292, 42, 20, 14, fl2, fl0, seed=113, runa_stride=2)
    _sparks(ctx, 456, 294, 38, 18, 12, ak1, ak0, seed=114, runa_stride=2)
    _rocks(ctx, [(18, 368, 8, 4), (78, 382, 10, 5), (558, 378, 11, 5), (618, 364, 9, 4)], g3, g1, g2)
    _tuft_band(ctx, 4, 142, lambda x: 396 - int(x * 0.08), 46, 8, 22, [g3, g1, g0], seed=115)
    _tuft_band(ctx, 504, 636, lambda x: 396 - int((636 - x) * 0.09), 48, 8, 24, [g3, g1, g0], seed=116)
    _birds(ctx, [(84, 72), (112, 82), (414, 54)], ctx.col('mont', 1))


def _ds_secundario_post(ctx):
    rk0, rk1, rk2, rk_hi = ctx.pal['rock']
    wd0, _, wd_hi = ctx.pal['wood']
    m0, m1 = ctx.pal['mist']

    # Caballete del tejado, celosias shoji y farolillo colgante del taller del herrero
    for x in range(62, 130):
        ctx.put(x, 183, rk_hi if x % 4 == 0 else rk1)
    for rx_e in (62, 130):
        ctx.put(rx_e, 181, rk_hi)
        ctx.put(rx_e, 182, rk2)
    for vx in (52, 78, 104, 130):
        for dy in range(223, 242, 6):
            for dx in range(10):
                ctx.over(vx + dx, dy, wd0, 0.55)
    _add_farol(ctx, 146, 214, 8, '#fff0b8', '#ff9840')

    # Yunque del herrero y soporte de katanas en el porche
    for dx in range(-4, 5):
        ctx.put(158 + dx, 248, rk_hi if abs(dx) < 3 else rk2)
    ctx.put(157, 249, rk2)
    ctx.put(158, 249, rk2)
    for k in range(8):
        ctx.put(151 + k // 2, 249 - k, '#dce4f4' if k > 3 else wd_hi)

    def path_y(x):
        return 252 + int(max(0, min(1, (x - 134) / 280.0)) * 58) + int(6 * math.sin((x - 134) * 0.015))

    rng = random.Random(212)
    for x in range(192, 608, 22):
        if 252 <= x <= 306 or 432 <= x <= 506:
            continue
        sy = path_y(x) + rng.randint(-4, 6)
        _rocks(ctx, [(x, sy, 4, 2)], rk_hi, rk0, rk2)

    for y in range(264, 286):
        hw = 4 if y > 282 else (3 if y < 269 else 2)
        for dx in range(-hw, hw + 1):
            ctx.put(572 + dx, y, rk_hi if dx < 0 else rk2)
    _add_farol(ctx, 572, 267, 9, '#fff0b8', '#ff9840')

    _flowers(ctx, [(26, 372), (52, 366), (86, 382), (558, 378), (598, 366), (620, 380)], '#e8344c', '#183424', '#ffd068')
    _tuft_band(ctx, 8, 128, 397, 38, 10, 26, [ctx.col('ground', 3), ctx.col('ground', 1)], seed=215)
    _tuft_band(ctx, 514, 632, 397, 38, 10, 26, [ctx.col('ground', 3), ctx.col('ground', 1)], seed=216)

    _sparks(ctx, 278, 282, 34, 18, 12, m0, m1, seed=218)
    _sparks(ctx, 468, 284, 38, 20, 12, '#7ef4d8', '#30a48c', seed=219)
    _sparks(ctx, 118, 166, 10, 8, 6, '#ffe49c', '#ff9438', seed=220, runa_stride=2)


def _ds_bloqueo_post(ctx):
    st0, st1, st2, _ = ctx.pal['stone']
    w0, w1, _, _ = ctx.pal['wist']
    _, _, tr_g = ctx.pal['torii']

    # Lajas de la terraza y escalinata central del santuario Torii
    _stone_courses(ctx, 40, 250, 600, 396, st2, st0, step_x=16, step_y=8, seed=301)
    for s_i in range(4):
        y_st = 282 - s_i * 5
        hw = 58 - s_i * 4
        for x in range(320 - hw, 320 + hw + 1):
            ctx.put(x, y_st, st2 if s_i % 2 == 0 else st1)
            ctx.put(x, y_st + 1, st0)

    # Cuerda sagrada shimenawa + shide en el dintel del Torii (x=258..383)
    for x in range(258, 383):
        sag = int(3 * math.sin((x - 258) / 124.0 * math.pi))
        ctx.put(x, 203 + sag, tr_g if (x % 4) else '#b8944c')
    for sx in (282, 306, 334, 358):
        for dy in range(6):
            dx_z = (dy % 2) * 2 - 1
            ctx.put(sx + dx_z, 206 + dy, '#f4f0e8')
            ctx.put(sx + dx_z + 1, 206 + dy, '#d4cee0')

    # Pares de estatuas Komainu vigilando la entrada
    for kx, flip in ((228, 1), (412, -1)):
        for dy in range(18):
            hw = 5 if dy > 11 else 3
            for dx in range(-hw, hw + 1):
                ctx.put(kx + dx, 270 + dy, st2 if dx * flip <= 0 else st0)
        ctx.put(kx + 2 * flip, 268, st2)
        ctx.put(kx - 2 * flip, 268, st2)

    ctx.put(310, 290, '#d8b058')
    ctx.put(330, 290, '#d8b058')
    _add_runa(ctx, 310, 288, w1, w0)
    _add_runa(ctx, 330, 288, w1, w0)

    rng = random.Random(305)
    for cx in list(range(28, 152, 16)) + list(range(494, 620, 16)):
        for dy in range(rng.randint(10, 24)):
            y = 148 + dy
            if en_zona(cx, y, 8):
                continue
            hw = max(1, 3 - dy // 7)
            for dx in range(-hw, hw + 1):
                ctx.put(cx + dx, y, w1 if dx <= 0 else w0, check_hud=True)
    _sparks(ctx, 320, 344, 210, 44, 28, w1, w0, seed=308, runa_stride=2)


# =====================================================================
# 2. SOLO LEVELING (principal, secundario, bloqueo)
# =====================================================================

def _sl_principal_post(ctx):
    au0, au1, au2 = ctx.pal['aura']
    cr0, cr1, cr_g = ctx.pal['carpet']
    chi = ctx.pal['castle_hi']
    cdk = ctx.pal['castle_dk']
    fhi = ctx.pal['floor_hi']
    fli = ctx.pal['floor_line']

    for gx, gy in ((86, 228), (194, 236), (396, 234)):
        for dy in range(-6, 1):
            ctx.put(gx, gy + dy, chi, check_hud=True)
            if dy <= -2:
                ctx.put(gx - 2, gy + dy + 1, cdk, check_hud=True)
                ctx.put(gx + 2, gy + dy + 1, cdk, check_hud=True)

    for bx in (116, 224, 364, 456):
        for dx in range(-4, 5):
            ctx.put(bx + dx, 232, cr_g if (dx % 2 == 0) else cr1, check_hud=True)
    _stone_courses(ctx, 16, 170, 468, 280, chi, cdk, step_x=14, step_y=10, seed=401)

    for bx, by_f, col_h in ((132, 326, 66), (194, 320, 60), (394, 320, 60), (466, 328, 64)):
        for ry in range(by_f - col_h + 12, by_f - 10, 14):
            _add_runa(ctx, bx, ry, au2, au1)

    cx_s, cy_s = 294, 356
    for rx_r, ry_r, col_r in ((74, 16, au0), (54, 11, au1)):
        for ang in range(0, 360, 4):
            rx = int(round(cx_s + rx_r * math.cos(math.radians(ang))))
            ry = int(round(cy_s + ry_r * math.sin(math.radians(ang))))
            ctx.over(rx, ry, col_r, 0.48)
    for ang in range(0, 360, 45):
        rad = math.radians(ang)
        _add_runa(ctx, cx_s + 74 * math.cos(rad), cy_s + 16 * math.sin(rad), au2, au1)

    for sx, sy in ((76, 364), (112, 376), (518, 372), (562, 362)):
        for k in range(12):
            ctx.put(sx + k // 4, sy - k, fhi if k < 8 else cr_g)
        for dx in range(-3, 4):
            ctx.put(sx + 2 + dx, sy - 9, cdk)
        ctx.put(sx + 1, sy, fli)
    _sparks(ctx, 118, 336, 62, 22, 16, au1, au0, seed=405)
    _sparks(ctx, 514, 336, 68, 22, 16, au2, au0, seed=406)


def _sl_secundario_pre(ctx):
    r_hi, r_dk, r_rim = ctx.pal['ruin']
    rk0, rk1, rk2, rk_hi = ctx.pal['rock']

    for bx, bw, bh in ((50, 15, 44), (70, 14, 62), (92, 18, 38), (122, 15, 52), (160, 16, 42)):
        top_r = HOR - 5 - bh
        for rx in range(bx + 2, bx + bw - 2, 4):
            ctx.put(rx, top_r - 1, r_dk)
            ctx.put(rx, top_r - 2, r_rim)
        if bh >= 50:
            _add_runa(ctx, bx + bw // 2, top_r - 3, '#ff4868', '#c82040')
        for wy in range(top_r + 12, HOR - 12, 12):
            if (bx + wy) % 3 == 0:
                _add_ventana(ctx, bx + bw // 2 - 1, wy, r_hi, '#ffb860', w=2, h=3)

    _rocks(ctx, [(28, HOR - 2, 7, 3), (186, HOR - 2, 8, 3), (206, HOR - 1, 6, 3)], rk_hi, rk0, rk2)


def _sl_secundario_post(ctx):
    _, _, _, hv_hi = ctx.pal['hive']
    cg0, cg1, cg2 = ctx.pal['cave_glow']
    _, rk1, rk2, rk_hi = ctx.pal['rock']
    au_m = ctx.pal['aura_mid']
    au_c = ctx.pal['aura_cyan']

    for y_s, x0, x1 in ((232, 442, 470), (244, 474, 524), (262, 446, 518)):
        for x in range(x0, x1):
            sag = int(4 * math.sin((x - x0) / float(max(1, x1 - x0)) * math.pi))
            ctx.over(x, y_s + sag, hv_hi, 0.55)
    _sparks(ctx, 486, 336, 38, 12, 10, cg1, cg0, seed=412)

    rng = random.Random(415)
    for side in (-1, 1):
        for i in range(6):
            px = 306 + side * rng.randint(32, 54)
            py = rng.randint(292, 336)
            ctx.put(px, py, rk_hi)
            ctx.put(px + 1, py, rk2)
            if i % 2 == 0:
                _add_runa(ctx, px, py - 2, au_c if i % 4 else au_m, au_m)

    _rocks(ctx, [(18, 392, 14, 7), (52, 395, 10, 5), (84, 397, 8, 4)], rk_hi, rk1, rk2)
    _sparks(ctx, 48, 384, 24, 10, 6, cg2, cg0, seed=416)


def _sl_bloqueo_post(ctx):
    st0, st1, st2, st3 = ctx.pal['stone']
    p0, p1, p2, _ = ctx.pal['portal']

    for ox in (218, 422):
        for ry in range(218, 286, 12):
            _add_runa(ctx, ox, ry, p2, p1)
        _stone_courses(ctx, ox - 9, 206, ox + 10, 294, st3, st1, step_x=8, step_y=7, seed=420 + ox)
    for fx in (64, 114, 526, 576):
        ctx.put(fx, 250, st2, check_hud=True)
        ctx.put(fx, 249, st3, check_hud=True)
        _add_farol(ctx, fx, 247, 9, p2, p0)

    for ang in range(0, 360, 4):
        rx = int(round(320 + 114 * math.cos(math.radians(ang))))
        ry = int(round(342 + 24 * math.sin(math.radians(ang))))
        ctx.over(rx, ry, p1, 0.55)
    for ang in range(0, 360, 30):
        rad = math.radians(ang)
        _add_runa(ctx, 320 + 114 * math.cos(rad), 342 + 24 * math.sin(rad), p2, p0)
    _rocks(ctx, [(28, 386, 12, 5), (72, 392, 8, 4), (568, 392, 9, 4), (612, 384, 13, 6)], st3, st1, st0)


# =====================================================================
# 3. STRANGER THINGS (principal, secundario, bloqueo)
# =====================================================================

def _st_principal_post(ctx):
    r0, r1, _, r3 = ctx.pal['rift']
    h0, h1, h2, h3 = ctx.pal['house']
    _, rd1, rd_line, _ = ctx.pal['road']
    l0, _ = ctx.pal['lamp']

    for px_c in (344, 356, 380, 392):
        for py in range(266, 286):
            ctx.put(px_c, py, h3 if py % 3 == 0 else h0)
    for x in range(342, 395):
        ctx.put(x, 274, h3)
    _add_ventana(ctx, 367, 250, h2, r1, w=3, h=4)
    _add_ventana(ctx, 336, 240, h2, l0, w=2, h=4)
    _add_ventana(ctx, 398, 240, h2, l0, w=2, h=4)
    for py in range(298, 308):
        ctx.put(296, py, h2)
    for dx in range(-2, 3):
        ctx.put(296 + dx, 297, h3)
    ctx.put(298, 296, r0)

    for px, p_top in ((76, 224), (264, 226), (514, 228)):
        for dx in range(-7, 8):
            ctx.put(px + dx, p_top + 6, rd1)
        for dy in range(5):
            for dx in range(-2, 3):
                ctx.put(px + 3 + dx, p_top + 10 + dy, h1 if dx < 0 else h2)
    for (ax, ay), (bx, by) in (((76, 230), (264, 232)), ((264, 232), (514, 234))):
        steps = abs(bx - ax)
        for i in range(0, steps + 1, 2):
            u = i / float(steps)
            wy = int(round(ay + (by - ay) * u + 12 * math.sin(u * math.pi)))
            ctx.over(ax + i, wy, '#140b14', 0.65, check_hud=True)

    for x in range(16, 624, 18):
        for dx in range(9):
            ctx.put(x + dx, 338, rd_line)
    for py in range(294, 322):
        ctx.put(546, py, h2)
    for py in range(292, 302):
        for px in range(534, 558):
            ctx.put(px, py, h3 if py in (292, 301) or px in (534, 557) else '#1a121a')
    for px in range(537, 555, 2):
        ctx.put(px, 296, '#d8c8b0')

    _ground_cracks(ctx, 118, 376, [(-0.2, 26), (0.3, 18), (2.9, 22)], r3, r0)
    _ground_cracks(ctx, 512, 378, [(3.0, 24), (2.5, 16), (-0.4, 20)], r3, r0)
    _sparks(ctx, 90, 384, 72, 12, 12, r1, r0, seed=505)
    _sparks(ctx, 540, 384, 72, 12, 12, r1, r0, seed=506)


def _st_secundario_post(ctx):
    dm0, _, r0, r1 = ctx.pal['demo']
    fl_cols = list(ctx.pal['neon'])

    for i, lx in enumerate(range(60, 170, 7)):
        sag = int(2 * math.sin(i * 0.9))
        ctx.over(lx, 281 + sag, '#141018', 0.8)
        _add_runa(ctx, lx, 283 + sag, fl_cols[i % len(fl_cols)], fl_cols[i % len(fl_cols)])
    for dy in range(16):
        ctx.put(140, 254 - dy, '#241c28')
    for dx in range(-5, 6):
        ctx.put(140 + dx, 241, '#3c3044')
    for yy in range(315, 326, 3):
        for xx in range(44, 53, 3):
            ctx.disc(xx, yy, 1, '#4a3228')

    for w_x in (220, 232):
        for ang in range(0, 360, 30):
            ctx.put(w_x + 3 * math.cos(math.radians(ang)), 322 + 3 * math.sin(math.radians(ang)), '#3a3240')
    _line(ctx, 220, 322, 226, 316, '#843440')
    _line(ctx, 226, 316, 232, 322, '#843440')
    _add_farol(ctx, 246, 318, 9, '#fff0c0', '#ffaa44')

    _ground_cracks(ctx, 488, 356, [(-0.2, 28), (-0.7, 22), (0.35, 24)], dm0, r0)
    _ground_cracks(ctx, 560, 344, [(2.8, 30), (2.2, 20), (-0.5, 18)], dm0, r0)
    _sparks(ctx, 540, 346, 68, 32, 16, r1, r0, seed=512)
    _tuft_band(ctx, 10, 148, 397, 36, 8, 22, [ctx.col('pine', 1), ctx.col('ground', 3)], seed=513)
    _tuft_band(ctx, 512, 632, 397, 36, 8, 22, [ctx.col('pine', 1), ctx.col('ground', 3)], seed=514)


def _st_bloqueo_post(ctx):
    r0, r1, _, r3 = ctx.pal['rift']
    wd0, wd1, wd2, wd_hi = ctx.pal['wood']
    fl0, fl1, _ = ctx.pal['floor']

    for y in range(150, 258):
        for x in range(12, 628, 12):
            if 288 <= x <= 352 or en_zona(x, y, 8):
                continue
            if (x + y // 12) % 3 == 0:
                ctx.over(x, y, wd2, 0.25, check_hud=True)
    for bx in range(-280, 320, 44):
        x_top = 320 + bx
        x_bot = 320 + int(bx * 1.48)
        _line(ctx, x_top, 286, x_bot, 398, '#0c060c', alpha=0.50, check_hud=False)

    for fx0, fy0, tilt in ((98, 188, 1), (412, 192, -1)):
        for dy in range(30):
            for dx in range(24):
                is_fr = dx in (0, 23) or dy in (0, 29)
                ctx.put(fx0 + dx, fy0 + dy + (dx * tilt) // 12, wd_hi if is_fr else fl1, check_hud=True)

    for yy in range(318, 342):
        for xx in range(166, 198):
            ctx.put(xx, yy, wd0 if (yy % 6 == 0 or xx in (166, 197)) else wd1)
    for xx in range(174, 186):
        for yy in range(312, 318):
            ctx.put(xx, yy, '#222434' if (xx % 4) else '#b0b8cc')
    ctx.put(190, 314, '#e6dcc8')
    ctx.put(190, 315, '#e6dcc8')
    ctx.put(190, 316, '#e6dcc8')
    _add_farol(ctx, 190, 312, 8, '#fff0c0', '#ff9848')

    _ground_cracks(ctx, 84, 378, [(-0.4, 34), (-0.9, 26), (0.2, 28)], r3, r0)
    _ground_cracks(ctx, 556, 378, [(3.5, 34), (2.7, 26), (2.1, 24)], r3, r0)
    _sparks(ctx, 148, 326, 62, 46, 12, r1, r0, seed=520)
    _sparks(ctx, 492, 326, 62, 46, 12, r1, r0, seed=521)


# =====================================================================
# 4. BLACK CLOVER (principal, secundario, bloqueo)
# =====================================================================

def _bc_principal_pre(ctx):
    st0, _, st2 = ctx.pal['stone']
    wl0, wl1 = ctx.pal['wall']
    _, tm1 = ctx.pal['timber']
    rf0, _, rf2 = ctx.pal['roof']
    gold0 = ctx.col('gold', 0)

    for hx0, hw, hh in ((16, 26, 18), (48, 28, 22)):
        by_h = HOR - 12 - (6 if hx0 == 16 else 0)
        for yy in range(by_h - hh, by_h):
            for xx in range(hx0, hx0 + hw):
                ctx.put(xx, yy, wl0 if xx < hx0 + hw // 2 else wl1)
        for dy in range(11):
            w_r = max(1, (hw // 2 + 3) - (dy * (hw // 2 + 2)) // 10)
            cx_r = hx0 + hw // 2
            for dx in range(-w_r, w_r + 1):
                ctx.put(cx_r + dx, by_h - hh - dy, rf2 if dx < 0 else rf0)
        _add_ventana(ctx, hx0 + 6, by_h - hh + 6, tm1, ctx.warm(), w=2, h=4)
        if hw >= 26:
            _add_ventana(ctx, hx0 + hw - 8, by_h - hh + 6, tm1, ctx.warm(), w=2, h=4)

    for dx, dy in ((0, -2), (-2, 0), (2, 0), (0, 2)):
        ctx.put(133 + dx, 174 + dy, gold0)
    _stone_courses(ctx, 182, HOR - 72, 210, HOR - 12, st2, st0, step_x=7, step_y=7, seed=601)
    for cx_k in (512, 526, 542, 556):
        _add_ventana(ctx, cx_k, HOR - 32, ctx.col('mont', 4), '#ffe090', w=2, h=3)


def _bc_principal_post(ctx):
    _, sw_m, sw_dk = ctx.pal['sword']
    a0, a1 = ctx.pal['anti']
    s0, s1, s2, s3 = ctx.pal['suelo']

    for k in range(14):
        cx = 56 + k
        cy = H - 24 + int(4 * math.sin(k * 0.45))
        ctx.put(cx, cy, sw_m if (k % 2 == 0) else sw_dk)
    for px, py in ((65, H - 36), (92, H - 32), (84, H - 40)):
        ctx.put(px, py, '#e8dcc4')
        ctx.put(px + 1, py, a1)
        _add_runa(ctx, px, py - 1, a1, a0)

    _flowers(ctx, [(20, H - 14), (32, H - 10), (96, H - 10), (594, H - 12), (618, H - 16)], ctx.col('gold', 0), s3, a1)
    _tuft_band(ctx, 2, 102, lambda x: H - int(26 * math.cos(min(1.0, x / 106.0) * 1.57)), 28, 5, 14, [s3, s1, s0], seed=605)
    _tuft_band(ctx, W - 62, W - 2, lambda x: H - int(18 * math.cos(min(1.0, (W - 1 - x) / 64.0) * 1.57)), 24, 5, 12, [s3, s2, s0], seed=606)
    _birds(ctx, [(276, 62), (294, 70), (344, 58)], ctx.col('mont', 3))


def _bc_secundario_post(ctx):
    cs0, _, _, cs3 = ctx.pal['castle']
    cr0, cr1, cr2 = ctx.pal['crimson']
    gd0 = ctx.pal['gold'][0]
    sn0, sn1 = ctx.pal['nieve']
    da0, da1, da2 = ctx.pal['dais']

    _icicles(ctx, 118, 296, HOR - 59, 6, 4, sn0, cs3, seed=610)
    _icicles(ctx, 42, 344, HOR - 24, 9, 5, sn0, sn1, seed=611)
    for tx, ty in ((142, HOR - 140), (206, HOR - 178), (270, HOR - 142)):
        for k in range(1, 9):
            ctx.put(tx + k, ty + k // 4, cr1 if k < 6 else cr2)
            if k < 5:
                ctx.put(tx + k, ty + 1, cr0)
    _stone_courses(ctx, 114, HOR - 60, 298, HOR - 22, cs3, cs0, step_x=12, step_y=7, seed=612)

    for rx in range(308, 464, 24):
        ctx.put(rx, HOR - 22, gd0)
        ctx.put(rx - 1, HOR - 21, cr1)
        ctx.put(rx + 1, HOR - 21, cr1)
    _sparks(ctx, 362, 236, 22, 16, 12, cr2, cr1, seed=615)

    _rocks(ctx, [(86, 364, 14, 6), (138, 376, 11, 5), (506, 372, 13, 6), (558, 362, 10, 5)], da2, da1, da0)
    _tuft_band(ctx, 16, 112, 396, 28, 6, 14, [sn1, cs3, da0], seed=616)
    _tuft_band(ctx, 518, 624, 396, 28, 6, 14, [sn1, cs3, da0], seed=617)


def _bc_bloqueo_post(ctx):
    st0, _, st2, _ = ctx.pal['stone']
    gd0, gd1 = ctx.pal['gold']
    r0, r1, _ = ctx.pal['crimson']

    for tx in (58, 556):
        if not en_zona(tx, 160, 8):
            _stone_courses(ctx, tx - 10, 152, tx + 11, 254, st2, st0, step_x=6, step_y=8, seed=620 + tx)
    _banner(ctx, 212, 220, 22, 4, r0, gd0)
    _banner(ctx, 404, 220, 22, 4, r0, gd0)

    for bx in range(-280, 320, 48):
        _line(ctx, 320 + int(bx * 0.52), HOR - 12, 320 + int(bx * 1.4), 399, st0, alpha=0.45, check_hud=False)
    for ang in range(0, 360, 72):
        rad = math.radians(ang)
        _add_runa(ctx, 320 + 28 * math.cos(rad), 359 + 8 * math.sin(rad), gd0, r1)

    for fx in (112, 528):
        for y in range(348, 366):
            ctx.put(fx, y, st0)
        _add_farol(ctx, fx, 347, 9, '#fff2c4', gd1)
    _sparks(ctx, 320, 296, 44, 18, 12, '#f0e2c8', r1, seed=625)


# =====================================================================
# 5. CONTINENTE DEMONIAC0 (principal, secundario, bloqueo)
# =====================================================================

def _cd_principal_pre(ctx):
    _, _, bs2 = ctx.pal['basalt']
    m_hi, m_lo = ctx.pal['mana']
    cr0, cr1 = ctx.pal['cristal']

    for rx in range(86, 178, 18):
        _add_runa(ctx, rx, HOR - 38, m_hi, m_lo)
    for x in range(184, 206):
        sag = int(3 * math.sin((x - 184) / 22.0 * math.pi))
        ctx.put(x, HOR - 50 + sag, ctx.pal['adobe'][2])
        if x % 4 == 0:
            ctx.put(x, HOR - 52 + sag, bs2)
    _ground_cracks(ctx, 56, HOR - 14, [(0.15, 22), (0.6, 14)], m_lo, m_hi)
    _ground_cracks(ctx, 198, HOR - 12, [(2.9, 20), (2.4, 15)], m_lo, m_hi)
    for rx_c in (288, 336, 384):
        ctx.put(rx_c, HOR - 6, cr0, check_hud=True)
        ctx.put(rx_c, HOR - 5, cr1, check_hud=True)


def _cd_principal_post(ctx):
    hg_hi, hg_core, hg_mid, _ = ctx.pal['hongo']
    cr0, cr1 = ctx.pal['cristal']
    su0, su1, _, su3 = ctx.pal['suelo']

    for cx, cy, rx in ((80, 32, 26), (140, 60, 20), (44, 114, 16)):
        for x in range(cx - rx + 4, cx + rx - 3, 4):
            ctx.over(x, cy + 3, hg_core, 0.72)
        _sparks(ctx, cx, cy + 16, rx - 4, 10, 7, hg_core, hg_hi, seed=700 + cx)

    for cx, cy in ((42, H - 10), (W - 44, H - 10)):
        for dy in range(14):
            ctx.put(cx - dy // 4, cy - dy, cr0 if dy > 6 else cr1)
            ctx.put(cx - dy // 4 + 1, cy - dy, cr1)
    _sparks(ctx, 32, H - 30, 22, 14, 8, hg_core, hg_mid, seed=708)
    _sparks(ctx, W - 32, H - 28, 22, 14, 8, hg_core, hg_mid, seed=709)
    _tuft_band(ctx, 4, 78, lambda x: H - int(22 * math.cos(min(1.0, x / 82.0) * 1.57)), 20, 5, 11, [su3, su1, su0], seed=710)


def _cd_secundario_post(ctx):
    ar3 = ctx.pal['armor'][3]
    cr0, cr1, cr2 = ctx.pal['dome']
    m_hi, _ = ctx.pal['mana']
    lv0, lv1 = ctx.pal['lava']
    hg0, hg1, _, _ = ctx.pal['hongo']

    for x in range(175, 198, 4):
        for y in range(HOR - 60, HOR - 44):
            ctx.put(x, y, ar3 if (y % 4 != 0) else '#1a0a1e')
    for x in (96, 126, 152, 220, 246, 274):
        _add_ventana(ctx, x, HOR - 64, '#1a0814', lv1, w=2, h=4)

    _sparks(ctx, 210, 368, 120, 22, 16, lv1, lv0, seed=715)
    _sparks(ctx, 388, 286, 24, 18, 10, '#a8f8ff', m_hi, seed=716)
    _rocks(ctx, [(482, 344, 8, 4), (540, 352, 11, 5), (576, 360, 9, 4)], cr2, cr1, cr0)
    _sparks(ctx, 598, 366, 28, 16, 6, hg1, hg0, seed=717)


def _cd_bloqueo_post(ctx):
    rk0, rk1, rk2, _ = ctx.pal['rock']
    lv0, lv1 = ctx.pal['lava']
    cr0, cr1, _ = ctx.pal['crimson']

    for dx in range(-4, 5):
        ctx.put(320 + dx, HOR - 18 + abs(dx) // 2, rk2)
    ctx.put(320, HOR - 21, lv1)
    _banner(ctx, 202, 232, 20, 4, lv0, cr1)
    _banner(ctx, 438, 232, 20, 4, lv0, cr1)

    for mx in (46, 82, 558, 594):
        for dy in (248, 266):
            _add_runa(ctx, mx, dy, cr1, cr0)
    _sparks(ctx, 320, 340, 14, 48, 16, lv1, lv0, seed=725)
    _sparks(ctx, 194, 246, 6, 6, 4, lv1, lv0, seed=726)
    _sparks(ctx, 446, 246, 6, 6, 4, lv1, lv0, seed=727)
    _rocks(ctx, [(112, 376, 11, 5), (528, 378, 10, 5)], rk2, rk1, rk0)


# =====================================================================
# 6. FITTOA (principal, secundario, bloqueo)
# =====================================================================

def _fittoa_principal_pre(ctx):
    st0, _, st2 = ctx.pal['stone']
    tm0, tm1 = ctx.pal['timber']
    rf0, rf1, _ = ctx.pal['roof2']
    _, cs1 = ctx.pal['cascada']

    for x in (232, 255):
        for y in range(HOR - 64, HOR - 10, 5):
            ctx.put(x, y, st2)
            ctx.put(x, y + 1, st2)
    for bx in (90, 96):
        for dy in range(5):
            ctx.put(bx, HOR - 14 + dy, tm0 if dy % 2 else tm1)
            ctx.put(bx + 1, HOR - 14 + dy, tm1)
    for k in range(6):
        ctx.over(100 + (k * 2) % 8, HOR - 3 + (k % 3), cs1, 0.7)

    for cx, by in ((386, HOR - 12), (412, HOR - 14)):
        for yy in range(by - 10, by):
            for xx in range(cx, cx + 14):
                ctx.put(xx, yy, ctx.pal['plaster'][0])
        for i in range(6):
            for xx in range(cx - 1 + i, cx + 15 - i):
                ctx.put(xx, by - 10 - i, rf1 if xx < cx + 7 else rf0)
        _add_ventana(ctx, cx + 6, by - 6, st0, ctx.warm(), w=2, h=3)
    _add_farol(ctx, 344, HOR - 7, 8, '#fff4cc', '#ffaa44')


def _fittoa_principal_post(ctx):
    r0, r1 = ctx.pal['rama']
    mn0, mn1 = ctx.pal['mana']

    rng = random.Random(802)
    for vx in range(38, 224, 24):
        ln = rng.randint(10, 26)
        top_y = 66 + (vx % 18)
        for dy in range(ln):
            ctx.over(vx + int(math.sin(dy * 0.4)), top_y + dy, r1 if dy % 2 else r0, 0.72)

    _sparks(ctx, 130, 118, 86, 36, 14, mn0, mn1, seed=803)
    _sparks(ctx, 72, 348, 56, 32, 12, mn0, mn1, seed=804)
    _sparks(ctx, 586, 348, 44, 28, 10, mn0, mn1, seed=805)
    for lx, ly in ((174, 344), (192, 356), (492, 368), (508, 354)):
        ctx.put(lx + 1, ly - 2, '#fff4f8')
        ctx.over(lx - 6, ly + 1, ctx.pal['ola'][0], 0.45)
        ctx.over(lx + 6, ly + 1, ctx.pal['ola'][0], 0.45)
    _rocks(ctx, [(12, 392, 10, 4), (624, 392, 9, 4)], ctx.pal['stone'][2], ctx.pal['stone'][1], ctx.pal['stone'][0])


def _fittoa_secundario_pre(ctx):
    _, mb1, mb2 = ctx.pal['marble']
    gd0, _, gd2 = ctx.pal['gold']
    mn0, mn1 = ctx.pal['mana']
    _, rf1, rf2 = ctx.pal['roof']

    # Cristales levitadores extra bajo la fortaleza flotante Chaos Breaker
    cbx = getattr(ctx.main, 'CBX', None)
    cby = getattr(ctx.main, 'CBY', None)
    if cbx is not None and cby is not None:
        for dx_k, len_k in ((-36, 10), (36, 10)):
            for dy in range(len_k):
                ctx.put(cbx + dx_k, cby + 20 + dy, mn0 if dy < len_k // 2 else mn1, check_hud=True)
            _add_runa(ctx, cbx + dx_k, cby + 20 + len_k, mn0, mn1)

    for px_a in (104, 146, 188, 222):
        for y in range(HOR - 12, HOR):
            ctx.put(px_a, y, mb2)
            ctx.put(px_a + 1, y, mb1)
    for rx in (256, 304, 392, 444):
        _banner(ctx, rx, HOR - 35, 10, 2, rf1, gd0)
    for x in range(148, 161, 3):
        ctx.put(x, HOR - 19, rf2)
        ctx.put(x, HOR - 18, rf1)
    _add_runa(ctx, 240, HOR - 38, mn0, gd2)


def _fittoa_secundario_post(ctx):
    ola0 = ctx.pal['ola'][0]
    mn0, mn1 = ctx.pal['mana']
    _, lt1 = ctx.pal['loto']

    for lx, ly in ((165, 344), (295, 360), (420, 338)):
        ctx.over(lx - 6, ly + 1, ola0, 0.5)
        ctx.over(lx + 6, ly + 1, ola0, 0.5)
        ctx.put(lx + 1, ly - 1, lt1)
    _sparks(ctx, 48, 356, 34, 24, 10, mn0, mn1, seed=815)
    _sparks(ctx, 578, 358, 38, 24, 10, mn0, mn1, seed=816)


def _fittoa_bloqueo_post(ctx):
    st0, st1, st2, _ = ctx.pal['stone']
    rf0, rf1, _ = ctx.pal['roof']
    mn0, mn1, _ = ctx.pal['mana']
    p0, p1, p2 = ctx.pal['pino']

    for px in range(44, 134, 11):
        for y in range(HOR - 22, HOR - 13):
            ctx.put(px, y, rf1)
    for x in range(44, 134):
        ctx.put(x, HOR - 19, rf0)
    _add_ventana(ctx, 78, HOR - 32, rf0, ctx.pal.get('win', ctx.warm()), w=2, h=4)

    for x in range(258, 382, 3):
        ctx.over(x, HOR - 17, mn1, 0.72)
    for rx in range(272, 372, 16):
        _add_runa(ctx, rx, HOR - 18, mn0, mn1)
    _sparks(ctx, 320, 215, 22, 16, 12, mn0, mn1, seed=822)

    for s_y in range(HOR + 4, 394, 14):
        _rocks(ctx, [(312 + ((s_y // 14) % 2) * 14, s_y, 7, 3)], st2, st1, st0)
    _flowers(ctx, [(84, 346), (138, 362), (176, 338), (472, 344), (534, 364), (582, 350)], '#f8e48c', p1, '#fffdf0')
    _rocks(ctx, [(34, 382, 12, 5), (602, 384, 11, 5)], st2, st1, st0)
    _tuft_band(ctx, 8, 178, 397, 36, 6, 14, [p2, p1, p0], seed=825)
    _tuft_band(ctx, 462, 632, 397, 36, 6, 14, [p2, p1, p0], seed=826)


# =====================================================================
# 7. HARRY POTTER (principal, secundario, bloqueo)
# =====================================================================

def _hp_principal_pre(ctx):
    wl = ctx.pal['wall']
    gold_hp = '#e8b84c'
    w_lit = ctx.warm()

    for tx, ty in ((204, 108), (272, 84), (350, 102), (402, 128)):
        _banner(ctx, tx, ty, 8, 2, '#9a1c28', gold_hp)
    for wx in range(288, 342, 12):
        _add_ventana(ctx, wx, 214, wl[2], w_lit, w=2, h=4)

    _add_farol(ctx, 94, HOR - 16, 8, '#fff2c4', '#ff9838')
    boat_col = '#141824'
    for bx in (184, 294, 408):
        ctx.put(bx - 3, HOR - 12, boat_col)
        ctx.put(bx - 3, HOR - 11, boat_col)
        ctx.put(bx - 2, HOR - 13, boat_col)
        _add_farol(ctx, bx + 4, HOR - 12, 6, '#ffe698', '#ff9c40')

    _birds(ctx, [(288, 56), (312, 44), (336, 66)], '#d8dce8' if ctx.fase != 'noche' else '#9ca8c8')


def _hp_principal_post(ctx):
    gold_hp = '#ffe678'

    _sparks(ctx, 224, 90, 22, 10, 10, gold_hp, '#ffa830', seed=902)
    _sparks(ctx, 48, 344, 34, 32, 10, '#88fce4', '#30a894', seed=904)
    _rocks(ctx, [(18, 388, 12, 5), (62, 393, 9, 4), (608, 391, 11, 5)], ctx.pal['cliff'][0], ctx.pal['cliff'][1], ctx.pal['cliff'][2])
    _tuft_band(ctx, 4, 96, 397, 32, 8, 22, [ctx.col('pine', 1), ctx.col('pine', 0)], seed=905)
    _tuft_band(ctx, 548, 636, 397, 26, 7, 18, [ctx.col('pine', 1), ctx.col('pine', 0)], seed=906)


def _hp_secundario_post(ctx):
    st0, st1, st2, _ = ctx.pal['stone']
    tr0, tr1, _, tr3 = ctx.pal['train']
    sn0, sn1, _, _ = ctx.pal['snow']
    pat0, pat1, _ = ctx.pal['pat']

    _railing(ctx, 232, 312, 224, 2, 10, st2, st1)
    _railing(ctx, 602, 636, 224, 2, 10, st2, st1)
    for ax in range(254, 624, 42):
        ctx.put(ax, 232, st2, check_hud=True)
        ctx.put(ax, 233, st1, check_hud=True)
    for wx in range(382, 586, 16):
        _add_ventana(ctx, wx, 200, tr0, ctx.warm(), w=3, h=4)
    _add_farol(ctx, 599, 204, 8, '#ff4860', '#d01830')

    for sx in (82, 164):
        for dx in range(5):
            ctx.put(sx + dx, 266, tr1)
            ctx.put(sx + dx, 267, tr3)
    _icicles(ctx, 56, 178, 256, 7, 3, sn0, sn1, seed=910)

    _sparks(ctx, 458, 322, 42, 24, 16, pat1, pat0, seed=912)
    _rocks(ctx, [(28, 378, 12, 5), (76, 386, 9, 4), (566, 384, 12, 5), (612, 376, 10, 4)], st2, st1, st0)
    _tuft_band(ctx, 6, 118, 397, 26, 6, 14, [sn1, st2, st0], seed=914)


def _hp_bloqueo_post(ctx):
    fl0, fl1, _ = ctx.pal['floor']
    br0, _, br2, br3 = ctx.pal['brick']
    gd0, _, gd2 = ctx.pal['gold']

    _stone_courses(ctx, 20, 120, 620, 290, br3, br2, step_x=12, step_y=6, seed=920)
    for x in range(306, 335):
        for y in range(166, 176):
            is_bd = x in (306, 334) or y in (166, 175)
            ctx.put(x, y, gd0 if is_bd else '#180c10')
    ctx.put(316, 171, '#f4ecdc')
    ctx.put(320, 171, gd0)
    ctx.put(324, 171, '#f4ecdc')
    for sx in (204, 436):
        ctx.put(sx, 238, br0)
        ctx.put(sx, 237, gd2)
        _add_farol(ctx, sx, 235, 10, '#fff2c0', '#ffa440')

    for x in range(12, 628, 2):
        ctx.over(x, 384, gd2, 0.42)
    _stone_courses(ctx, 16, 294, 624, 398, fl1, fl0, step_x=22, step_y=12, seed=921)
    for dy, c_bk in ((0, '#6a1e28'), (3, '#1e3c58'), (6, '#382a1c')):
        for dx in range(16):
            ctx.put(322 + dx, 344 - dy, c_bk)
            ctx.put(322 + dx, 345 - dy, gd2 if dx == 0 else c_bk)
    _line(ctx, 324, 338, 342, 333, '#885c38')
    _add_runa(ctx, 343, 333, '#fff6c8', gd0)
    for fx, fy in ((264, 356), (278, 362), (312, 360)):
        ctx.put(fx, fy, '#f4f8ff')
        ctx.put(fx + 1, fy, '#dce6f4')
    _sparks(ctx, 320, 254, 24, 20, 8, '#fff4b8', gd0, seed=925)


# =====================================================================
# 8. HUNTER X HUNTER (principal, secundario, bloqueo)
# =====================================================================

def _hxh_principal_pre(ctx):
    wd0, wd1, wdk = ctx.pal['wood']
    _, sl1 = ctx.pal['sail']
    nn0, nn1 = ctx.pal['nen']

    _line(ctx, 292, HOR - 40, 276, HOR - 12, sl1, alpha=0.8)
    _line(ctx, 292, HOR - 40, 308, HOR - 12, sl1, alpha=0.8)
    for dy in range(4):
        for dx in range(6):
            ctx.put(256 + dx, HOR - 8 + dy, wd1 if (dy == 0 or dx % 2) else wd0)
            ctx.put(266 + dx, HOR - 7 + dy, wd0 if dy % 2 else wdk)
    for vx in (121, 135, 156, 170):
        for dx in range(4):
            ctx.put(vx - 1 + dx, HOR - 40, ctx.pal['fol'][0])
    ctx.put(365, HOR - 4, '#e83848')
    ctx.put(365, HOR - 3, '#ffffff')
    _add_runa(ctx, 184, HOR - 62, nn1, nn0)


def _hxh_principal_post(ctx):
    nn0, nn1 = ctx.pal['nen']
    s0, s1, _, s3 = ctx.pal['suelo']

    for cx, cy in ((12, 22), (18, 25), (10, 28)):
        ctx.disc(cx, cy, 2, ctx.pal['wood'][0])
        ctx.put(cx - 1, cy - 1, ctx.pal['wood'][1])
    _rocks(ctx, [(22, 391, 9, 4), (48, 394, 7, 3), (602, 391, 10, 4)], ctx.pal['wall'][0], ctx.pal['wood'][0], ctx.pal['wood'][2])
    _sparks(ctx, 42, 368, 28, 18, 8, nn1, nn0, seed=1004)
    _sparks(ctx, 598, 368, 28, 18, 8, nn1, nn0, seed=1005)
    _tuft_band(ctx, 4, 68, 397, 24, 6, 15, [s3, s1, s0], seed=1006)
    _birds(ctx, [(262, 60), (282, 50), (354, 70)], ctx.col('mont', 1))


def _hxh_secundario_post(ctx):
    r_line = ctx.pal['roof_line']
    g_mid = ctx.pal['grass_mid']
    g_hi = ctx.pal['grass_hi']
    g_sh = ctx.pal['grass_sh']
    nn0, nn1 = ctx.pal['nen']

    for px in (428, 450, 495, 514):
        for dy in range(18):
            ctx.put(px + ((dy // 3) % 2), 312 + dy, g_sh if dy % 2 else g_mid)
    for tx, ty in ((472, 64), (582, 134)):
        if not en_zona(tx, ty, 8):
            for dy in range(1, 6):
                ctx.put(tx, ty - dy, ctx.pal['tile_y'], check_hud=True)
            _add_runa(ctx, tx, ty - 6, nn1, nn0)

    for dy in range(12):
        ctx.put(108, 212 + dy, r_line)
    for dx in range(-3, 4):
        ctx.put(108 + dx, 212, ctx.pal['dirt'][2])

    _flowers(
        ctx,
        [(136, 294), (178, 326), (244, 344), (312, 316), (366, 368), (546, 376), (594, 354)],
        ctx.pal['ball'][1],
        g_sh,
        ctx.pal['ball'][0],
    )
    _sparks(ctx, 272, 224, 32, 16, 8, nn1, nn0, seed=1015)
    _tuft_band(ctx, 6, 150, 397, 34, 6, 15, [g_hi, g_mid, g_sh], seed=1016)
    _tuft_band(ctx, 488, 634, 397, 34, 6, 15, [g_hi, g_mid, g_sh], seed=1017)
    _birds(ctx, [(168, 62), (192, 54)], ctx.col('mont', 0))


def _hxh_bloqueo_post(ctx):
    tw0, _, tw2, tw3 = ctx.pal['twr']
    gd0, _ = ctx.pal['gold']
    w_col = ctx.pal['win']
    cy_col = ctx.pal['cyan']

    for nx in (272, 368):
        for ny in range(158, 250, 6):
            ctx.put(nx, ny, cy_col, check_hud=True)
            ctx.put(nx, ny + 1, gd0, check_hud=True)
        _add_runa(ctx, nx, 156, w_col, cy_col)

    for zx in range(184, 456, 20):
        for dy in range(4):
            for dx in range(10):
                ctx.over(zx + dx, 292 + dy, tw3, 0.36)
    for dy in range(-5, 6):
        for dx in range(-4, 5):
            if abs(dx) + abs(dy) in (4, 5):
                ctx.put(320 + dx, 352 + dy, cy_col)
            elif abs(dx) + abs(dy) <= 1:
                ctx.put(320 + dx, 352 + dy, w_col)
    _add_runa(ctx, 320, 352, '#ffffff', cy_col)

    _stone_courses(ctx, 16, 282, 624, 398, tw2, tw0, step_x=18, step_y=12, seed=1022)
    for wx, wy in ((28, 244), (72, 224), (150, 232), (442, 250)):
        _add_ventana(ctx, wx, wy, tw0, w_col, w=2, h=4)


# =====================================================================
# 9. SPIDER-MAN MILES MORALES (principal, secundario, bloqueo)
# =====================================================================

def _sm_principal_pre(ctx):
    _, _, br2 = ctx.pal['bridge']
    nr, nc, ny = ctx.pal['neon_r'], ctx.pal['neon_c'], ctx.pal['neon_y']
    _, st1 = ctx.pal['steel']

    for tx in range(226, 408, 18):
        ctx.put(tx, HOR - 25, nr if (tx // 18) % 2 else ny)
        ctx.put(tx + 1, HOR - 25, nr if (tx // 18) % 2 else '#ffffff')
    for tx in (268, 370):
        for dy in range(1, 8):
            ctx.put(tx, HOR - 82 - dy, st1)
        for dx in range(1, 6):
            ctx.put(tx + dx, HOR - 88, nr if dx % 2 else nc)
            ctx.put(tx + dx, HOR - 87, '#dce6f2' if dx < 3 else nr)
    for x in range(224, 412, 8):
        if abs(x - 268) < 10 or abs(x - 370) < 10:
            continue
        _line(ctx, x, HOR - 46 + abs(x - 319) // 6, x, HOR - 25, br2, alpha=0.45)

    ctx.put(68, HOR - 11, nr)
    ctx.put(68, HOR - 10, nr)
    ctx.put(69, HOR - 10, st1)
    for dx in range(10):
        ctx.put(134 + dx, HOR - 16, '#0c1814')
    ctx.put(136, HOR - 15, '#38f09c')
    ctx.put(141, HOR - 15, '#38f09c')
    _add_runa(ctx, 139, HOR - 16, '#84ffd0', '#24d884')
    _add_runa(ctx, 402, 191, nr, nr)


def _sm_principal_post(ctx):
    st0, st1 = ctx.pal['steel']
    nr, nc, ny = ctx.pal['neon_r'], ctx.pal['neon_c'], ctx.pal['neon_y']

    _railing(ctx, 2, 72, H - 18, 12, 12, st1, st0)
    _railing(ctx, W - 66, W - 2, H - 16, 11, 12, st1, st0)
    for cx, col_cap in ((16, nr), (21, nc), (26, ny)):
        for dy in range(5):
            ctx.put(cx, H - 5 - dy, col_cap if dy == 4 else st1)
            ctx.put(cx + 1, H - 5 - dy, col_cap if dy == 4 else st0)
    _sparks(ctx, 40, H - 14, 24, 9, 8, ny, nc, seed=1104)
    _sparks(ctx, W - 36, H - 13, 22, 8, 8, nc, ny, seed=1105)


def _sm_secundario_pre(ctx):
    st0, st1 = ctx.pal['steel']
    cn0, cn1, _ = ctx.pal['concrete']
    nr, _, _ = ctx.pal['neon_r'], ctx.pal['neon_c'], ctx.pal['neon_y']

    for x in range(224, 632, 18):
        if en_zona(x, 238, 6):
            continue
        _line(ctx, x, 236, x + 12, 243, st0, alpha=0.8)
        _line(ctx, x + 12, 236, x, 243, st1, alpha=0.7)
    for wx in range(292, 402, 14):
        _add_ventana(ctx, wx, 220, cn0, '#ffe49c', w=3, h=3)
    _add_runa(ctx, 412, 222, nr, nr)
    for dy in range(10):
        ctx.put(250, 227 - dy, st0)
    _add_runa(ctx, 250, 217, '#44f894', '#1ab860')

    for bx in range(20, 204, 28):
        ctx.put(bx, HOR - 10, st1)
        ctx.put(bx, HOR - 9, st0)
        for dx in range(1, 10):
            ctx.put(bx + dx, HOR - 8, cn1)


def _sm_secundario_post(ctx):
    st0, st1 = ctx.pal['steel']
    nr, nc, _ = ctx.pal['neon_r'], ctx.pal['neon_c'], ctx.pal['neon_y']

    for dx in range(-3, 4):
        ctx.put(118 + dx, 319, nr)
    for dy in range(5):
        ctx.put(118, 318 - dy, st1)
    _add_farol(ctx, 118, 312, 8, '#ff4868', nr)
    _railing(ctx, 2, 56, H - 18, 12, 11, st1, st0)
    _railing(ctx, W - 56, W - 2, H - 18, 12, 11, st1, st0)
    _sparks(ctx, 32, H - 13, 18, 8, 6, nc, nr, seed=1112)
    _sparks(ctx, W - 32, H - 13, 18, 8, 6, nr, nc, seed=1113)


def _sm_bloqueo_post(ctx):
    _, bk1, bk2 = ctx.pal['brick']
    rf0, rf1, rf2 = ctx.pal['roof']
    _, _, _, ct3 = ctx.pal['city']
    nr, nc, ny = ctx.pal['red'], ctx.pal['cyan'], ctx.pal['win']

    _stone_courses(ctx, 8, 296, 632, 327, bk1, bk2, step_x=10, step_y=5, seed=1120)
    for x in range(0, 640, 2):
        ctx.over(x, 294, rf2, 0.5)

    for mx in (228, 243, 258):
        for my in range(298, 326):
            ctx.put(mx, my, rf0)
    for dy in range(18):
        for dx in range(26):
            is_edge = dy in (0, 17) or dx in (0, 25)
            ctx.put(416 + dx, 316 + dy, ct3 if is_edge else (rf2 if (dy % 3 == 0) else rf0))
    ctx.disc(424, 325, 4, rf0)
    for dy in range(-5, 6):
        ctx.put(450 + abs(dy) // 2, 312 + dy, rf1)
    for px in (384, 396):
        ctx.put(px, 292, ct3)
        ctx.put(px + 1, 292, rf0)
        ctx.put(px, 291, rf2)

    for yy in range(340, 350):
        for xx in range(138, 148):
            ctx.put(xx, yy, nr if yy < 344 else '#181422')
    ctx.put(142, 344, nc)
    for px, py, pw in ((182, 358, 28), (356, 368, 36), (484, 360, 24)):
        for dx in range(-pw // 2, pw // 2 + 1):
            col_r = nc if (dx % 7 == 0) else (nr if dx % 5 == 0 else rf2)
            ctx.over(px + dx, py, col_r, 0.42)
            ctx.over(px + dx // 2, py + 1, col_r, 0.25)

    for wx, wy in ((28, 194), (174, 186), (282, 202), (382, 180)):
        _add_ventana(ctx, wx, wy, rf0, ny, w=2, h=4)
    _sparks(ctx, 118, 296, 18, 12, 10, ny, nc, seed=1124)


# =====================================================================
# 10. NARUTO SHIPPUDEN (principal, secundario, bloqueo)
# =====================================================================

def _naruto_principal_post(ctx):
    br_r, br_o, br_y, br_k, _ = ctx.pal['baryon']
    g0, _, g2, g3 = ctx.pal['ground']
    is_w, is_s, _, _, is_g = ctx.pal['isshiki']

    # Grietas incandescentes compactas bajo los pies de Naruto (198, 344) y de Isshiki (392, 344)
    _ground_cracks(ctx, 198, 345, [(-2.9, 16), (-2.5, 14), (-0.4, 16), (0.2, 15)], br_r, br_y)
    _ground_cracks(ctx, 392, 345, [(-2.9, 14), (-2.4, 12), (-0.3, 14)], is_s, is_g)

    # Peñascos fracturados y escombros dimensionales en primer plano
    _rocks(ctx, [(28, 362, 12, 5), (104, 378, 9, 4), (446, 364, 11, 4)], g3, g0, g2)

    # Chispas de fusion nuclear Baryon en arco y destellos en los cubos Daikokuten
    _sparks(ctx, 184, 282, 46, 40, 18, br_y, br_r, seed=901)
    _sparks(ctx, 326, 276, 36, 24, 10, is_g, br_r, seed=902, runa_stride=3)
    _add_runa(ctx, 211, 319, '#fff4b4', br_o)


def _naruto_secundario_pre(ctx):
    c0, c1, c2, c3 = ctx.pal['cliff']
    r0, r1, _, _ = ctx.pal['roof']
    t0, _, _, t3 = ctx.pal['tree']

    # Farolillos adicionales a lo largo de la orilla del Río Naka (x=108..430)
    for fx in (106, 176, 260, 408):
        _add_farol(ctx, fx, HOR - 8, 6, '#fff0bc', '#ff782c')

    # Banderines rojos con emblema Konoha flanqueando el Edificio del Hokage
    for bx in (190, 246):
        _banner(ctx, bx, HOR - 30, 12, 2, r1, c3)

    # Matorrales verdes y piedra musgosa en la base del farallón
    _tuft_band(ctx, 14, 444, HOR - 12, 28, 3, 6, [t0, t3, c2], seed=922)


def _naruto_secundario_post(ctx):
    ol0, ol1, _ = ctx.pal['olas']
    r1 = ctx.pal['roof'][1]
    t0, _, _, t3 = ctx.pal['tree']
    w0, w1, _ = ctx.pal['wood']

    # Embarcadero de madera y farolillo en la orilla inferior izquierda sobre el río (x=12..78, y=354..384)
    for y in range(362, 374):
        for x in range(12, 68):
            ctx.put(x, y, w0 if y % 3 else w1)
    for px in (20, 44, 62):
        for y in range(358, 378):
            ctx.put(px, y, w1)
    _add_farol(ctx, 62, 357, 7, '#fff2c4', '#ff7c2c')

    # Hojas arremolinadas de Konoha y reflejos naranjas sobre el Río Naka
    _sparks(ctx, 218, 326, 95, 22, 12, ol0, ol1, seed=924, runa_stride=4)
    _sparks(ctx, 64, 242, 18, 12, 6, '#ffefb8', r1, seed=925)
    _tuft_band(ctx, 0, 22, 396, 8, 5, 9, [t0, t3], seed=926)


def _naruto_bloqueo_pre(ctx):
    wf1, wf2 = ctx.pal['water_f'][1], ctx.pal['water_f'][2]

    # Bruma ascendente en los bordes de la cascada del Valle del Fin
    for bx in range(242, 328, 8):
        ctx.over(bx, HOR - 4, wf2, 0.65)
        ctx.over(bx + 2, HOR - 7, wf1, 0.45)

    # Sellos de energía eléctrica/espiral alrededor de Rasengan y Chidori
    _sparks(ctx, 284, 246, 26, 18, 14, '#ffffff', ctx.pal['rasen'][1], seed=933, runa_stride=2)


def _naruto_bloqueo_post(ctx):
    st0, st1, st2, st3 = ctx.pal['statue']
    cl2 = ctx.pal['cliff'][2]

    # Rocas ribereñas y monolito del emblema de Konoha en primer plano inferior izquierdo
    _rocks(ctx, [(24, 376, 16, 6), (62, 386, 11, 5), (442, 378, 14, 5)], st3, st1, cl2)
    for dy in range(18):
        for dx in range(-4, 5):
            ctx.put(38 + dx, 360 + dy, st2 if abs(dx) == 4 else st0)
    # Bruma azul-violeta reflejada bajo el choque sobre las aguas del valle
    _sparks(ctx, 284, 324, 34, 18, 12, ctx.pal['rasen'][1], ctx.pal['chido'][1], seed=935, runa_stride=3)


def _jujutsu_principal_post(ctx):
    # Destellos carmesi del Sagrario Malevolente, Vacio Infinito, choque Purpura Vacio y grietas del suelo
    _sparks(ctx, 132, 210, 44, 26, 16, '#fb7185', '#f43f5e', seed=1111, runa_stride=3)
    _sparks(ctx, 446, 146, 54, 34, 18, '#38bdf8', '#c084fc', seed=1112, runa_stride=3)
    _sparks(ctx, 306, 298, 28, 18, 14, '#e879f9', '#f5d0fe', seed=1113, runa_stride=2)
    _ground_cracks(ctx, 214, 348, [(2.7, 18), (0.35, 16), (3.0, 14)], '#f43f5e', '#fb7185')
    _ground_cracks(ctx, 398, 348, [(2.8, 16), (0.4, 18), (0.1, 14)], '#38bdf8', '#c084fc')
    _rocks(ctx, [(28, 368, 9, 4), (92, 380, 11, 5), (542, 376, 11, 5), (608, 366, 8, 4)], '#4c324e', '#2c1d2e', '#140b18')


def _jujutsu_secundario_post(ctx):
    # Destellos negros sobre Itadori, sello de Prision Confinadora, rayos de Nue y cruce de Shibuya
    _sparks(ctx, 187, 323, 28, 18, 14, '#e11d48', '#fda4af', seed=1121, runa_stride=2)
    _sparks(ctx, 314, 282, 26, 18, 12, '#f43f5e', '#a855f7', seed=1122, runa_stride=2)
    _sparks(ctx, 390, 200, 36, 20, 14, '#38bdf8', '#818cf8', seed=1123, runa_stride=3)
    _add_farol(ctx, 84, 258, 7, '#fef08a', '#f59e0b')
    _add_farol(ctx, 444, 258, 7, '#a5f3fc', '#38bdf8')


def _jujutsu_bloqueo_post(ctx):
    # Sellos Ofuda, dedo maldito de Sukuna y cuatro linternas Toro del recinto sagrado
    _sparks(ctx, 320, 166, 46, 22, 14, '#fde047', '#ef4444', seed=1131, runa_stride=3)
    _sparks(ctx, 320, 290, 34, 18, 16, '#ef4444', '#c084fc', seed=1132, runa_stride=2)
    for fx, fy in ((228, 236), (412, 236), (182, 310), (458, 310)):
        _add_farol(ctx, fx, fy, 8, '#fef08a', '#f97316')
    _tuft_band(ctx, 10, 138, 386, 36, 8, 18, ['#451a2b', '#2c0f1c', '#180610'], seed=1133)
    _tuft_band(ctx, 504, 632, 386, 36, 8, 18, ['#451a2b', '#2c0f1c', '#180610'], seed=1134)


# =====================================================================
# 12. ATTACK ON TITAN (principal, secundario, bloqueo)
# =====================================================================

def _aot_principal_post(ctx):
    # Brasas del Retumbar, vapor de Titanes Colosales y chispas de acero EDM sobre Shiganshina
    _sparks(ctx, 294, 134, 64, 28, 18, '#fde047', '#f97316', seed=1211, runa_stride=3)
    _sparks(ctx, 210, 326, 26, 18, 12, '#bae6fd', '#ef4444', seed=1212, runa_stride=3)
    _sparks(ctx, 392, 322, 28, 18, 12, '#e2e8f0', '#38bdf8', seed=1213, runa_stride=3)
    _ground_cracks(ctx, 250, 354, [(2.8, 18), (0.3, 16), (2.4, 12)], '#f97316', '#fde047')
    _rocks(ctx, [(26, 370, 9, 4), (86, 384, 12, 5), (546, 382, 11, 5), (610, 368, 8, 4)], '#5a4a42', '#3a2e28', '#221814')
    _tuft_band(ctx, 6, 128, 394, 34, 8, 20, ['#4d382c', '#36241b', '#22150e'], seed=1214)


def _aot_secundario_post(ctx):
    # Relampago dorado del Titan Colosal tras la Muralla Maria y destellos del Cuerpo de Exploracion
    _sparks(ctx, 202, 120, 48, 34, 20, '#fef08a', '#f59e0b', seed=1221, runa_stride=2)
    _sparks(ctx, 320, 276, 32, 16, 12, '#fb923c', '#ef4444', seed=1222, runa_stride=3)
    _add_farol(ctx, 146, 278, 7, '#fde68a', '#f59e0b')
    _add_farol(ctx, 430, 278, 7, '#fde68a', '#f59e0b')
    _birds(ctx, [(74, 78), (102, 68), (376, 62)], '#3b2420')


def _aot_bloqueo_post(ctx):
    # Polvo estelar dorado de La Coordenada y memorial de cuchillas EDM bajo el arbol
    _sparks(ctx, 320, 148, 62, 48, 22, '#67e8f9', '#fde047', seed=1231, runa_stride=2)
    _sparks(ctx, 320, 320, 36, 18, 14, '#e2e8f0', '#38bdf8', seed=1232, runa_stride=3)
    _tuft_band(ctx, 12, 160, 384, 42, 8, 20, ['#2e5248', '#1f3b34', '#132420'], seed=1233)
    _tuft_band(ctx, 488, 632, 384, 42, 8, 20, ['#2e5248', '#1f3b34', '#132420'], seed=1234)


# =====================================================================
# 13. ONE PIECE (principal, secundario, bloqueo)
# =====================================================================

def _op_principal_post(ctx):
    # Relampagos de Haki del Rey, Bajrang Gun y aliento igneo de Kaido en Onigashima
    _sparks(ctx, 236, 306, 36, 22, 16, '#f472b6', '#ef4444', seed=1311, runa_stride=2)
    _sparks(ctx, 308, 276, 40, 24, 18, '#fef08a', '#f97316', seed=1312, runa_stride=2)
    _sparks(ctx, 358, 204, 48, 26, 16, '#38bdf8', '#818cf8', seed=1313, runa_stride=3)
    _ground_cracks(ctx, 204, 348, [(2.8, 16), (0.3, 15)], '#ef4444', '#f472b6')
    _rocks(ctx, [(22, 368, 10, 5), (84, 382, 12, 5), (546, 380, 11, 5), (612, 366, 9, 4)], '#4a3d5a', '#2e243a', '#181222')


def _op_secundario_pre(ctx):
    _birds(ctx, [(86, 82), (118, 70), (392, 64), (428, 78)], '#1e293b')


def _op_secundario_post(ctx):
    # Linternas del Thousand Sunny, aura verde de Zoro y Diable Jambe azul de Sanji
    _add_farol(ctx, 276, 234, 7, '#fef08a', '#f59e0b')
    _add_farol(ctx, 332, 234, 7, '#fef08a', '#f59e0b')
    _sparks(ctx, 292, 216, 14, 10, 8, '#4ade80', '#22c55e', seed=1321, runa_stride=2)
    _sparks(ctx, 314, 216, 14, 10, 8, '#38bdf8', '#60a5fa', seed=1322, runa_stride=2)
    _sparks(ctx, 304, 286, 56, 8, 10, '#e0f2fe', '#38bdf8', seed=1323, runa_stride=4)


def _op_bloqueo_post(ctx):
    # Glifos brillantes del Road Poneglyph carmesi, Sombrero de Paja y Fruta Nika
    _sparks(ctx, 198, 288, 26, 26, 16, '#38bdf8', '#f43f5e', seed=1331, runa_stride=2)
    _sparks(ctx, 404, 318, 22, 16, 12, '#e879f9', '#fde047', seed=1332, runa_stride=2)
    _rocks(ctx, [(34, 364, 9, 4), (528, 370, 10, 5), (598, 358, 8, 4)], '#64748b', '#475569', '#1e293b')
    _tuft_band(ctx, 8, 122, 386, 30, 7, 16, ['#166534', '#14532d', '#052e16'], seed=1333)


# =====================================================================
# 14. DRAGON BALL Z (principal, secundario, bloqueo)
# =====================================================================

def _dbz_principal_post(ctx):
    # Ki plateado del Ultra Instinto, Supernova de Freezer Dorado y choque Kamehameha en Namek
    _sparks(ctx, 202, 322, 36, 26, 18, '#e0f2fe', '#38bdf8', seed=1411, runa_stride=2)
    _sparks(ctx, 304, 298, 38, 22, 18, '#fef08a', '#f97316', seed=1412, runa_stride=2)
    _sparks(ctx, 386, 296, 30, 22, 14, '#f43f5e', '#facc15', seed=1413, runa_stride=2)
    _ground_cracks(ctx, 202, 348, [(2.8, 18), (0.3, 16), (2.4, 12)], '#f97316', '#fde047')
    _ground_cracks(ctx, 404, 344, [(2.9, 16), (0.4, 18)], '#ef4444', '#facc15')


def _dbz_secundario_pre(ctx):
    _birds(ctx, [(78, 76), (112, 88), (402, 68)], '#164e63')


def _dbz_secundario_post(ctx):
    # Relampagos verdes-dorados de Shenron y resplandor de las 7 Bolas de Dragon
    _sparks(ctx, 288, 154, 62, 54, 22, '#fef08a', '#4ade80', seed=1421, runa_stride=2)
    _sparks(ctx, 288, 275, 58, 12, 16, '#facc15', '#f97316', seed=1422, runa_stride=2)
    _tuft_band(ctx, 6, 124, 278, 28, 7, 16, ['#22d3ee', '#0891b2', '#164e63'], seed=1423)


def _dbz_bloqueo_pre(ctx):
    _birds(ctx, [(84, 72), (120, 62), (382, 74)], '#334155')


def _dbz_bloqueo_post(ctx):
    # Farol calido de Kame House, aureola dorada de la Bola de 4 Estrellas y brisa en la Nube Kinton
    _add_farol(ctx, 186, 214, 9, '#fef3c7', '#f59e0b')
    _sparks(ctx, 422, 256, 24, 18, 14, '#fef08a', '#f97316', seed=1431, runa_stride=2)
    _sparks(ctx, 242, 128, 28, 12, 10, '#fde68a', '#fbbf24', seed=1432, runa_stride=3)


# =====================================================================
# 15. CYBERPUNK EDGERUNNERS (principal, secundario, bloqueo)
# =====================================================================

def _cyber_principal_post(ctx):
    # Chispas cromaticas del Sandevistan, monofilo de Lucy y neones de Arasaka / Quadra
    _sparks(ctx, 228, 322, 42, 22, 16, '#22d3ee', '#4ade80', seed=1511, runa_stride=2)
    _sparks(ctx, 328, 308, 38, 18, 14, '#fb7185', '#fde047', seed=1512, runa_stride=2)
    _sparks(ctx, 160, 82, 24, 16, 10, '#f43f5e', '#fb7185', seed=1513, runa_stride=3)
    _add_farol(ctx, 41, 320, 8, '#fda4af', '#ef4444')
    _add_farol(ctx, 136, 320, 7, '#a5f3fc', '#22d3ee')


def _cyber_secundario_post(ctx):
    # Brillo del crater Tycho, monorrail NCART, aura lunar de David & Lucy y balizas de azotea
    _sparks(ctx, 316, 92, 54, 42, 18, '#e0f2fe', '#38bdf8', seed=1521, runa_stride=3)
    _sparks(ctx, 162, 222, 44, 10, 12, '#67e8f9', '#06b6d4', seed=1522, runa_stride=3)
    _sparks(ctx, 315, 274, 28, 16, 10, '#bae6fd', '#f472b6', seed=1523, runa_stride=3)
    for bx in (42, 148, 240, 396):
        _add_farol(ctx, bx, 259, 6, '#e0f2fe', '#38bdf8' if bx % 2 == 0 else '#f472b6')


def _cyber_bloqueo_post(ctx):
    # Mural ER en spray acido, letrero Afterlife e implante espinal Apogee Sandevistan
    _sparks(ctx, 320, 198, 44, 34, 18, '#4ade80', '#facc15', seed=1531, runa_stride=2)
    _sparks(ctx, 132, 182, 26, 14, 10, '#f43f5e', '#fb7185', seed=1532, runa_stride=3)
    _sparks(ctx, 320, 317, 38, 14, 16, '#22d3ee', '#4ade80', seed=1533, runa_stride=2)
    _add_farol(ctx, 34, 272, 9, '#a5f3fc', '#0ea5e9')


# =====================================================================
# 16. TERRAZA DE LOS MICHIS (principal, secundario, bloqueo)
# =====================================================================

def _michis_principal_post(ctx):
    # Luciérnagas sobre el cesped, brillos en la pelotita multicolor y matitas de hierba
    _sparks(ctx, 138, 294, 20, 14, 8, '#fde047', '#fb7185', seed=1611, runa_stride=3)
    _sparks(ctx, 310, 276, 48, 18, 10, '#fef08a', '#4ade80', seed=1612, runa_stride=3)
    _tuft_band(ctx, 120, 440, 266, 20, 6, 10, ['#4ade80', '#22c55e', '#86efac'], seed=1613)


def _michis_secundario_post(ctx):
    # Brillos sobre el rascador y la pelotita multicolor en el cesped
    _sparks(ctx, 262, 236, 18, 14, 8, '#fef08a', '#a3e635', seed=1621, runa_stride=3)
    _sparks(ctx, 290, 324, 26, 16, 10, '#fde047', '#4ade80', seed=1622, runa_stride=3)
    _tuft_band(ctx, 26, 450, 272, 22, 6, 10, ['#4ade80', '#22c55e', '#a3e635'], seed=1623)


def _michis_bloqueo_post(ctx):
    # Aureola calida del farol y destellos zen alrededor del cojin y los michis
    _sparks(ctx, 320, 312, 34, 18, 14, '#fef08a', '#4ade80', seed=1631, runa_stride=2)
    _sparks(ctx, 176, 322, 18, 14, 8, '#fbbf24', '#fef3c7', seed=1632, runa_stride=3)


# =====================================================================
# 17. SALÓN DE NOAH Y MAGGIE (principal, secundario, bloqueo)
# =====================================================================

def _salon_principal_post(ctx):
    _sparks(ctx, 118, 178, 28, 16, 6, '#fde68a', '#93c5fd', seed=1712, runa_stride=4)


def _salon_secundario_post(ctx):
    _sparks(ctx, 290, 96, 26, 18, 8, '#fef08a', '#fde68a', seed=1721, runa_stride=3)


def _salon_bloqueo_post(ctx):
    _sparks(ctx, 240, 42, 64, 10, 8, '#fef08a', '#fbbf24', seed=1731, runa_stride=3)


# =====================================================================
# TABLA DE DESPACHO PARA LAS ESCENAS
# =====================================================================

_PRE_LAGO = {
    ('black-clover', 'principal'): _bc_principal_pre,
    ('continente-demoniaco', 'principal'): _cd_principal_pre,
    ('dragon-ball-z', 'secundario'): _dbz_secundario_pre,
    ('dragon-ball-z', 'bloqueo'): _dbz_bloqueo_pre,
    ('fittoa', 'principal'): _fittoa_principal_pre,
    ('fittoa', 'secundario'): _fittoa_secundario_pre,
    ('harry-potter', 'principal'): _hp_principal_pre,
    ('hunter-x-hunter', 'principal'): _hxh_principal_pre,
    ('naruto', 'secundario'): _naruto_secundario_pre,
    ('naruto', 'bloqueo'): _naruto_bloqueo_pre,
    ('one-piece', 'secundario'): _op_secundario_pre,
    ('solo-leveling', 'secundario'): _sl_secundario_pre,
    ('spiderman-miles-morales', 'principal'): _sm_principal_pre,
    ('spiderman-miles-morales', 'secundario'): _sm_secundario_pre,
}

_POST_ESCENA = {
    ('attack-on-titan', 'principal'): _aot_principal_post,
    ('attack-on-titan', 'secundario'): _aot_secundario_post,
    ('attack-on-titan', 'bloqueo'): _aot_bloqueo_post,
    ('cyberpunk-edgerunners', 'principal'): _cyber_principal_post,
    ('cyberpunk-edgerunners', 'secundario'): _cyber_secundario_post,
    ('cyberpunk-edgerunners', 'bloqueo'): _cyber_bloqueo_post,
    ('demon-slayer', 'principal'): _ds_principal_post,
    ('demon-slayer', 'secundario'): _ds_secundario_post,
    ('demon-slayer', 'bloqueo'): _ds_bloqueo_post,
    ('dragon-ball-z', 'principal'): _dbz_principal_post,
    ('dragon-ball-z', 'secundario'): _dbz_secundario_post,
    ('dragon-ball-z', 'bloqueo'): _dbz_bloqueo_post,
    ('jujutsu-kaisen', 'principal'): _jujutsu_principal_post,
    ('jujutsu-kaisen', 'secundario'): _jujutsu_secundario_post,
    ('jujutsu-kaisen', 'bloqueo'): _jujutsu_bloqueo_post,
    ('naruto', 'principal'): _naruto_principal_post,
    ('naruto', 'secundario'): _naruto_secundario_post,
    ('naruto', 'bloqueo'): _naruto_bloqueo_post,
    ('one-piece', 'principal'): _op_principal_post,
    ('one-piece', 'secundario'): _op_secundario_post,
    ('one-piece', 'bloqueo'): _op_bloqueo_post,
    ('solo-leveling', 'principal'): _sl_principal_post,
    ('solo-leveling', 'secundario'): _sl_secundario_post,
    ('solo-leveling', 'bloqueo'): _sl_bloqueo_post,
    ('stranger-things', 'principal'): _st_principal_post,
    ('stranger-things', 'secundario'): _st_secundario_post,
    ('stranger-things', 'bloqueo'): _st_bloqueo_post,
    ('black-clover', 'principal'): _bc_principal_post,
    ('black-clover', 'secundario'): _bc_secundario_post,
    ('black-clover', 'bloqueo'): _bc_bloqueo_post,
    ('continente-demoniaco', 'principal'): _cd_principal_post,
    ('continente-demoniaco', 'secundario'): _cd_secundario_post,
    ('continente-demoniaco', 'bloqueo'): _cd_bloqueo_post,
    ('fittoa', 'principal'): _fittoa_principal_post,
    ('fittoa', 'secundario'): _fittoa_secundario_post,
    ('fittoa', 'bloqueo'): _fittoa_bloqueo_post,
    ('harry-potter', 'principal'): _hp_principal_post,
    ('harry-potter', 'secundario'): _hp_secundario_post,
    ('harry-potter', 'bloqueo'): _hp_bloqueo_post,
    ('hunter-x-hunter', 'principal'): _hxh_principal_post,
    ('hunter-x-hunter', 'secundario'): _hxh_secundario_post,
    ('hunter-x-hunter', 'bloqueo'): _hxh_bloqueo_post,
    ('spiderman-miles-morales', 'principal'): _sm_principal_post,
    ('spiderman-miles-morales', 'secundario'): _sm_secundario_post,
    ('spiderman-miles-morales', 'bloqueo'): _sm_bloqueo_post,
    ('terraza-michis', 'principal'): _michis_principal_post,
    ('terraza-michis', 'secundario'): _michis_secundario_post,
    ('terraza-michis', 'bloqueo'): _michis_bloqueo_post,
    ('salon-noah-maggie', 'principal'): _salon_principal_post,
    ('salon-noah-maggie', 'secundario'): _salon_secundario_post,
    ('salon-noah-maggie', 'bloqueo'): _salon_bloqueo_post,
}


def enriquecer_pre_lago(lz, hor=HOR):
    """Aplica detalles sobre la linea del horizonte antes de que render_lago refleje el paisaje."""
    ctx = _Ctx(lz, hor=hor)
    fn = _PRE_LAGO.get(ctx.key())
    if fn is not None:
        fn(ctx)


def enriquecer_post_escena(lz):
    """Aplica detalles finales tras el paisaje principal y antes de aplica_vineta."""
    ctx = _Ctx(lz)
    fn = _POST_ESCENA.get(ctx.key())
    if fn is not None:
        fn(ctx)
