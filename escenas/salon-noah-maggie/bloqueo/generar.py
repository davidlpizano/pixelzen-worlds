#!/usr/bin/env python3
"""PixelZen Worlds - Salon de Noah y Maggie (Bloqueo): Cojin Crema de Rombos y Siesta."""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), 'src'))
from pz_lib import (  # noqa: E402
    Lienzo, W, H, aplica_vineta, dibuja_luna_estandar, dibuja_sol_estandar,
    dith, exporta_salida, exporta_sprites_si_aplica,
    render_cielo, render_estrellas, render_nubes,
)

ARGS = [a for a in sys.argv[1:] if not a.startswith('--')]
ANIM = '--anim' in sys.argv
FASE = os.environ.get('PZ_FASE', 'noche')
SKYM = os.environ.get('PZ_SKY', 'normal')
random.seed(1703)

PALETAS = {
    'noche': dict(
        sky=['#040812', '#091224', '#0f1c34', '#162848', '#1e365c', '#28466e', '#345882', '#426b96', '#557faa', '#1f445c'],
        wall=('#262834', '#1e202b', '#323544'),
        cushion=('#7b705e', '#928571', '#5a5143', '#ab9e87'),
        rug=('#1b2230', '#273042', '#10151e'),
        floor=('#2e2016', '#3d2a1c', '#1e140d'),
        vig=0.70,
        nube=['#1a2a46', '#24385a', '#304870', '#3f5a86', '#526f9c', '#132038'],
    ),
    'dorado': dict(
        sky=['#131838', '#252654', '#46346c', '#74487c', '#a65c7a', '#d67468', '#f2985e', '#fbbc5c', '#fde07e', '#fff4ba'],
        wall=('#6c5d54', '#564942', '#827167'),
        cushion=('#bda88e', '#d6c1a6', '#917f6a', '#ebd7be'),
        rug=('#262e3e', '#354054', '#161b26'),
        floor=('#523520', '#69442a', '#382314'),
        vig=0.82,
        nube=['#543456', '#724264', '#945670', '#b8707a', '#dc9286', '#3a2240'],
    ),
    'dia': dict(
        sky=['#1a4e9c', '#2966b8', '#3c80d0', '#549ae2', '#72b4ee', '#94ccf6', '#b8e0fa', '#daf0fc', '#eff8fc', '#fcf8e4'],
        wall=('#9e978e', '#867f76', '#b6afa6'),
        cushion=('#cfc1aa', '#e6d8c1', '#a39580', '#f5ead6'),
        rug=('#2a3446', '#3b485e', '#1a202c'),
        floor=('#68442a', '#825636', '#482e1c'),
        vig=0.90,
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
render_estrellas(lz, FASE, ANIM, ESTRELLAS, hor=220)

NUBES_DEF = [
    (96, 52, 82, PAL['nube'][1], 2),
    (256, 42, 74, PAL['nube'][2], 2),
    (398, 66, 68, PAL['nube'][3], 2),
]
render_nubes(lz, NUBES_DEF, NUBES, ANIM)


def rect(x0, y0, w, h, col):
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            put(x, y, col)


# 1. Gran ventanal panoramico (abierto x=26..452, y=24..228)
w0, w1, w2 = PAL['wall']
for y in range(0, 268):
    for x in range(0, W):
        if 26 <= x < 452 and 24 <= y < 228:
            continue
        put(x, y, w1 if y > 230 and dith(x, y, 0.35) else w0)

rect(22, 20, 434, 5, '#1b1e26')
rect(22, 228, 434, 6, '#2b2f3a')
rect(22, 24, 5, 204, '#1b1e26')
rect(451, 24, 5, 204, '#1b1e26')
rect(168, 24, 4, 204, '#1b1e26')
rect(312, 24, 4, 204, '#1b1e26')

# Guirnalda calida en la parte superior del ventanal
for bx in range(48, 440, 42):
    put(bx, 30, '#fbbf24' if FASE != 'dia' else '#fef08a')
    put(bx, 31, '#fffbeb')
    if FASE != 'dia':
        glow(bx, 31, 8, '#f59e0b', 0.42 if FASE == 'noche' else 0.28)
        if not ANIM:
            FAROLES.append([bx, 31, 8])

# 2. Suelo de madera (y=268..400)
fl0, fl1, fl2 = PAL['floor']
for y in range(268, H):
    for x in range(0, W):
        plank = (y - 268) % 18
        put(x, y, fl2 if plank == 0 else (fl1 if (x + y) % 9 == 0 else fl0))

# 3. Gran cojin crema tejido con relieve de rombos (basado en la foto de Noah!) (x=48..324, y=274..394)
c0, c1, c2, c3 = PAL['cushion']
for y in range(274, 396):
    for x in range(46, 326):
        dx = (x - 186) / 140.0
        dy = (y - 335) / 60.0
        # Rectangulo muy redondeado
        if abs(dx) ** 3.2 + abs(dy) ** 3.2 <= 1.0:
            edge = abs(dx) ** 3.2 + abs(dy) ** 3.2 > 0.88
            if edge:
                put(x, y, c2)
            else:
                # Patron de rombos tejidos en relieve
                d1 = abs((x - y) % 34 - 17)
                d2 = abs((x + y) % 34 - 17)
                is_rib = (d1 <= 2) or (d2 <= 2)
                if is_rib:
                    put(x, y, c3 if (x + y) % 2 == 0 else c1)
                else:
                    put(x, y, c1 if dith(x, y, 0.35) and y < 335 else c0)

# 4. Alfombra gris pizarra a la derecha para Maggie panza arriba (x=344..606, y=278..392)
r0, r1, r2 = PAL['rug']
for y in range(278, 392):
    for x in range(344, 606):
        dx = (x - 475) / 130.0
        dy = (y - 335) / 56.0
        if dx * dx + dy * dy <= 1.0:
            edge = dx * dx + dy * dy > 0.88
            put(x, y, r2 if edge else (r1 if (x * 5 + y * 3) % 7 == 0 else r0))

# 5. Noah hecha bollito en el cojin de rombos y Maggie panza arriba en la alfombra
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from salon_sprites import SPR_MAGGIE_SPRAWL, SPR_NOAH_CURL, draw_sprite_1x  # noqa: E402

draw_sprite_1x(lz, 184, 344, SPR_NOAH_CURL, fase=FASE, shadow_col='#2c261e', shadow_alpha=0.35)
draw_sprite_1x(lz, 474, 360, SPR_MAGGIE_SPRAWL, fase=FASE, shadow_col='#080a10', shadow_alpha=0.40)

try:
    import pz_detalles
    pz_detalles.enriquecer_post_escena(lz)
except ImportError:
    pass

aplica_vineta(lz, PAL['vig'])

out = ARGS[0] if ARGS else '.'
datos = dict(W=W, H=H, estrellas=ESTRELLAS, ventanas=VENTANAS, faroles=FAROLES, runas=RUNAS,
             chimenea=CHIMENEA, destellos=DESTELLOS, barca=None, luna=[286, 86, 30])
exporta_salida(lz, out, FASE, ANIM, NUBES, datos)
