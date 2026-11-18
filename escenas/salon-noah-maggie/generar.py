#!/usr/bin/env python3
"""PixelZen Worlds - Salon de Noah y Maggie (Principal): Mueble, Tele Breaking Bad y Ventanal."""
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
random.seed(1701)

PALETAS = {
    'noche': dict(
        sky=['#050a16', '#0a1428', '#101f3a', '#182c4e', '#213c62', '#2c4d76', '#3a608a', '#4c759d', '#628cb0', '#27536a'],
        wall=('#3a352f', '#2f2b26', '#4a433b', '#221f1c'),
        frame=('#171a22', '#252934', '#0d0f14'),
        curtain=('#484c5c', '#5b6074', '#343845'),
        wood=('#63472e', '#7c5a3b', '#493320', '#966f4b'),
        top=('#14161c', '#1e222b', '#0a0b0e', '#2d323e'),
        vig=0.72,
        nube=['#1a2a46', '#24385a', '#304870', '#3f5a86', '#526f9c', '#132038'],
    ),
    'dorado': dict(
        sky=['#131838', '#252654', '#46346c', '#74487c', '#a65c7a', '#d67468', '#f2985e', '#fbbc5c', '#fde07e', '#fff4ba'],
        wall=('#8e7b68', '#786655', '#a8927c', '#5a4b3d'),
        frame=('#252126', '#383238', '#141216'),
        curtain=('#a4948a', '#c2b0a4', '#7e7068'),
        wood=('#966a44', '#b48256', '#724f32', '#cc986a'),
        top=('#181920', '#242630', '#0e0f14', '#383b48'),
        vig=0.84,
        nube=['#543456', '#724264', '#945670', '#b8707a', '#dc9286', '#3a2240'],
    ),
    'dia': dict(
        sky=['#1a4e9c', '#2966b8', '#3c80d0', '#549ae2', '#72b4ee', '#94ccf6', '#b8e0fa', '#daf0fc', '#eff8fc', '#fcf8e4'],
        wall=('#9a8f82', '#877c70', '#b0a597', '#6a6056'),
        frame=('#262932', '#3a3f4c', '#16181e'),
        curtain=('#c8c2ba', '#e2dcd4', '#9e978f'),
        wood=('#a87a50', '#c49264', '#825c3a', '#d8a878'),
        top=('#1a1c22', '#262932', '#0e1014', '#3c404d'),
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
render_estrellas(lz, FASE, ANIM, ESTRELLAS, hor=220)

if not ANIM:
    if FASE == 'noche':
        dibuja_luna_estandar(lz, 146, 78, 28, halo='#93c5fd', base='#f8fafc', sombra='#cbd5e1', crater='#94a3b8', crater_hi='#cbd5e1')
    elif FASE == 'dorado':
        dibuja_sol_estandar(lz, 146, 134, 19, halo='#fde68a', centro='#fffbeb', borde='#f59e0b', rayo='#fef08a')
    else:
        dibuja_sol_estandar(lz, 146, 78, 19, halo='#fde68a', centro='#ffffff', borde='#f59e0b', rayo='#fef08a')

NUBES_DEF = [
    (78, 56, 62, PAL['nube'][1], 2),
    (176, 92, 54, PAL['nube'][2], 2),
]
render_nubes(lz, NUBES_DEF, NUBES, ANIM)


def rect(x0, y0, w, h, col):
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            put(x, y, col)


# 1. Pared interior del salon (deja abierto el ventanal izquierdo x=28..212, y=28..224)
w0, w1, w2, w3 = PAL['wall']
WIN_X0, WIN_X1, WIN_Y0, WIN_Y1 = 28, 212, 28, 224
for y in range(0, 276):
    for x in range(0, W):
        if WIN_X0 <= x < WIN_X1 and WIN_Y0 <= y < WIN_Y1:
            continue
        # Gradiente suave hacia la ventana y parte alta
        c = w2 if (x < 260 and y < 220 and dith(x, y, 0.35)) else (w1 if y > 220 and dith(x, y, 0.45) else w0)
        if FASE == 'dorado' and x < 310 and y < 230 and dith(x, y, 0.18):
            c = mix(c, '#f59e0b', 0.22)
        put(x, y, c)

# Reflejo sutil en cristal del ventanal (sin tapar el cielo en modo corte)
if SKYM == 'normal':
    for y in range(WIN_Y0, WIN_Y1):
        for x in range(WIN_X0, WIN_X1):
            if (x - y) in (-42, -41, 14, 15):
                over(x, y, '#e0f2fe', 0.14)

# Marco del ventanal y parteluz
f0, f1, f2 = PAL['frame']
rect(WIN_X0 - 4, WIN_Y0 - 4, (WIN_X1 - WIN_X0) + 8, 5, f0)
rect(WIN_X0 - 4, WIN_Y1, (WIN_X1 - WIN_X0) + 8, 6, f1)
rect(WIN_X0 - 4, WIN_Y0, 5, WIN_Y1 - WIN_Y0, f0)
rect(WIN_X1, WIN_Y0, 5, WIN_Y1 - WIN_Y0, f0)
rect(118, WIN_Y0, 4, WIN_Y1 - WIN_Y0, f2)
rect(WIN_X0, 140, WIN_X1 - WIN_X0, 3, f2)

# Cortina lateral suave a la izquierda del ventanal
c0, c1, c2 = PAL['curtain']
for y in range(WIN_Y0 - 6, WIN_Y1 + 20):
    fold_w = 24 + int(math.sin(y * 0.08) * 3)
    for x in range(WIN_X0 - 8, WIN_X0 + fold_w):
        stripe = (x % 7)
        col = c1 if stripe in (1, 2) else (c2 if stripe in (5, 6) else c0)
        put(x, y, col)

# 2. Balda superior de madera con libros y plantita (x=244..450, y=26..42)
wd0, wd1, wd2, wd3 = PAL['wood']
rect(246, 36, 202, 7, wd0)
rect(246, 36, 202, 2, wd3)
rect(246, 42, 202, 2, wd2)
# Soportes de balda
rect(266, 44, 5, 10, f0)
rect(424, 44, 5, 10, f0)
# Libros decorativos y macetita en la balda
for bx, bw, bh, bc in ((256, 7, 18, '#dc2626'), (264, 6, 16, '#2563eb'), (271, 8, 19, '#d97706'), (280, 6, 15, '#16a34a')):
    rect(bx, 36 - bh, bw, bh, bc if FASE != 'noche' else mix(bc, '#0f172a', 0.45))
    rect(bx, 36 - bh, 1, bh, wd2)
# Macetita con hojas
rect(410, 24, 14, 12, '#9a4428')
for lx, ly, r in ((412, 20, 5), (419, 18, 6), (425, 21, 5)):
    disc(lx, ly, r, '#2e7d32' if FASE != 'noche' else '#1a4a22')
    disc(lx - 1, ly - 1, max(2, r - 2), '#4ade80' if FASE != 'noche' else '#2c6b3a')

# 3. Televisor en la pared mostrando Breaking Bad T4:E5 'Escopeta' (x=242..454, y=68..198)
TV_X0, TV_Y0, TV_W, TV_H = 242, 68, 212, 126
# Soporte TV
rect(334, TV_Y0 + TV_H, 28, 22, f2)
rect(316, TV_Y0 + TV_H + 18, 64, 5, f0)
# Marco TV
rect(TV_X0, TV_Y0, TV_W, TV_H, f2)
rect(TV_X0 + 1, TV_Y0 + 1, TV_W - 2, TV_H - 2, f0)
# Pantalla (x=246..450, y=72..190)
SX0, SY0, SW, SH = TV_X0 + 4, TV_Y0 + 4, TV_W - 8, TV_H - 8
for y in range(SY0, SY0 + SH):
    for x in range(SX0, SX0 + SW):
        rx, ry = x - SX0, y - SY0
        # Escena cocina/desierto calida de Breaking Bad
        if ry < 64:
            if rx < 76:
                c = '#84745c' if (rx // 18 + ry // 16) % 2 == 0 else '#6e604c'
            elif rx < 138:
                c = '#c9b48e' if ry > 12 else '#a4906e'
            else:
                c = '#b8a07a'
        else:
            c = '#5c4d3e' if ry < 86 else '#3b3228'
        if FASE == 'noche':
            c = mix(c, '#ffffff', 0.08)
        put(x, y, c)
# Silueta de Jesse/Walter en la cocina de la TV
rect(SX0 + 142, SY0 + 22, 18, 18, '#d4a682')  # cabeza
rect(SX0 + 144, SY0 + 19, 14, 5, '#5c3c24')   # pelo/perilla
rect(SX0 + 132, SY0 + 40, 38, 44, '#94a3b8')  # camiseta
rect(SX0 + 138, SY0 + 42, 26, 40, '#cbd5e1')
# Encimera y cafetera en TV
rect(SX0 + 84, SY0 + 74, 118, 12, '#7c6248')
rect(SX0 + 114, SY0 + 60, 14, 14, '#e2e8f0')
# Logo verde pixelado "Breaking Bad" a la izquierda de la TV + barra de progreso roja abajo
rect(SX0 + 14, SY0 + 44, 14, 12, '#15803d')
rect(SX0 + 29, SY0 + 50, 12, 10, '#166534')
rect(SX0 + 16, SY0 + 47, 8, 2, '#dcfce7')
rect(SX0 + 31, SY0 + 53, 7, 2, '#dcfce7')
# Subtitulo & barra roja
rect(SX0 + 56, SY0 + 96, 86, 4, '#f8fafc')
rect(SX0 + 10, SY0 + 106, SW - 20, 3, '#475569')
rect(SX0 + 10, SY0 + 106, 134, 3, '#ef4444')
# Brillo ambiente de la tele en pared/mueble de noche
if FASE != 'dia':
    glow(348, 132, 92, '#22c55e', 0.14 if FASE == 'noche' else 0.08)
    glow(348, 132, 74, '#fde68a', 0.18 if FASE == 'noche' else 0.10)

# 4. Mueble de salon en primer plano (superficie oscura y=262..288 + madera roble y=288..400)
tp0, tp1, tp2, tp3 = PAL['top']
# Superficie superior oscura con ligera perspectiva (y=260..286)
for y in range(260, 287):
    t = (y - 260) / 26.0
    for x in range(0, W):
        if y >= 283:
            c = tp2 if y == 286 else tp3
        elif y == 260:
            c = tp2
        else:
            c = mix(tp0, tp1, t)
            if x > 220 and x < 480 and FASE != 'dia' and dith(x, y, 0.25):
                c = mix(c, '#fde68a', 0.09)
        put(x, y, c)

# Frontal de madera roble del mueble (y=287..400)
for y in range(287, H):
    for x in range(0, W):
        if x > 454 and 298 <= y < 386:
            # Hueco abierto derecho con libros y router con LEDs verdes
            put(x, y, '#14151a')
            continue
        grain = ((x * 3 + y // 5) % 17 == 0)
        c = wd2 if grain else (wd1 if (x // 28) % 2 == 0 and dith(x, y, 0.25) else wd0)
        if x in (160, 318, 452):
            c = wd2
        put(x, y, c)

# Libros y router en el hueco derecho del mueble
for bx, bw, bh, bc in ((464, 14, 62, '#dc2626'), (480, 12, 58, '#eab308'), (494, 14, 64, '#2563eb')):
    rect(bx, 384 - bh, bw, bh, bc if FASE != 'noche' else mix(bc, '#0f172a', 0.45))
    rect(bx + 2, 384 - bh + 8, bw - 4, 4, '#f8fafc')
# Router negro con luces LED
rect(522, 368, 76, 14, '#0f172a')
for lx in range(532, 580, 8):
    put(lx, 374, '#4ade80')
    put(lx + 1, 374, '#4ade80')
    if FASE != 'dia' and not ANIM:
        RUNAS.append([lx, 374])

# 5. Noah y Maggie sobre el mueble!
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from salon_sprites import SPR_MAGGIE_LEDGE, SPR_NOAH_LOAF, draw_sprite_1x  # noqa: E402

# Noah en modo panecillo a la izquierda sobre el mueble (cx=144, by=280)
draw_sprite_1x(lz, 144, 280, SPR_NOAH_LOAF, fase=FASE, shadow_col='#090b10', shadow_alpha=0.42)

# Maggie tumbada sobre el mueble con su patita blanca colgando por el borde frontal (cx=354, by=306)
draw_sprite_1x(lz, 354, 306, SPR_MAGGIE_LEDGE, fase=FASE, shadow_col='#090b10', shadow_alpha=0.45)

try:
    import pz_detalles
    pz_detalles.enriquecer_post_escena(lz)
except ImportError:
    pass

aplica_vineta(lz, PAL['vig'])

out = ARGS[0] if ARGS else '.'
datos = dict(W=W, H=H, estrellas=ESTRELLAS, ventanas=VENTANAS, faroles=FAROLES, runas=RUNAS,
             chimenea=CHIMENEA, destellos=DESTELLOS, barca=None, luna=[146, 78, 28])
exporta_salida(lz, out, FASE, ANIM, NUBES, datos)
