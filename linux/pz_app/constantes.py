"""Constantes, rutas y utilidades de GSettings/estado para PixelZen Worlds Linux."""
import os
import subprocess
import time

from gi.repository import Gio

APP_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPO_ROOT = os.path.dirname(APP_DIR)

UUID = 'pixelzen@mosqui1988.github.io'
EXT_DIR = os.path.expanduser(f'~/.local/share/gnome-shell/extensions/{UUID}')
SCHEMA_DIR = os.path.join(EXT_DIR, 'schemas')
SCHEMA_ID = 'org.gnome.shell.extensions.pixelzen'
SVC_CICLO90 = 'pixelzen-ciclo90.service'
RELEASES_API = 'https://api.github.com/repos/davidlpizano/pixelzen-worlds/releases/latest'
RELEASES_URL = 'https://github.com/davidlpizano/pixelzen-worlds/releases'
WEB_URL_FALLBACK = 'https://davidlpizano.github.io/pixelzen-worlds/'
CLIMA_CACHE_PATH = os.path.expanduser('~/.config/pixelzen/clima_real.json')
UPDATE_CACHE_DIR = os.path.expanduser('~/.cache/pixelzen')

FASES = [('dia', '☀️ Día'), ('dorado', '🌅 Dorado'), ('noche', '🌙 Noche')]
MODOS = [
    ('90m', '🌗 Ciclo suave — Día y noche cada 90 min (Recomendado)'),
    ('real', '🕒 Hora real — Igual que el reloj de tu sistema'),
    ('demo', '⚡ Paseo rápido — Cambia en 90 segundos para probar'),
    ('fija', '🔒 Momento fijo — Elige tú Día, Atardecer o Noche'),
]
MODOS_CORTO = {'90m': 'Ciclo 90m', 'real': 'Hora real', 'demo': 'Pase rápido', 'fija': 'Hora fija'}
CLIMAS = [
    ('normal', '✨ Despejado (Original del mundo)'),
    ('lluvia', '🌧️ Lluvia suave en tiempo real'),
    ('tormenta', '⛈️ Tormenta con relámpagos'),
    ('nieve', '❄️ Nevadas suaves de invierno'),
    ('niebla', '🌫️ Niebla nocturna misteriosa'),
    ('ceniza', '🌋 Ceniza volcánica / brasas'),
    ('auto', '🤖 Automático por universo y clima real'),
]
ROTACIONES = [
    (0, '🔒 Desactivado — Mantener mundo elegido'),
    (5, '⏱️ Rotar cada 5 minutos'),
    (15, '⏱️ Rotar cada 15 minutos'),
    (30, '⏱️ Rotar cada 30 minutos'),
    (60, '🕒 Rotar cada hora'),
]
VARIANTES = [('principal', 'Principal'), ('secundaria', 'Secundaria'), ('bloqueo', 'Bloqueo')]

STATS_META = [
    ('hud-tiempo', '🕒 Reloj, fecha y nombre del mundo', 'Muestra la hora grande, la fecha en español y el escenario activo.', '21:34 · Fittoa'),
    ('hud-clima', '☀️ Clima real y órbita solar', 'Temperatura real, viento, elevación solar y fase atmosférica.', '☀ SOL +18° · DESPEJADO'),
    ('hud-sistema', '💻 Rendimiento del PC (CPU, RAM, Temp, Disco)', 'Barras visuales en tiempo real para controlar la carga del equipo.', '❖ CPU 12% RAM 48%'),
    ('hud-gpu', '🎮 GPU y motor gráfico', 'Tarjeta gráfica detectada, FPS activos y carga visual.', '▣ GPU · 8 FPS'),
    ('hud-red', '🌐 Conexión e Internet (Wi-Fi / IP / Velocidad)', 'Muestra tu red activa, IP local y tráfico de subida/bajada.', '◈ ETH 192.168.1.38'),
    ('hud-audio', '🎵 Música y banda sonora del mundo', 'Reproductores activos (Spotify/MPRIS) o BSO acorde al universo.', '♪ MÚSICA / BSO EN VIVO'),
    ('hud-dev', '🛠️ Información técnica / Programador', 'Nombre del equipo, repositorios Git y runtimes detectados.', '⚔ DEV · main'),
    ('hud-foco', '⏱️ Temporizador Zen / Sesión (Pomodoro)', 'Cuenta atrás de 25 minutos por ciclos y tiempo de sesión activa.', '⧖ ZEN 25:00'),
    ('hud-grimorio', '📖 Frase del universo (Grimorio)', 'Citas icónicas de la serie que rotan automáticamente.', '«Frase del mundo...»'),
]


def leer_version():
    """Lee la versión actual desde VERSION junto a la app o en la raíz del repo."""
    for vp in (os.path.join(APP_DIR, 'VERSION'), os.path.join(REPO_ROOT, 'VERSION')):
        if os.path.isfile(vp):
            try:
                txt = open(vp, 'r', encoding='utf-8').read().strip()
                if txt:
                    return txt
            except Exception:
                pass
    return '1.2.36'


VERSION_ACTUAL = leer_version()


def cargar_settings():
    """Carga Gio.Settings compilados de la extensión GNOME si están presentes."""
    if os.path.isfile(os.path.join(SCHEMA_DIR, 'gschemas.compiled')):
        src = Gio.SettingsSchemaSource.new_from_directory(SCHEMA_DIR, None, False)
        schema = src.lookup(SCHEMA_ID, True)
        if schema is not None:
            return Gio.Settings.new_full(schema, None, None)
    return None


def has_key(s, key):
    if not s:
        return False
    try:
        schema = s.props.settings_schema
        return bool(schema and schema.has_key(key))
    except Exception:
        return False


def get_str(s, key, default):
    if not has_key(s, key):
        return default
    try:
        return s.get_string(key)
    except Exception:
        return default


def get_bool(s, key, default):
    if not has_key(s, key):
        return default
    try:
        return s.get_boolean(key)
    except Exception:
        return default


def get_int(s, key, default):
    if not has_key(s, key):
        return default
    try:
        return s.get_int(key)
    except Exception:
        return default


def set_safe(s, kind, key, val):
    if not has_key(s, key):
        return
    try:
        if kind == 's':
            s.set_string(key, str(val))
        elif kind == 'b':
            s.set_boolean(key, bool(val))
        elif kind == 'i':
            s.set_int(key, int(val))
        elif kind == 'd':
            s.set_double(key, float(val))
    except Exception:
        pass


def extension_instalada():
    return os.path.isdir(EXT_DIR) and os.path.isfile(os.path.join(SCHEMA_DIR, 'gschemas.compiled'))


_EXT_ACTIVA_CACHE = {'t': 0.0, 'v': False}


def extension_activa(force=False):
    ahora = time.monotonic()
    if not force and ahora - _EXT_ACTIVA_CACHE['t'] < 10.0:
        return _EXT_ACTIVA_CACHE['v']
    res = False
    try:
        out = subprocess.run(
            ['gnome-extensions', 'info', UUID],
            capture_output=True, text=True, check=False,
        ).stdout
        for linea in out.splitlines():
            if 'State:' in linea or 'Estado:' in linea:
                res = ('ACTIVE' in linea.upper()) or ('ENABLED' in linea.upper()) or ('ACTIVA' in linea.upper())
                break
    except Exception:
        pass
    _EXT_ACTIVA_CACHE['t'] = ahora
    _EXT_ACTIVA_CACHE['v'] = res
    return res


def ciclo90_activo():
    try:
        res = subprocess.run(
            ['systemctl', '--user', 'is-active', SVC_CICLO90],
            capture_output=True, text=True, check=False,
        )
        return res.stdout.strip() == 'active'
    except Exception:
        return False
