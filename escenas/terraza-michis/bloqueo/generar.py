#!/usr/bin/env python3
"""PixelZen Worlds - Terraza de los Michis (Bloqueo): Santuario de la Pelotita y Siesta Nocturna."""
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
random.seed(1603)

PALETAS = {
    'noche': dict(
        sky=['#040812', '#081022', '#0e1a34', '#162646', '#1e345a', '#28456e', '#365884', '#486c98', '#5c82ac', '#244b62'],
        hills=('#0a1420', '#112030', '#060c14'),
        fence=('#1a1210', '#291d18', '#100b09', '#3b2b22'),
        grass=('#163212', '#204619', '#2b5a20', '#0e220c', '#3a6e28'),
        wood=('#3c2416', '#563420', '#27170e', '#70452b'),
        cushion=('#121622', '#1e2436', '#090b12', '#334155'),
        sisal=('#705a3c', '#927852', '#52402a', '#ab9068'),
        gray_cat=('#363c46', '#4d5563', '#23272e', '#656f80', '#e6ecf5', '#cbd5e1', '#f59e0b', '#f4a4b8'),
        cream_cat=('#8b786c', '#a89486', '#69594f', '#c2afa2', '#eee6dc', '#d8cec2', '#f4a4b8', '#463832'),
        vig=0.70,
        nube=['#16243c', '#203250', '#2c4266', '#3a547c', '#4c6892', '#101c30'],
    ),
    'dorado': dict(
        sky=['#121634', '#222450', '#423068', '#704478', '#a25876', '#d27064', '#ee945a', '#f8b858', '#fcdc7a', '#fff2b6'],
        hills=('#201e32', '#322a48', '#141220'),
        fence=('#342016', '#4c2f20', '#20130c', '#68402c'),
        grass=('#2c5414', '#3c701c', '#4e8a24', '#1e3c0e', '#68a430'),
        wood=('#5d341c', '#7c4727', '#3c2010', '#9c5c34'),
        cushion=('#1a1c28', '#2a2e40', '#0e1018', '#475569'),
        sisal=('#9c7b4a', '#c29c62', '#755a34', '#dcb67a'),
        gray_cat=('#444954', '#5e6674', '#2c3038', '#788292', '#f4efe6', '#d8d0c4', '#f59e0b', '#f9a8b8'),
        cream_cat=('#a98e78', '#c6aa92', '#826b59', '#dec4ad', '#fbf4ea', '#e4d8ca', '#f49aa8', '#5c4638'),
        vig=0.80,
        nube=['#503052', '#6e3e60', '#90526c', '#b46c76', '#d88e82', '#36203c'],
    ),
    'dia': dict(
        sky=['#1a4e9c', '#2966b8', '#3c80d0', '#549ae2', '#72b4ee', '#94ccf6', '#b8e0fa', '#daf0fc', '#eff8fc', '#fcf8e4'],
        hills=('#284c66', '#3a6682', '#1b364a'),
        fence=('#3c291e', '#553a2b', '#261912', '#6e4d3a'),
        grass=('#386e18', '#4a8c20', '#5ea62a', '#285210', '#78be38'),
        wood=('#683b20', '#8a502c', '#452614', '#aa6538'),
        cushion=('#1e2432', '#30394e', '#10141c', '#475569'),
        sisal=('#aa8a56', '#ceb074', '#82673e', '#e4c88c'),
        gray_cat=('#484e5a', '#626a7a', '#30343c', '#7c8698', '#f8fafc', '#dce4ee', '#f59e0b', '#f9a8b8'),
        cream_cat=('#b29c8a', '#ccb6a4', '#8c7767', '#e2cebe', '#fcf8f2', '#e4dcd0', '#f49aa8', '#5e4a3d'),
        vig=0.88,
        nube=['#eef5fc', '#dceaf8', '#cadcf0', '#ffffff', '#e4eef8', '#b8cce2'],
    ),
}
PAL = PALETAS[FASE]

ESTRELLAS, VENTANAS, FAROLES, RUNAS, DESTELLOS, NUBES = [], [], [], [], [], []
CHIMENEA = None
lz = Lienzo()
put, over, disc, glow = lz.put, lz.over, lz.disc, lz.glow

render_cielo(lz, PAL['sky'], SKYM, FASE, aurora_cols=('#fde047', '#4ade80'))
exporta_sprites_si_aplica(
    lz,
    lambda: dibuja_luna_estandar(lz, 104, 104, 38, halo='#93c5fd', base='#f8fafc', sombra='#cbd5e1', crater='#94a3b8', crater_hi='#cbd5e1'),
    lambda: dibuja_sol_estandar(lz, 104, 104, 24, halo='#fde68a', centro='#fffbeb', borde='#f59e0b', rayo='#fef08a'),
)
render_estrellas(lz, FASE, ANIM, ESTRELLAS, hor=212)

if not ANIM:
    if FASE == 'noche':
        dibuja_luna_estandar(lz, 320, 74, 38, halo='#93c5fd', base='#f8fafc', sombra='#cbd5e1', crater='#94a3b8', crater_hi='#cbd5e1')
    elif FASE == 'dorado':
        dibuja_sol_estandar(lz, 320, 128, 24, halo='#fde68a', centro='#fffbeb', borde='#f59e0b', rayo='#fef08a')
    else:
        dibuja_sol_estandar(lz, 320, 74, 24, halo='#fde68a', centro='#ffffff', borde='#f59e0b', rayo='#fef08a')

NUBES_DEF = [
    (74, 48, 80, PAL['nube'][1], 2),
    (240, 38, 72, PAL['nube'][2], 2),
    (386, 54, 70, PAL['nube'][3], 2),
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


# Fondo de valla y cesped ceremonial
r_sky = Ruido(43, 64)
h_dk, h_md, h_sh = PAL['hills']
for x in range(W):
    hy = int(202 - 14 * fbm(r_sky, x * 0.015))
    for y in range(hy, 234):
        put(x, y, h_sh if y < hy + 3 else h_dk)

f_dk, f_md, f_sh, f_hi = PAL['fence']
for y in range(218, 266):
    for x in range(W):
        if x % 6 == 0:
            put(x, y, f_sh)
        elif x % 6 == 1:
            put(x, y, f_hi if y % 7 != 0 else f_md)
        else:
            put(x, y, f_md if (x + y) % 3 else f_dk)
for ry in (224, 258):
    for x in range(W):
        put(x, ry, f_sh)
        put(x, ry + 1, f_hi)

# Cesped
g_dk, g_md, g_hi, g_sh, g_bt = PAL['grass']
rng_g = random.Random(1610)
for y in range(266, H):
    prof = (y - 266) / float(H - 266)
    for x in range(W):
        n = rng_g.random()
        c = g_sh if y < 270 else (g_bt if n < 0.14 else (g_hi if n < 0.44 else (g_md if n < 0.78 else g_dk)))
        put(x, y, c)
        if prof > 0.35 and (x * 13 + y * 7) % 23 == 0 and y > 270:
            put(x, y - 1, g_bt)

# Plataforma de tarima de madera central (x=140..500, y=336..400)
w_dk, w_md, w_sh, w_hi = PAL['wood']
for y in range(340, H):
    for x in range(130, 510):
        if x in (130, 131, 508, 509) or y in (340, 341):
            put(x, y, w_sh)
            continue
        ph = (y - 340) % 15
        put(x, y, w_sh if ph == 0 else (w_hi if ph == 1 else (w_dk if (x + y) % 10 == 0 else w_md)))

# Farol calido en esquina de la tarima (x=176, y=310)
for y in range(312, 340):
    for x in range(166, 187):
        edge = x in (166, 167, 185, 186) or y in (312, 313, 338, 339)
        put(x, y, '#1e293b' if edge else ('#fef08a' if FASE != 'dia' else '#e2e8f0'))
for dx in range(-12, 13):
    put(176 + dx, 311, '#0f172a')
    if abs(dx) < 9:
        put(176 + dx, 309, '#1e293b')
if FASE != 'dia':
    glow(176, 326, 26, '#fbbf24', 0.42 if FASE == 'noche' else 0.28)
    if not ANIM:
        FAROLES.append([176, 326, 12])

# Cojin oscuro ceremonial en el centro (x=320, y=326) + pelotita multicolor arriba
c0, c1, c2, c3 = PAL['cushion']
ellipse(320, 332, 54, 15, c2)
ellipse(320, 328, 50, 13, c0)
ellipse(320, 325, 44, 10, c1)
ellipse(320, 322, 34, 6, c3)

# Huellitas rúnicas luminosas en el borde del cojín
for px_r, py_r in ((280, 328), (360, 328), (320, 344)):
    put(px_r, py_r, '#fde047')
    put(px_r - 1, py_r - 2, '#fef08a')
    put(px_r + 1, py_r - 2, '#fef08a')
    if not ANIM:
        RUNAS.append([px_r, py_r])

# Pelotita multicolor ceremonial (x=320, y=314, radio 12)
ellipse(321, 322, 13, 5, '#070a12', 0.5)
ball_cols = ['#ef4444', '#facc15', '#22c55e', '#ec4899', '#3b82f6', '#fb923c']
for dy in range(-12, 13):
    for dx in range(-12, 13):
        d2 = dx * dx + dy * dy
        if d2 <= 140:
            col = ball_cols[((dx + 12) // 7 + ((dy + 12) // 7) * 2) % len(ball_cols)]
            if d2 > 110 or dy > 6:
                col = mix(col, '#111827', 0.35)
            elif dx < -3 and dy < -3:
                col = mix(col, '#ffffff', 0.25)
            put(320 + dx, 312 + dy, col)
glow(320, 312, 18, '#fde047', 0.22 if FASE != 'dia' else 0.08)

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from michis_sprites import SPR_CREAM_SLEEP, SPR_GRAY_SLEEP, draw_sprite_1x  # noqa: E402

# Ambos michis acurrucados durmiendo juntos a ambos lados del cojín
draw_sprite_1x(lz, 232, 338, SPR_CREAM_SLEEP, fase=FASE)
draw_sprite_1x(lz, 408, 338, SPR_GRAY_SLEEP, fase=FASE)

# Poste rascador detras a la derecha (x=462, y=236..308)
s0, s1, s2, s3 = PAL['sisal']
for y in range(238, 306):
    for x in range(454, 472):
        put(x, y, s2 if (x in (454, 471) or y % 3 == 0) else (s3 if x < 461 else s1))
ellipse(463, 238, 16, 5, c1)

try:
    import pz_detalles
    pz_detalles.enriquecer_post_escena(lz)
except ImportError:
    pass

aplica_vineta(lz, PAL['vig'])

out = ARGS[0] if ARGS else '.'
datos = dict(W=W, H=H, estrellas=ESTRELLAS, ventanas=VENTANAS, faroles=FAROLES, runas=RUNAS,
             chimenea=CHIMENEA, destellos=DESTELLOS, barca=None, luna=[320, 74, 38])
exporta_salida(lz, out, FASE, ANIM, NUBES, datos)
