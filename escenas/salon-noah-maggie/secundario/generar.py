#!/usr/bin/env python3
"""PixelZen Worlds - Salon de Noah y Maggie (Secundario): Cuadro Miro, Lampara y Posado Oficial."""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), 'src'))
from pz_lib import (  # noqa: E402
    Lienzo, W, H, aplica_vineta, dibuja_luna_estandar, dibuja_sol_estandar,
    dith, exporta_salida, exporta_sprites_si_aplica, mix,
    render_cielo, render_estrellas, render_nubes,
)

ARGS = [a for a in sys.argv[1:] if not a.startswith('--')]
ANIM = '--anim' in sys.argv
FASE = os.environ.get('PZ_FASE', 'noche')
SKYM = os.environ.get('PZ_SKY', 'normal')
random.seed(1702)

PALETAS = {
    'noche': dict(
        sky=['#050a16', '#0a1428', '#101f3a', '#182c4e', '#213c62', '#2c4d76', '#3a608a', '#4c759d', '#628cb0', '#27536a'],
        wall=('#46423d', '#3a3632', '#58524b', '#2b2824'),
        curtain=('#6b635e', '#827872', '#4c4642'),
        cabinet=('#989ba6', '#b2b5c0', '#70737e', '#cfd2dc'),
        vig=0.72,
        nube=['#1a2a46', '#24385a', '#304870', '#3f5a86', '#526f9c', '#132038'],
    ),
    'dorado': dict(
        sky=['#131838', '#252654', '#46346c', '#74487c', '#a65c7a', '#d67468', '#f2985e', '#fbbc5c', '#fde07e', '#fff4ba'],
        wall=('#a49484', '#8e7f70', '#bcab9a', '#6e6256'),
        curtain=('#c8b6aa', '#e2d0c4', '#9e8e84'),
        cabinet=('#c8c4be', '#e2ded8', '#9c9892', '#f4f0ea'),
        vig=0.84,
        nube=['#543456', '#724264', '#945670', '#b8707a', '#dc9286', '#3a2240'],
    ),
    'dia': dict(
        sky=['#1a4e9c', '#2966b8', '#3c80d0', '#549ae2', '#72b4ee', '#94ccf6', '#b8e0fa', '#daf0fc', '#eff8fc', '#fcf8e4'],
        wall=('#b8b0a6', '#a49c92', '#ccc4ba', '#847c72'),
        curtain=('#ddd2ca', '#f0e8e2', '#b8aca4'),
        cabinet=('#d4d6dc', '#eaecf0', '#a6a9b2', '#ffffff'),
        vig=0.92,
        nube=['#eef5fc', '#dceaf8', '#cadcf0', '#ffffff', '#e4eef8', '#b8cce2'],
    ),
}
PAL = PALETAS[FASE]

ESTRELLAS, VENTANAS, FAROLES, RUNAS, DESTELLOS, NUBES = [], [], [], [], [], []
CHIMENEA = None
lz = Lienzo()
put, over, disc, glow = lz.put, lz.over, lz.disc, lz.glow

render_cielo(lz, PAL['sky'], SKYM, FASE, hor=240, aurora_cols=('#4ade80', '#fde047'))
exporta_sprites_si_aplica(
    lz,
    lambda: dibuja_luna_estandar(lz, 104, 104, 38, halo='#93c5fd', base='#f8fafc', sombra='#cbd5e1', crater='#94a3b8', crater_hi='#cbd5e1'),
    lambda: dibuja_sol_estandar(lz, 104, 104, 24, halo='#fde68a', centro='#fffbeb', borde='#f59e0b', rayo='#fef08a'),
)
render_estrellas(lz, FASE, ANIM, ESTRELLAS, hor=210)

NUBES_DEF = [
    (74, 62, 54, PAL['nube'][1], 2),
    (118, 104, 48, PAL['nube'][2], 2),
]
render_nubes(lz, NUBES_DEF, NUBES, ANIM)


def rect(x0, y0, w, h, col):
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            put(x, y, col)


def thick_line(x0, y0, x1, y1, r, col):
    steps = max(abs(x1 - x0), abs(y1 - y0), 1)
    for k in range(steps + 1):
        cx = int(round(x0 + (x1 - x0) * k / steps))
        cy = int(round(y0 + (y1 - y0) * k / steps))
        disc(cx, cy, r, col)


# 1. Pared interior (ventana abierta a la izquierda x=24..148, y=28..236)
w0, w1, w2, w3 = PAL['wall']
WIN_X0, WIN_X1, WIN_Y0, WIN_Y1 = 24, 148, 28, 236
for y in range(0, 276):
    for x in range(0, W):
        if WIN_X0 <= x < WIN_X1 and WIN_Y0 <= y < WIN_Y1:
            continue
        c = w2 if x < 240 and y < 220 and dith(x, y, 0.30) else (w1 if y > 220 and dith(x, y, 0.40) else w0)
        put(x, y, c)

# Marco ventana + visillo suave a la derecha de la ventana
rect(WIN_X0 - 4, WIN_Y0 - 4, (WIN_X1 - WIN_X0) + 8, 5, '#252830')
rect(WIN_X0 - 4, WIN_Y1, (WIN_X1 - WIN_X0) + 8, 5, '#353944')
rect(WIN_X0 - 4, WIN_Y0, 5, WIN_Y1 - WIN_Y0, '#252830')
rect(WIN_X1, WIN_Y0, 5, WIN_Y1 - WIN_Y0, '#252830')

c0, c1, c2 = PAL['curtain']
for y in range(WIN_Y0 - 6, 276):
    for x in range(124, 156):
        stripe = (x % 7)
        col = c1 if stripe in (1, 2) else (c2 if stripe in (5, 6) else c0)
        put(x, y, col)

# 2. Cuadro estilo Miro enmarcado en negro en la pared (x=180..374, y=28..238)
PX0, PY0, PW, PH = 180, 28, 194, 210
rect(PX0, PY0, PW, PH, '#14161c')
rect(PX0 + 5, PY0 + 5, PW - 10, PH - 10, '#e5e0d6' if FASE == 'dia' else ('#d8ccb8' if FASE == 'dorado' else '#9a968e'))
# Papel interior ligeramente moteado
paper = '#ebe7de' if FASE == 'dia' else ('#dfd4c2' if FASE == 'dorado' else '#a6a198')
rect(PX0 + 9, PY0 + 9, PW - 18, PH - 18, paper)

# Trazos y circulos estilo Miro (basado en la foto!)
ink = '#181a20'
red = '#dc2626' if FASE != 'noche' else '#991b1b'
blue = '#2563eb' if FASE != 'noche' else '#1e40af'
green = '#16a34a' if FASE != 'noche' else '#166534'
yellow = '#eab308' if FASE != 'noche' else '#a16207'

# Circulo concentrado azul/rojo/negro arriba-izquierda del cuadro
disc(PX0 + 58, PY0 + 96, 28, blue)
disc(PX0 + 58, PY0 + 96, 21, paper)
disc(PX0 + 58, PY0 + 96, 15, green)
disc(PX0 + 58, PY0 + 96, 10, red)
disc(PX0 + 58, PY0 + 96, 5, yellow)

# Formas negras organicas y trazos
disc(PX0 + 56, PY0 + 52, 16, ink)
disc(PX0 + 54, PY0 + 52, 7, paper)
thick_line(PX0 + 30, PY0 + 48, PX0 + 90, PY0 + 130, 3, ink)
thick_line(PX0 + 90, PY0 + 130, PX0 + 150, PY0 + 110, 3, ink)
thick_line(PX0 + 118, PY0 + 42, PX0 + 144, PY0 + 168, 3, ink)
disc(PX0 + 122, PY0 + 70, 12, red)
disc(PX0 + 152, PY0 + 154, 11, yellow)
disc(PX0 + 104, PY0 + 158, 9, blue)
# Ojos / estrella negra de Miro
for dx in range(-8, 9):
    put(PX0 + 148 + dx, PY0 + 52, ink)
    put(PX0 + 148, PY0 + 52 + dx, ink)

# 3. Lamparita de pinza negra sobre el cuadro iluminando a Noah y Maggie
rect(274, 24, 14, 10, '#0f172a')
thick_line(281, 24, 294, 18, 2, '#1e293b')
thick_line(294, 18, 304, 48, 2, '#1e293b')
thick_line(304, 48, 294, 72, 2, '#1e293b')
# Cabezal de la lampara
disc(291, 77, 8, '#0f172a')
disc(290, 81, 5, '#fef08a' if FASE != 'dia' else '#cbd5e1')
if FASE != 'dia':
    glow(286, 118, 72, '#fde047', 0.24 if FASE == 'noche' else 0.16)
    glow(290, 82, 24, '#fffbeb', 0.45)
    if not ANIM:
        FAROLES.append([290, 82, 12])

# 4. Mueble blanco minimalista en primer plano (y=272..400)
cb0, cb1, cb2, cb3 = PAL['cabinet']
for y in range(272, H):
    for x in range(0, W):
        if y == 272:
            c = cb2
        elif y < 276:
            c = cb3
        elif y < 292:
            c = cb1 if dith(x, y, 0.35) else cb0
        elif y == 292:
            c = cb2
        else:
            c = cb0 if (x + y) % 11 != 0 else cb2
        put(x, y, c)

# 5. Noah (izquierda, mirando seria/entrecerrada) y Maggie (derecha, ojazos ambar) sobre el mueble blanco!
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from salon_sprites import SPR_MAGGIE_SIT, SPR_NOAH_SIT, draw_sprite_1x  # noqa: E402

draw_sprite_1x(lz, 204, 288, SPR_NOAH_SIT, fase=FASE, shadow_col='#2c2f3b', shadow_alpha=0.35)
draw_sprite_1x(lz, 344, 288, SPR_MAGGIE_SIT, fase=FASE, shadow_col='#2c2f3b', shadow_alpha=0.38)

try:
    import pz_detalles
    pz_detalles.enriquecer_post_escena(lz)
except ImportError:
    pass

aplica_vineta(lz, PAL['vig'])

out = ARGS[0] if ARGS else '.'
datos = dict(W=W, H=H, estrellas=ESTRELLAS, ventanas=VENTANAS, faroles=FAROLES, runas=RUNAS,
             chimenea=CHIMENEA, destellos=DESTELLOS, barca=None, luna=[86, 86, 26])
exporta_salida(lz, out, FASE, ANIM, NUBES, datos)
