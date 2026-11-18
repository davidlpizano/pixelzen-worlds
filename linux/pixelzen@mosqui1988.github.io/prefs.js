// Preferencias gráficas de PixelZen Worlds para GNOME Shell 46-50+.
import Adw from 'gi://Adw';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Gtk from 'gi://Gtk';
import {ExtensionPreferences} from 'resource:///org/gnome/Shell/Extensions/js/extensions/prefs.js';

const TEMAS_BASE = [
    {id: 'fittoa', nombre: 'Región de Fittoa'},
    {id: 'continente-demoniaco', nombre: 'Continente Demoníaco'},
    {id: 'hunter-x-hunter', nombre: 'Hunter × Hunter · Isla Ballena'},
    {id: 'black-clover', nombre: 'Black Clover · Aldea de Hage'},
    {id: 'spiderman-miles-morales', nombre: 'Spider-Man · Miles Morales'},
    {id: 'solo-leveling', nombre: 'Solo Leveling · Castillo del Monarca'},
    {id: 'demon-slayer', nombre: 'Demon Slayer · Tren Infinito'},
    {id: 'stranger-things', nombre: 'Stranger Things · Hawkins y el Revés'},
    {id: 'harry-potter', nombre: 'Harry Potter · Castillo de Hogwarts'},
    {id: 'naruto', nombre: 'Naruto · Modo Baryon'},
    {id: 'jujutsu-kaisen', nombre: 'Jujutsu Kaisen · Expansión de Dominio'},
    {id: 'attack-on-titan', nombre: 'Attack on Titan · El Retumbar'},
    {id: 'one-piece', nombre: 'One Piece · Gear 5 & Onigashima'},
    {id: 'dragon-ball-z', nombre: 'Dragon Ball Z · Ultra Instinto'},
    {id: 'cyberpunk-edgerunners', nombre: 'Cyberpunk: Edgerunners · Night City'},
    {id: 'terraza-michis', nombre: 'Terraza de los Michis · Siesta Zen'},
    {id: 'salon-noah-maggie', nombre: 'Salón de Noah y Maggie · Hogar Zen'},
];

export default class PixelZenPreferences extends ExtensionPreferences {
    _listarTemas() {
        const temasDir = `${this.path}/temas`;
        if (!GLib.file_test(temasDir, GLib.FileTest.IS_DIR))
            return TEMAS_BASE;

        const encontrados = [];
        try {
            const dir = Gio.File.new_for_path(temasDir);
            const it = dir.enumerate_children('standard::name,standard::type', Gio.FileQueryInfoFlags.NONE, null);
            let info;
            while ((info = it.next_file(null)) !== null) {
                if (info.get_file_type() !== Gio.FileType.DIRECTORY) continue;
                const id = info.get_name();
                let nombre = id;
                const tj = `${temasDir}/${id}/tema.json`;
                if (GLib.file_test(tj, GLib.FileTest.EXISTS)) {
                    try {
                        const raw = JSON.parse(new TextDecoder().decode(GLib.file_get_contents(tj)[1]));
                        if (raw.nombre) nombre = raw.nombre;
                    } catch (_e) { /* usar id */ }
                }
                encontrados.push({id, nombre});
            }
        } catch (_e) {
            return TEMAS_BASE;
        }
        return encontrados.length ? encontrados.sort((a, b) => a.nombre.localeCompare(b.nombre)) : TEMAS_BASE;
    }

    fillPreferencesWindow(window) {
        const settings = this.getSettings();
        window.set_title('PixelZen Worlds · Preferencias');
        window.set_default_size(560, 620);

        const page = new Adw.PreferencesPage({
            title: 'Paisaje y ciclo',
            icon_name: 'preferences-desktop-wallpaper-symbolic',
        });
        window.add(page);

        // Grupo 1: Mundo activo
        const grupoTema = new Adw.PreferencesGroup({
            title: 'Mundo activo',
            description: 'Cambia el paisaje animado y las citas del grimorio al instante.',
        });
        page.add(grupoTema);

        const temas = this._listarTemas();
        const listaTemas = new Gtk.StringList();
        temas.forEach(t => listaTemas.append(`${t.nombre} (${t.id})`));

        const comboTema = new Adw.ComboRow({
            title: 'Escena / Paisaje',
            model: listaTemas,
        });
        const actualTema = settings.get_string('tema');
        const idxTema = Math.max(0, temas.findIndex(t => t.id === actualTema));
        comboTema.set_selected(idxTema);
        comboTema.connect('notify::selected', () => {
            const sel = temas[comboTema.get_selected()];
            if (sel && sel.id !== settings.get_string('tema')) {
                settings.set_string('tema', sel.id);
                settings.set_int('tema-revision', settings.get_int('tema-revision') + 1);
            }
        });
        grupoTema.add(comboTema);

        // Grupo 2: Tiempo y animación
        const grupoTiempo = new Adw.PreferencesGroup({
            title: 'Ciclo solar y animación',
        });
        page.add(grupoTiempo);

        const modos = [
            {id: 'real', label: 'Hora real del sistema'},
            {id: '90m', label: 'Ciclo completo (24h en 90 min)'},
            {id: 'demo', label: 'Demo rápida (24h en 90 s)'},
            {id: 'fija', label: 'Hora fija manual'},
        ];
        const listaModos = new Gtk.StringList();
        modos.forEach(m => listaModos.append(m.label));
        const comboModo = new Adw.ComboRow({
            title: 'Modo de tiempo',
            model: listaModos,
        });
        const servicio90Activo = () => {
            try {
                const [ok, , , status] = GLib.spawn_command_line_sync('systemctl --user is-active --quiet pixelzen-ciclo90.service');
                return ok && status === 0;
            } catch (_e) {
                return false;
            }
        };
        const paraServicio90 = () => {
            try {
                Gio.Subprocess.new(
                    ['systemctl', '--user', 'disable', '--now', 'pixelzen-ciclo90.service'],
                    Gio.SubprocessFlags.STDOUT_SILENCE | Gio.SubprocessFlags.STDERR_SILENCE
                );
            } catch (_e) { /* systemd no disponible */ }
        };

        const leeModoIdx = () => {
            if (servicio90Activo()) return 1;
            if (settings.get_boolean('ciclo-rapido'))
                return settings.get_int('ciclo-duracion') >= 3600 ? 1 : 2;
            return settings.get_double('hora-simulada') >= 0 ? 3 : 0;
        };
        comboModo.set_selected(leeModoIdx());

        const rowHora = new Adw.SpinRow({
            title: 'Hora fija (formato 24h)',
            subtitle: 'Ejemplo: 18.75 = 18:45 (atardecer), 22.0 = 22:00 (noche)',
            adjustment: new Gtk.Adjustment({
                lower: 0,
                upper: 23.75,
                step_increment: 0.25,
                page_increment: 1.0,
                value: Math.max(0, settings.get_double('hora-simulada') >= 0 ? settings.get_double('hora-simulada') : 18.75),
            }),
            digits: 2,
        });
        rowHora.set_sensitive(comboModo.get_selected() === 3);

        comboModo.connect('notify::selected', () => {
            const idx = comboModo.get_selected();
            paraServicio90();
            if (idx === 0) {
                settings.set_boolean('ciclo-rapido', false);
                settings.set_double('hora-simulada', -1);
            } else if (idx === 1) {
                settings.set_int('ciclo-duracion', 5400);
                settings.set_boolean('ciclo-rapido', true);
                settings.set_double('hora-simulada', -1);
            } else if (idx === 2) {
                settings.set_int('ciclo-duracion', 90);
                settings.set_boolean('ciclo-rapido', true);
                settings.set_double('hora-simulada', -1);
            } else {
                settings.set_boolean('ciclo-rapido', false);
                settings.set_double('hora-simulada', rowHora.get_value());
            }
            rowHora.set_sensitive(idx === 3);
        });
        rowHora.connect('notify::value', () => {
            if (comboModo.get_selected() === 3)
                settings.set_double('hora-simulada', rowHora.get_value());
        });
        grupoTiempo.add(comboModo);
        grupoTiempo.add(rowHora);

        const rowAnimar = new Adw.SwitchRow({
            title: 'Animar paisaje y partículas',
            subtitle: 'Nubes, agua, aves, ferry/Miles Morales y luces nocturnas',
        });
        settings.bind('animar', rowAnimar, 'active', Gio.SettingsBindFlags.DEFAULT);
        grupoTiempo.add(rowAnimar);

        const rowFps = new Adw.SpinRow({
            title: 'Cuadros por segundo (FPS)',
            adjustment: new Gtk.Adjustment({lower: 4, upper: 30, step_increment: 1, page_increment: 2, value: settings.get_int('fps')}),
            digits: 0,
        });
        settings.bind('fps', rowFps, 'value', Gio.SettingsBindFlags.DEFAULT);
        grupoTiempo.add(rowFps);

        const climas = [
            {id: 'normal', label: 'Despejado (Original del mundo)'},
            {id: 'lluvia', label: 'Lluvia suave'},
            {id: 'tormenta', label: 'Tormenta con relámpagos'},
            {id: 'nieve', label: 'Nieve suave'},
            {id: 'niebla', label: 'Niebla misteriosa'},
            {id: 'ceniza', label: 'Ceniza / brasas'},
            {id: 'auto', label: 'Automático por universo y clima real'},
        ];
        const listaClima = new Gtk.StringList();
        climas.forEach(c => listaClima.append(c.label));
        const comboClima = new Adw.ComboRow({title: 'Clima dinámico', model: listaClima});
        const curClima = settings.get_string('clima');
        comboClima.set_selected(Math.max(0, climas.findIndex(c => c.id === curClima)));
        comboClima.connect('notify::selected', () => {
            const sel = climas[comboClima.get_selected()];
            if (sel) settings.set_string('clima', sel.id);
        });
        grupoTiempo.add(comboClima);

        // Grupo 3: HUD y monitores
        const grupoHud = new Adw.PreferencesGroup({
            title: 'Panel HUD y pantallas',
        });
        page.add(grupoHud);

        const listaMon = new Gtk.StringList();
        listaMon.append('1 monitor (solo monitor principal)');
        listaMon.append('2 monitores (principal + continuación de la historia)');
        const comboMon = new Adw.ComboRow({
            title: 'Número de monitores',
            subtitle: 'El monitor principal del sistema muestra la escena base y el 2.º la continuación',
            model: listaMon,
        });
        const actualMon = settings.get_boolean('todos-monitores') ? settings.get_int('num-monitores') : 1;
        comboMon.set_selected(actualMon >= 2 ? 1 : 0);
        comboMon.connect('notify::selected', () => {
            const dos = comboMon.get_selected() === 1;
            settings.set_int('num-monitores', dos ? 2 : 1);
            settings.set_boolean('todos-monitores', dos);
        });
        grupoHud.add(comboMon);

        const rowSoloW = new Adw.SwitchRow({
            title: 'Modo Solo Widgets',
            subtitle: 'Muestra solo las tarjetas HUD manteniendo tu fondo de GNOME',
        });
        settings.bind('solo-widgets', rowSoloW, 'active', Gio.SettingsBindFlags.DEFAULT);
        grupoHud.add(rowSoloW);

        const rowHud = new Adw.SwitchRow({
            title: 'Mostrar panel de datos (HUD)',
            subtitle: 'Activa o desactiva la superposición del HUD en el monitor principal',
        });
        settings.bind('hud', rowHud, 'active', Gio.SettingsBindFlags.DEFAULT);
        grupoHud.add(rowHud);

        const rowCompacto = new Adw.SwitchRow({
            title: 'HUD compacto',
            subtitle: 'Reduce márgenes y relleno entre tarjetas',
        });
        settings.bind('hud-compacto', rowCompacto, 'active', Gio.SettingsBindFlags.DEFAULT);
        grupoHud.add(rowCompacto);

        // Grupo 3b: Tarjetas de estadísticas del HUD
        const grupoStats = new Adw.PreferencesGroup({
            title: 'Estadísticas visibles en el HUD (9 tarjetas)',
            description: 'Si activas más de 5 tarjetas, el HUD pasa automáticamente a 2 columnas.',
        });
        page.add(grupoStats);

        for (const [clave, titulo, subtitulo] of [
            ['hud-tiempo', 'Tiempo y fase lunar', 'Reloj en vivo, fecha, nombre del mundo y luna'],
            ['hud-clima', 'Clima real y órbita solar', 'Temperatura, viento, elevación solar y azimut'],
            ['hud-sistema', 'Sistema (CPU, RAM, Temp, Disco)', 'Barras de rendimiento, historial CPU y batería'],
            ['hud-gpu', 'GPU y motor gráfico', 'Tarjeta gráfica, FPS y resolución'],
            ['hud-red', 'Red y tráfico', 'SSID/interfaz, IP, puerta de enlace, VPN y caudal ↓↑'],
            ['hud-audio', 'Música y BSO del mundo', 'Reproductores MPRIS/Spotify o banda sonora del universo'],
            ['hud-dev', 'Entorno Dev y servicios', 'Repositorios Git, versiones (Python/Node/Go/Rust) y servicios'],
            ['hud-foco', 'Foco Zen (Pomodoro)', 'Temporizador de 25 minutos y tiempo de sesión'],
            ['hud-grimorio', 'Grimorio (citas del mundo)', 'Citas rotatorias de los personajes del paisaje activo'],
        ]) {
            const row = new Adw.SwitchRow({title: titulo, subtitle: subtitulo});
            settings.bind(clave, row, 'active', Gio.SettingsBindFlags.DEFAULT);
            grupoStats.add(row);
        }

        // Grupo 4: Créditos
        const grupoCreditos = new Adw.PreferencesGroup({
            title: 'Créditos',
        });
        page.add(grupoCreditos);

        const rowOrig = new Adw.ActionRow({
            title: 'Basado en PixelZen de mosqui1988',
            subtitle: 'https://github.com/mosqui1988/pixelzen · Licencia GPL-3.0-or-later',
        });
        grupoCreditos.add(rowOrig);
    }
}
