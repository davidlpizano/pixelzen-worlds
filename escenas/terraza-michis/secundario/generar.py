#!/usr/bin/env python3
"""PixelZen Worlds - Terraza de los Michis (Secundario): Torre Rascador de Sisal y Juego."""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), 'src'))
from pz_lib import (  # noqa: E402
    Lienzo, Ruido, W, H, aplica_vineta, dibuja_luna_estandar, dibuja_sol_estandar,
    dith, exporta_salida, exporta_sprites_si_aplica, fbm, mix,
    render_cielo, render_estrellas, render_nubes,
)

ARGS = [a for a in sys.argv[1:] if not a.startswith('--')]
ANIM = '--anim' in sys.argv
FASE = os.environ.get('PZ_FASE', 'noche')
SKYM = os.environ.get('PZ_SKY', 'normal')
random.seed(1602)

PALETAS = {
    'noche': dict(
        sky=['#050a16', '#0a1428', '#101f3a', '#182c4e', '#213c62', '#2c4d76', '#3a608a', '#4c759d', '#628cb0', '#27536a'],
        hills=('#0b1622', '#122234', '#070e18'),
        fence=('#1d1512', '#2d211b', '#120d0b', '#3f2e25'),
        grass=('#183614', '#224a1b', '#2e6022', '#11270e', '#3d742b'),
        wood=('#3c2416', '#563420', '#27170e', '#70452b'),
        plush=('#141822', '#222836', '#0a0c12', '#334155'),
        sisal=('#705a3c', '#927852', '#52402a', '#ab9068'),
        pot=('#5c2d1c', '#7c3f28', '#3c1c10', '#2e6f34', '#4ade80'),
        gray_cat=('#363c46', '#4d5563', '#23272e', '#656f80', '#e6ecf5', '#cbd5e1', '#f59e0b', '#fde047', '#f4a4b8'),
        cream_cat=('#8b786c', '#a89486', '#69594f', '#c2afa2', '#eee6dc', '#d8cec2', '#f4a4b8', '#463832'),
        vig=0.72,
        nube=['#1a2a46', '#24385a', '#304870', '#3f5a86', '#526f9c', '#132038'],
    ),
    'dorado': dict(
        sky=['#131838', '#252654', '#46346c', '#74487c', '#a65c7a', '#d67468', '#f2985e', '#fbbc5c', '#fde07e', '#fff4ba'],
        hills=('#232036', '#362e4c', '#161424'),
        fence=('#362218', '#4e3122', '#22150e', '#6c4430'),
        grass=('#2e5816', '#3e741e', '#528e26', '#20400f', '#6ca832'),
        wood=('#5d341c', '#7c4727', '#3c2010', '#9c5c34'),
        plush=('#1c202c', '#2d3446', '#0e1118', '#475569'),
        sisal=('#9c7b4a', '#c29c62', '#755a34', '#dcb67a'),
        pot=('#7c3a22', '#a65232', '#4c2214', '#3f8a36', '#86efac'),
        gray_cat=('#444954', '#5e6674', '#2c3038', '#788292', '#f4efe6', '#d8d0c4', '#f59e0b', '#fef08a', '#f9a8b8'),
        cream_cat=('#a98e78', '#c6aa92', '#826b59', '#dec4ad', '#fbf4ea', '#e4d8ca', '#f49aa8', '#5c4638'),
        vig=0.82,
        nube=['#543456', '#724264', '#945670', '#b8707a', '#dc9286', '#3a2240'],
    ),
    'dia': dict(
        sky=['#1a4e9c', '#2966b8', '#3c80d0', '#549ae2', '#72b4ee', '#94ccf6', '#b8e0fa', '#daf0fc', '#eff8fc', '#fcf8e4'],
        hills=('#2a4e68', '#3c6884', '#1d384c'),
        fence=('#3c291e', '#553a2b', '#261912', '#6e4d3a'),
        grass=('#386e18', '#4a8c20', '#5ea62a', '#285210', '#78be38'),
        wood=('#683b20', '#8a502c', '#452614', '#aa6538'),
        plush=('#1e2432', '#30394e', '#10141c', '#475569'),
        sisal=('#aa8a56', '#ceb074', '#82673e', '#e4c88c'),
        pot=('#8c4228', '#b85c3a', '#542616', '#429a3a', '#4ade80'),
        gray_cat=('#484e5a', '#626a7a', '#30343c', '#7c8698', '#f8fafc', '#dce4ee', '#f59e0b', '#fde047', '#f9a8b8'),
        cream_cat=('#b29c8a', '#ccb6a4', '#8c7767', '#e2cebe', '#fcf8f2', '#e4dcd0', '#f49aa8', '#5e4a3d'),
        vig=0.90,
        nube=['#eef5fc', '#dceaf8', '#cadcf0', '#ffffff', '#e4eef8', '#b8cce2'],
    ),
}
PAL = PALETAS[FASE]

ESTRELLAS, VENTANAS, FAROLES, RUNAS, DESTELLOS, NUBES = [], [], [], [], [], []
CHIMENEA = None
lz = Lienzo()
put, over, disc, glow = lz.put, lz.over, lz.disc, lz.glow

render_cielo(lz, PAL['sky'], SKYM, FASE, aurora_cols=('#4ade80', '#fde047'))
exporta_sprites_si_aplica(
    lz,
    lambda: dibuja_luna_estandar(lz, 104, 104, 38, halo='#93c5fd', base='#f8fafc', sombra='#cbd5e1', crater='#94a3b8', crater_hi='#cbd5e1'),
    lambda: dibuja_sol_estandar(lz, 104, 104, 24, halo='#fde68a', centro='#fffbeb', borde='#f59e0b', rayo='#fef08a'),
)
render_estrellas(lz, FASE, ANIM, ESTRELLAS, hor=212)

NUBES_DEF = [
    (82, 46, 84, PAL['nube'][1], 2),
    (254, 38, 76, PAL['nube'][2], 2),
    (404, 56, 70, PAL['nube'][3], 2),
]
render_nubes(lz, NUBES_DEF, NUBES, ANIM)


def ellipse(cx, cy, rx, ry, col, alpha=1.0):
    rx2, ry2 = max(1.0, float(rx * rx)), max(1.0, float(ry * ry))
    for dy in range(-int(ry) - 1, int(ry) + 2):
        for dx in range(-int(rx) - 1, int(rx) + 2):
            if (dx * dx) / rx2 + (dy * dy) / ry2 <= 1.0:
                if alpha >= 0.99:
                    put(int(round(cx + dx)), int(round(cy + dy)), col)
                else:
                    over(int(round(cx + dx)), int(round(cy + dy)), col, alpha)


def rect(x0, y0, w, h, col):
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            put(x, y, col)


# Horizonte de copas de arboles y valla de listones
r_sky = Ruido(42, 64)
h_dk, h_md, h_sh = PAL['hills']
for x in range(W):
    hy = int(200 - 16 * fbm(r_sky, x * 0.014))
    for y in range(hy, 232):
        put(x, y, h_sh if y < hy + 3 else (h_md if (x + y) % 5 == 0 else h_dk))

f_dk, f_md, f_sh, f_hi = PAL['fence']
for y in range(218, 268):
    for x in range(W):
        if x % 6 == 0:
            put(x, y, f_sh)
        elif x % 6 == 1:
            put(x, y, f_hi if y % 7 != 0 else f_md)
        else:
            put(x, y, f_md if (x + y) % 3 else f_dk)
for ry in (224, 260):
    for x in range(W):
        put(x, ry, f_sh)
        put(x, ry + 1, f_hi)

# Cesped de la terraza (y=268..400)
g_dk, g_md, g_hi, g_sh, g_bt = PAL['grass']
rng_g = random.Random(1608)
for y in range(268, H):
    prof = (y - 268) / float(H - 268)
    for x in range(W):
        n = rng_g.random()
        if y < 272:
            c = g_sh
        elif n < 0.14 * (0.5 + prof):
            c = g_bt
        elif n < 0.45:
            c = g_hi if dith(x, y, 0.4 + prof * 0.3) else g_md
        elif n < 0.78:
            c = g_md
        else:
            c = g_dk
        put(x, y, c)
        if prof > 0.3 and (x * 11 + y * 5) % 21 == 0 and y > 272:
            put(x, y - 1, g_bt)

# Sendero de tarima de madera a la derecha-abajo (x=460..640, y=330..400)
w_dk, w_md, w_sh, w_hi = PAL['wood']
for y in range(330, H):
    x_start = int(500 - (y - 330) * 0.45)
    for x in range(x_start, W):
        if x <= x_start + 2 or y <= 331:
            put(x, y, w_sh)
            continue
        ph = (y - 330) % 14
        put(x, y, w_sh if ph == 0 else (w_hi if ph == 1 else (w_dk if (x + y) % 9 == 0 else w_md)))

# Maceta de barro con planta verde junto a la valla (x=76, y=248)
p_dk, p_md, p_sh, lf1, lf2 = PAL['pot']
for dy in range(22):
    w_p = 14 - dy // 4
    for dx in range(-w_p, w_p + 1):
        put(76 + dx, 250 + dy, p_sh if abs(dx) >= w_p - 1 else (p_md if dx < 0 else p_dk))
rect(60, 246, 33, 5, p_md)
# Hojas frondosas
for lx, ly, rx, ry in ((64, 232, 9, 12), (76, 224, 10, 14), (88, 234, 9, 11), (70, 238, 8, 9), (83, 240, 8, 9)):
    ellipse(lx, ly, rx, ry, lf1)
    ellipse(lx - 2, ly - 3, max(3, rx - 4), max(3, ry - 5), lf2)

# TORRE RASCADOR DE DOS NIVELES (x=150..278, y=148..320)
pl0, pl1, pl2, pl3 = PAL['plush']
s0, s1, s2, s3 = PAL['sisal']
# Sombra base
ellipse(214, 322, 64, 14, '#081407', 0.45)
# Base acolchada
rect(156, 306, 116, 14, pl0)
rect(158, 304, 112, 4, pl1)
# Cueva / cubil inferior
rect(164, 260, 56, 44, pl1)
rect(164, 258, 56, 4, pl3)
ellipse(192, 286, 14, 14, pl2)  # abertura oscura
# Postes de cuerda sisal
for px0 in (232, 178):
    y_top_p = 208 if px0 == 232 else 172
    y_bot_p = 304 if px0 == 232 else 258
    for y in range(y_top_p, y_bot_p):
        for x in range(px0, px0 + 18):
            if x == px0 or x == px0 + 17:
                put(x, y, s2)
            elif y % 3 == 0:
                put(x, y, s2 if x > px0 + 11 else s0)
            else:
                put(x, y, s3 if x < px0 + 7 else s1)
# Plataforma intermedia y plataforma superior
rect(210, 204, 64, 8, pl1)
rect(210, 202, 64, 3, pl3)
rect(156, 166, 66, 8, pl1)
rect(156, 164, 66, 3, pl3)
# Cuerda con pompon colgante de la plataforma intermedia
for y in range(212, 232):
    put(262, y, s3)
ellipse(262, 235, 5, 5, '#fef08a')

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from michis_sprites import SPR_CREAM_PLAY, SPR_GRAY_SIT, draw_sprite_1x  # noqa: E402

# MICHI GRIS sentado majestuoso en la plataforma superior mirando la terraza (x=189, y=168)
draw_sprite_1x(lz, 189, 171, SPR_GRAY_SIT, fase=FASE, shadow_col=None)

# MICHI CREMA jugando sobre el cesped con la pelotita multicolor (x=340, y=340)
draw_sprite_1x(lz, 340, 340, SPR_CREAM_PLAY, fase=FASE)

# Pelotita multicolor delante de la patita del michi crema (x=292, y=328)
ellipse(293, 335, 9, 4, '#081407', 0.45)
ball_cols = ['#ef4444', '#facc15', '#22c55e', '#ec4899', '#3b82f6', '#fb923c']
for dy in range(-8, 9):
    for dx in range(-8, 9):
        if dx * dx + dy * dy <= 64:
            col = ball_cols[((dx + 8) // 5 + ((dy + 8) // 5) * 2) % len(ball_cols)]
            if dy > 4:
                col = mix(col, '#111827', 0.35)
            put(292 + dx, 328 + dy, col)

# Guirnalda en valla
for bx in range(34, 444, 44):
    put(bx, 222, '#fbbf24' if FASE != 'dia' else '#fef08a')
    put(bx, 223, '#fffbeb')
    if FASE != 'dia':
        glow(bx, 223, 6, '#f59e0b', 0.38 if FASE == 'noche' else 0.25)
        if not ANIM:
            FAROLES.append([bx, 223, 6])

try:
    import pz_detalles
    pz_detalles.enriquecer_post_escena(lz)
except ImportError:
    pass

aplica_vineta(lz, PAL['vig'])

out = ARGS[0] if ARGS else '.'
datos = dict(W=W, H=H, estrellas=ESTRELLAS, ventanas=VENTANAS, faroles=FAROLES, runas=RUNAS,
             chimenea=CHIMENEA, destellos=DESTELLOS, barca=None, luna=[360, 62, 38])
exporta_salida(lz, out, FASE, ANIM, NUBES, datos)
