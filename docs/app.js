(() => {
  const WORLDS = [
    {
      id: 'fittoa',
      serie: 'Mushoku Tensei',
      cat: 'anime',
      titulo: 'Región de Fittoa',
      m1: { name: 'Aldea de Buena', sub: 'K407 · Mansión Greyrat y Lago de Fittoa', desc: 'Aldea de Buena con la Mansión Greyrat, torre de mago, cascada lejana, muelle, arco rúnico con cristal de maná y Gran Roble.' },
      m2: { name: 'Base de Perugius', sub: 'Chaos Breaker · Fortaleza sobre Ars', desc: 'Sobre las llanuras de Asura y la Capital Real de Ars flota Chaos Breaker, la fortaleza celeste del Rey Dragón Blindado.' },
      m3: { name: 'Santuario del Teletransporte', sub: 'K407 · Monolito de Maná y Buena', desc: 'Santuario rúnico del bosque de Fittoa con monolito de teletransporte, cabaña del guardabosques y sendero empedrado.' },
      cita: '«Incluso desde un segundo intento, cada mañana bajo el Gran Roble de Buena vale la pena vivirla en serio.» — Rudeus Greyrat',
    },
    {
      id: 'continente-demoniaco',
      serie: 'Mushoku Tensei',
      cat: 'anime',
      titulo: 'Continente Demoníaco',
      m1: { name: 'Rikarisu · Dead End', sub: 'K410 · Basalto y Ruinas de Teletransporte', desc: 'Ciudadela demoníaca de Rikarisu entre agujas de basalto, cristales gigantes de maná, monolitos carmesí y río de obsidiana.' },
      m2: { name: 'Fortaleza Basalto', sub: 'Rikarisu y Rudeus · Invocación Arcana', desc: 'Fortaleza volcánica con torres con cuernos, grietas de lava y Rudeus Greyrat conjurando un hechizo con Aqua Heartia.' },
      m3: { name: 'Puerta de Obsidiana', sub: 'K410 · Abismo Carmesí y Roca Roja', desc: 'Puerta gemela de basalto y obsidiana sobre el profundo cañón volcánico de Rikarisu con cristales de maná.' },
      cita: '«Si confías en los compañeros que caminan a tu lado, incluso el Continente Demoníaco tiene salida.» — Ruijerd Superdia',
    },
    {
      id: 'hunter-x-hunter',
      serie: 'Hunter × Hunter',
      cat: 'anime',
      titulo: 'Isla Ballena y H×H',
      m1: { name: 'Isla Ballena', sub: 'Árbol del Mundo y Muelle de Gon', desc: 'Colosal Árbol del Mundo en la distancia, cabaña de Mito-san, muelle donde Gon pesca, dirigible de Cazadores y Aura Nen.' },
      m2: { name: 'Greed Island', sub: 'Praderas y Torre de Eta y Elena', desc: 'Vastas praderas verdes bajo nubes suaves con la icónica torre de recepción de techo cónico y Gon y Killua jugando.' },
      m3: { name: 'Torre Celestial', sub: 'Piso 251 · Arena del Cielo', desc: 'Silueta monumental de la Torre Celestial alzada sobre una gran plaza urbana iluminada junto al dirigible del Examen.' },
      cita: '«Deberías disfrutar los pequeños desvíos tanto como el objetivo final.» — Ging Freecss',
    },
    {
      id: 'black-clover',
      serie: 'Black Clover',
      cat: 'anime',
      titulo: 'Reino del Trébol y Picas',
      m1: { name: 'Aldea de Hage', sub: 'Cráneo del Demonio y Torre de Grimorios', desc: 'Aldea de Hage bajo el Cráneo del Demonio y estatua del Primer Rey Mago, con la Iglesia, Torre de Grimorios y espada de Asta.' },
      m2: { name: 'Reino de Picas y Asta', sub: 'Fortaleza Helada y Espada Demon-Slayer', desc: 'Cumbres nevadas, el Castillo de Picas bajo el sello del Qliphoth y Asta blandiendo la espada Danma con su grimorio negro.' },
      m3: { name: 'Altar del Grimorio Real', sub: 'Reino del Trébol · Ruinas Góticas', desc: 'Altar gótico y plaza ceremonial de piedra del Trébol con la espada antimagia clavada sobre un sello rúnico iluminado.' },
      cita: '«En las cinco hojas del trébol aguarda el poder que nunca se rinde.» — Asta',
    },
    {
      id: 'spiderman-miles-morales',
      serie: 'Marvel · Spider-Verse',
      cat: 'marvel',
      titulo: 'Miles Morales',
      m1: { name: 'Brooklyn & Estatua', sub: 'Brooklyn · Horizonte de Manhattan', desc: 'Ladrillo de Brooklyn con depósitos de agua, Puente de Brooklyn, Estatua de la Libertad, Manhattan y Miles con chispas Venom.' },
      m2: { name: 'Midtown y Harlem', sub: 'Tierra-1610 · Metro Elevado y Torres', desc: 'Rascacielos Art Déco, tren elevado de Nueva York, azoteas de Harlem con mural neón Spider-Verse y Miles balanceándose.' },
      m3: { name: 'Azotea de Harlem', sub: 'Manhattan · Vigilancia Nocturna', desc: 'Miles Morales vigilando el horizonte iluminado de Manhattan desde una azotea de ladrillo en Brooklyn.' },
      cita: '«Cualquiera puede llevar la máscara. Lo que importa es levantarse siempre una vez más.» — Miles Morales',
    },
    {
      id: 'solo-leveling',
      serie: 'Solo Leveling',
      cat: 'anime',
      titulo: 'Monarca de las Sombras',
      m1: { name: 'Castillo del Monarca', sub: 'Trono Carmesí · Jin-Woo e Igris', desc: 'Ciudadela gótica donde Sung Jin-Woo es proclamado Monarca de las Sombras junto a Igris y su ejército surgido de la oscuridad.' },
      m2: { name: 'Isla de Jeju y Beru', sub: 'Colmena de Hormigas · Rey Beru', desc: 'Acantilados volcánicos de la Isla de Jeju bajo el nido infectado, huevos bioluminiscentes y la imponente silueta alada de Beru.' },
      m3: { name: 'Portal del Monarca', sub: 'Portón Rango S · Dagas Sombra', desc: 'Portón dimensional azul-violeta flanqueado por obeliscos rúnicos y las dagas gemelas de Jin-Woo ante el sello de invocación.' },
      cita: '«Surge.» — Sung Jin-Woo, Monarca de las Sombras',
    },
    {
      id: 'demon-slayer',
      serie: 'Demon Slayer',
      cat: 'anime',
      titulo: 'Kimetsu no Yaiba',
      m1: { name: 'Tren Infinito', sub: 'Mugen Train · Rengoku vs Akaza', desc: 'Claro nocturno junto al Tren Infinito descarrilado donde Kyojuro Rengoku desata la Respiración de la Llama frente a Akaza.' },
      m2: { name: 'Aldea de los Herreros', sub: 'Valle Brumoso · Tokito vs Gyokko', desc: 'Sendero brumoso entre cedros junto al taller de los herreros donde Muichiro Tokito blande la Respiración de la Niebla contra Gyokko.' },
      m3: { name: 'Santuario de Glicinias', sub: 'Monte Fujikasane · Torii y Nichirin', desc: 'Santuario bajo cascadas de glicinias púrpuras que ahuyentan a los demonios, con faroles de piedra y katana Nichirin en el altar.' },
      cita: '«Haz arder tu corazón, supera tus límites y protege a los demás.» — Kyojuro Rengoku',
    },
    {
      id: 'stranger-things',
      serie: 'Stranger Things',
      cat: 'series',
      titulo: 'Hawkins y Upside Down',
      m1: { name: 'Hawkins y Creel House', sub: 'Casa Creel · Azotamentes y Bicis', desc: 'Noche tormentosa en Hawkins bajo la grieta carmesí del Upside Down con el Azotamentes alzándose y los chicos en bici.' },
      m2: { name: 'Bosque y Demogorgon', sub: 'Cabaña Byers · Luces y Demogorgon', desc: 'Linde del bosque de Hawkins con la cabaña iluminada por luces navideñas y la amenaza sombría del Demogorgon entre esporas.' },
      m3: { name: 'Reloj de Creel', sub: 'Maldición de Vecna · Grieta Escarlata', desc: 'El antiguo reloj de pie de la casa Creel atrapado entre grietas rojas del Mundo del Revés y esporas flotantes.' },
      cita: '«Los amigos nunca mienten, ni siquiera cuando el cielo se abre sobre Hawkins.» — Hawkins, Indiana',
    },
    {
      id: 'harry-potter',
      serie: 'Harry Potter',
      cat: 'series',
      titulo: 'Castillo de Hogwarts',
      m1: { name: 'Castillo y Lago Negro', sub: 'Torre de Astronomía y Quidditch', desc: 'Castillo de Hogwarts sobre acantilados de Escocia reflejado en el Lago Negro, barcas iluminadas y Harry tras la Snitch Dorada.' },
      m2: { name: 'Hogsmeade y Expreso', sub: 'Viaducto 5972 y Ciervo Patronus', desc: 'Cabañas nevadas de Hogsmeade con chimeneas humeantes, el Expreso de Hogwarts en el viaducto y el Ciervo Patronus brillante.' },
      m3: { name: 'Andén 9¾ y Reliquias', sub: "King's Cross · Hedwig y Saúco", desc: 'Arco victoriano del Andén 9¾ iluminado con faroles dorados, baúl con Hedwig y el resplandor de las Reliquias de la Muerte.' },
      cita: '«La felicidad se puede hallar hasta en los momentos más oscuros si recuerdas encender la luz.» — Albus Dumbledore',
    },
    {
      id: 'naruto',
      serie: 'Naruto',
      cat: 'anime',
      titulo: 'Konoha & Modo Baryon',
      m1: { name: 'Naruto Modo Baryon', sub: 'Naruto y Kurama vs Isshiki', desc: 'Duelo definitivo en el desierto rocío bajo la silueta espectral de Kurama, Naruto envuelto en las 9 colas de chakra Modo Baryon con Baryon Rasengan frente a Isshiki y sus cubos Daikokuten.' },
      m2: { name: 'Konoha y Monte Hokage', sub: 'Aldea Oculta e Ichiraku Ramen', desc: 'Río Naka reflejando el Monumento a los Hokages, la Residencia Hokage, faroles de Ichiraku Ramen y Naruto Séptimo Hokage junto a Sasuke bajo las hojas de Konoha.' },
      m3: { name: 'Valle del Fin', sub: 'Rasengan vs Chidori en la cascada', desc: 'Estatuas colosales de Hashirama y Madara flanqueando la gran cascada del Valle del Fin mientras el Rasengan y el Chidori chocan sobre las aguas.' },
      cita: '«Mientras no te rindas, siempre habrá una manera de cambiar tu destino.» — Naruto Uzumaki',
    },
    {
      id: 'jujutsu-kaisen',
      anime: 'Jujutsu Kaisen',
      serie: 'Jujutsu Kaisen',
      cat: 'anime',
      titulo: 'Expansión de Dominio',
      m1: { name: 'Santuario Malevolente vs Vacío Infinito', sub: 'Sukuna vs Gojo · Shinjuku', desc: 'Shinjuku partido por el choque de dominios: el monumental Sagrario Malevolente de Sukuna con su boca demoníaca y cráneos frente al Vacío Infinito de Gojo y Púrpura Vacío.' },
      m2: { name: 'Incidente de Shibuya', sub: 'Prisión Confinadora, Itadori y Fushiguro', desc: 'Cruce nocturno de Shibuya con la Torre 109, la Prisión Confinadora levitando, el Destello Negro de Itadori y Megumi junto al Perro Divino y Nue.' },
      m3: { name: 'Santuario del Dedo Maldito', sub: 'Torii Sagrado y Sellos Ofuda', desc: 'Calzada sagrada de piedra con pagoda entre cedros, faroles Toro, puerta Torii bermellón con sellos Ofuda y el Dedo de Ryomen Sukuna en su relicario.' },
      cita: '«En el cielo y en la tierra, solo yo merezco ser honrado.» — Satoru Gojo',
    },
    {
      id: 'attack-on-titan',
      anime: 'Attack on Titan',
      serie: 'Attack on Titan',
      cat: 'anime',
      titulo: 'El Retumbar y la Muralla',
      m1: { name: 'El Retumbar', sub: 'Titán Fundador, Colosales, Mikasa y Levi', desc: 'El colosal costillar del Titán Fundador alzándose tras una marcha de Titanes Colosales incandescentes mientras Mikasa y Levi combaten entre los tejados de Shiganshina.' },
      m2: { name: 'Caída de Shiganshina', sub: 'Año 845 · Titán Colosal en Muralla María', desc: 'El Titán Colosal asomando entre relámpagos dorados sobre los muros de la Muralla María frente a las casas tradicionales del distrito de Shiganshina.' },
      m3: { name: 'Los Caminos (La Coordenada)', sub: 'Árbol Luminoso y Memorial EDM', desc: 'El pilar resplandeciente de La Coordenada ramificándose por el cielo estrellado sobre la colina de Eren y el memorial de cuchillas EDM con la bufanda roja.' },
      cita: '«Si ganas, vives. Si pierdes, mueres. Si no luchas, no puedes ganar.» — Eren Jaeger',
    },
    {
      id: 'one-piece',
      anime: 'One Piece',
      serie: 'One Piece',
      cat: 'anime',
      titulo: 'Gear 5 & Onigashima',
      m1: { name: 'Gear 5 vs Kaido Dragón', sub: 'Tejado de Onigashima · Dios del Sol Nika', desc: 'Duelo legendario en el tejado de la cúpula de calavera de Onigashima: Luffy en Gear 5 desatando el Bajrang Gun frente al dragón azul de Kaido y su aliento ígneo.' },
      m2: { name: 'Thousand Sunny bajo la Luna', sub: 'Nuevo Mundo · Zoro y Sanji en cubierta', desc: 'El Thousand Sunny navegando bajo el reflejo lunar con su mascarón leonino, las velas del Sombrero de Paja y el aura de Zoro y Sanji.' },
      m3: { name: 'Road Poneglyph Carmesí', sub: 'Sombrero de Paja y Fruta Hito-Hito: Nika', desc: 'Acantilado junto al mar con el monolítico Road Poneglyph carmesí de glifos brillantes junto al Sombrero de Paja y la Fruta del Diablo de Nika.' },
      cita: '«¡Escucha bien los Tambores de la Liberación! ¡Soy quien siempre lucha libremente!» — Monkey D. Luffy',
    },
    {
      id: 'dragon-ball-z',
      anime: 'Dragon Ball Z',
      serie: 'Dragon Ball Z',
      cat: 'anime',
      titulo: 'Ultra Instinto en Namek',
      m1: { name: 'Ultra Instinto vs Freezer Dorado', sub: 'Namek al borde del colapso · Choque de Ki', desc: 'Planeta Namek agrietado por magma bajo dos soles: Son Goku Ultra Instinto Dominado chocando su Kamehameha Divino contra la Supernova de Freezer Dorado.' },
      m2: { name: 'Dragón Sagrado Shenron', sub: 'Namek · 7 Bolas de Dragón invocadas', desc: 'Las siete Bolas de Dragón brillando junto a aldeas y árboles Ajisa mientras el inmenso dragón Shenron asciende rodeado de relámpagos dorados.' },
      m3: { name: 'Kame House y Bola de 4 Estrellas', sub: 'Isla del Maestro Roshi · Nube Kinton', desc: 'La icónica isla de Kame House entre palmeras bajo la luna, la Nube Kinton junto al Bastón Mágico y la Bola de 4 Estrellas del abuelo Gohan.' },
      cita: '«El poder surge en respuesta a una necesidad, no a un deseo.» — Son Goku',
    },
    {
      id: 'cyberpunk-edgerunners',
      anime: 'Cyberpunk: Edgerunners',
      serie: 'Cyberpunk: Edgerunners',
      cat: 'anime',
      titulo: 'Night City & Sandevistan',
      m1: { name: 'Corpo Plaza · Lluvia de Neón', sub: 'David Martinez & Lucy · Quadra Turbo-R', desc: 'Las calles lluviosas de Night City bajo la torre Arasaka con el Quadra Turbo-R, David activando la estela cromática del Sandevistan y Lucy desplegando su monofilo.' },
      m2: { name: 'La Luna sobre Night City', sub: 'Azotea y tren elevado NCART', desc: 'David y Lucy sentados hombro con hombro en lo alto de la ciudad frente a la inmensidad plateada de la Luna mientras el monorraíl NCART cruza los rascacielos.' },
      m3: { name: 'Callejón Afterlife & Sandevistan', sub: 'Mural ER e Implante Apogee', desc: 'Callejón húmedo tras el Afterlife con el emblema grafiteado ER iluminado en verde ácido y el implante espinal Apogee Sandevistan latiendo en el banco.' },
      cita: '«No hace falta que salves el mundo entero… basta con llevarte hasta la luna.» — David Martinez',
    },
    {
      id: 'terraza-michis',
      serie: 'Vida Zen · Mascotas',
      cat: 'zen',
      titulo: 'Terraza de los Michis',
      m1: { name: 'Siesta en el Césped', sub: 'Michi Gris & Michi Crema · Pelotita Multicolor', desc: 'Tarde tranquila en el césped verde: el michi crema estirado panza arriba junto a su pelotita multicolor y la tarima de madera, mientras el michi gris de ojos ámbar descansa junto al rascador de sisal.' },
      m2: { name: 'Torre Rascador y Pelotita', sub: 'Mirador de Sisal · Juego en la Terraza', desc: 'Continuación del balcón con la torre rascador de dos niveles y plantas en maceta: el michi gris vigila desde lo alto y el michi crema persigue su pelotita arcoíris.' },
      m3: { name: 'Santuario de la Pelotita', sub: 'Altar del Cojín · Siesta Nocturna Juntos', desc: 'La pelotita multicolor reposando sobre el cojín oscuro rodeada de huellitas luminosas junto al farol cálido, con ambos michis descansando acurrucados bajo las estrellas.' },
      cita: '«La felicidad es un rayo de sol sobre el césped verde y un buen ronroneo sin prisas.» — Terraza de los Michis',
    },
    {
      id: 'salon-noah-maggie',
      serie: 'Vida Zen · Mascotas',
      cat: 'zen',
      titulo: 'Salón de Noah y Maggie',
      m1: { name: 'Noche de Breaking Bad', sub: 'Maggie con Patita Colgando & Noah Panecillo', desc: 'Salón acogedor con ventanal animado, tele reproduciendo Breaking Bad y Maggie estirada sobre el mueble con su patita blanca colgando junto a Noah.' },
      m2: { name: 'Rincón del Miró', sub: 'Posado Oficial en el Mueble Blanco', desc: 'Junto al cuadro de Miró y la lamparita de pinza, Noah entrecierra los ojos con su expresión seria y Maggie posa erguida con sus ojazos ámbar.' },
      m3: { name: 'Cojín de la Siesta', sub: 'Cojín de Rombos & Barriguita al Sol', desc: 'Noah hecha un bollito perfecto sobre el cojín crema tejido y Maggie estirada panza arriba bajo las luces cálidas del ventanal.' },
      cita: '«La mejor postura para ver Breaking Bad es con una patita blanca colgando del borde.» — Maggie',
    },
  ];

  const STAT_KEYS = ['tiempo', 'clima', 'sistema', 'gpu', 'red', 'audio', 'dev', 'foco', 'grimorio'];
  const canvas = document.getElementById('lienzo');
  const canvasSec = document.getElementById('lienzo-sec');
  const canvasBloq = document.getElementById('lienzo-bloq');
  const wrapEl = document.getElementById('canvas-wrap');
  const loadingEl = document.getElementById('canvas-loading');
  const sliderEl = document.getElementById('hora-slider');
  const horaLabelEl = document.getElementById('hora-label');
  const badgeSecEl = document.getElementById('badge-sec');
  const badgeBloqEl = document.getElementById('badge-bloq');

  let numMonitores = 2;

  const renderer = window.PixelZenCanvas.createRenderer(canvas, {
    initialState: {
      tema: 'fittoa',
      pantalla: 'principal',
      modoHora: 3,
      horaFija: 18.75,
      fps: 10,
      mostrarHud: true,
      hudStats: {
        tiempo: true, clima: true, sistema: true, gpu: true,
        red: true, audio: true, dev: true, foco: true, grimorio: true,
      },
      inicioHora: 18.75,
    },
    onTemaLoaded(tema, id) {
      wrapEl.style.background = tema.cielo_fondo || '#060814';
      loadingEl.classList.add('is-hidden');
      actualizaLoreStage(id);
      renderer.render();
    },
    onRender(fecha, T) {
      const p2 = v => String(v).padStart(2, '0');
      horaLabelEl.textContent = `${p2(fecha.getHours())}:${p2(fecha.getMinutes())}`;
      if (renderer.state.modoHora !== 3) {
        sliderEl.value = (fecha.getHours() + fecha.getMinutes() / 60).toFixed(2);
      }
      renderer.actualizaHud(fecha, T, { quoteIntervalMs: 15000 });
    },
  });

  function crearSecundarioRenderer(el, pantallaKey, badgeEl, badgePrefix) {
    if (!el) return null;
    return window.PixelZenCanvas.createRenderer(el, {
      initialState: {
        tema: 'fittoa',
        pantalla: pantallaKey,
        modoHora: 3,
        horaFija: 18.75,
        fps: 10,
        mostrarHud: false,
        inicioHora: 18.75,
      },
      onTemaLoaded(tema) {
        if (badgeEl && tema && tema.nombre) {
          badgeEl.textContent = `${badgePrefix} · ${tema.nombre.toUpperCase()}`;
        }
      },
    });
  }

  const rendererSec = crearSecundarioRenderer(canvasSec, 'secundaria', badgeSecEl, 'MONITOR 2');
  const rendererBloq = crearSecundarioRenderer(canvasBloq, 'bloqueo', badgeBloqEl, 'BLOQUEO');
  const { state } = renderer;

  function sincronizaAuxiliares() {
    for (const aux of [rendererSec, rendererBloq]) {
      if (!aux) continue;
      aux.state.modoHora = state.modoHora;
      aux.state.horaFija = state.horaFija;
      aux.state.inicioMs = state.inicioMs;
      aux.state.inicioHora = state.inicioHora;
      aux.state.tick = state.tick;
      aux.state.clima = state.clima;
      aux.state.audioReactivo = state.audioReactivo;
      aux.state.audioEnergy = state.audioEnergy;
      aux.state.parallax = state.parallax;
      aux.state.parallaxX = state.parallaxX;
      aux.state.parallaxY = state.parallaxY;
      aux.state.evento = state.evento ? { ...state.evento } : null;
    }
  }

  function renderTodo() {
    renderer.render();
    sincronizaAuxiliares();
    if (rendererSec && numMonitores >= 2) rendererSec.render();
    if (rendererBloq && numMonitores >= 3) rendererBloq.render();
  }

  function actualizaLoreStage(id) {
    const w = WORLDS.find(x => x.id === id);
    if (!w) return;
    const tEl = document.getElementById('stage-lore-title');
    const dEl = document.getElementById('stage-lore-desc');
    if (tEl) tEl.textContent = `${w.titulo} (${w.serie})`;
    if (dEl) dEl.textContent = `M1 ${w.m1.name} · M2 ${w.m2.name} · M3 ${w.m3.name}`;
  }

  function seleccionaYCarga(id) {
    loadingEl.classList.remove('is-hidden');
    const jobs = [renderer.cargarTema(id, { pantalla: 'principal' })];
    if (rendererSec && numMonitores >= 2) jobs.push(rendererSec.cargarTema(id, { pantalla: 'secundaria' }));
    if (rendererBloq && numMonitores >= 3) jobs.push(rendererBloq.cargarTema(id, { pantalla: 'bloqueo' }));
    Promise.all(jobs).then(() => {
      loadingEl.classList.add('is-hidden');
      renderTodo();
    });
  }

  function seleccionarTema(id) {
    state.tema = id;
    document.querySelectorAll('.pill[data-tema]').forEach(b => {
      b.classList.toggle('is-active', b.dataset.tema === id);
    });
    seleccionaYCarga(id);
  }

  function limpiarModos() {
    document.querySelectorAll('.btn-mode, .btn-phase').forEach(b => b.classList.remove('is-active'));
  }

  document.querySelectorAll('.pill[data-tema]').forEach(btn => {
    btn.addEventListener('click', () => seleccionarTema(btn.dataset.tema));
  });

  document.querySelectorAll('.btn-opt[data-monitores]').forEach(btn => {
    btn.addEventListener('click', () => {
      numMonitores = parseInt(btn.dataset.monitores, 10) || 1;
      document.querySelectorAll('.btn-opt[data-monitores]').forEach(b => b.classList.remove('is-active'));
      btn.classList.add('is-active');
      wrapEl.classList.toggle('is-dual', numMonitores === 2);
      wrapEl.classList.toggle('is-triple', numMonitores === 3);
      seleccionaYCarga(state.tema);
    });
  });

  function aplicaHudPreset(modo) {
    const sets = {
      all: STAT_KEYS,
      essential: ['tiempo', 'clima', 'sistema', 'grimorio'],
      minimal: ['tiempo', 'grimorio'],
    };
    const activos = sets[modo] || STAT_KEYS;
    state.mostrarHud = true;
    document.getElementById('btn-hud').textContent = 'HUD: ON';
    for (const k of STAT_KEYS) {
      const on = activos.includes(k);
      state.hudStats[k] = on;
      const chk = document.querySelector(`input[data-stat="${k}"]`);
      if (chk) chk.checked = on;
    }
    document.querySelectorAll('.btn-opt[data-hud-preset]').forEach(b => {
      b.classList.toggle('is-active', b.dataset.hudPreset === modo);
    });
    renderTodo();
  }

  document.querySelectorAll('.btn-opt[data-hud-preset]').forEach(btn => {
    btn.addEventListener('click', () => aplicaHudPreset(btn.dataset.hudPreset));
  });

  document.querySelectorAll('input[data-stat]').forEach(chk => {
    chk.addEventListener('change', () => {
      state.hudStats[chk.dataset.stat] = chk.checked;
      document.querySelectorAll('.btn-opt[data-hud-preset]').forEach(b => b.classList.remove('is-active'));
      renderTodo();
    });
  });

  document.querySelectorAll('.btn-mode').forEach(btn => {
    btn.addEventListener('click', () => {
      limpiarModos();
      btn.classList.add('is-active');
      const m = btn.dataset.modo;
      if (m === '90m') {
        state.modoHora = 1;
        state.inicioMs = Date.now();
        state.inicioHora = parseFloat(sliderEl.value) || 12;
      } else if (m === 'demo') {
        state.modoHora = 2;
      } else {
        state.modoHora = 0;
      }
      renderTodo();
    });
  });

  document.querySelectorAll('.btn-phase').forEach(btn => {
    btn.addEventListener('click', () => {
      limpiarModos();
      btn.classList.add('is-active');
      state.modoHora = 3;
      state.horaFija = parseFloat(btn.dataset.hora);
      sliderEl.value = state.horaFija;
      renderTodo();
    });
  });

  sliderEl.addEventListener('input', () => {
    limpiarModos();
    state.modoHora = 3;
    state.horaFija = parseFloat(sliderEl.value);
    renderTodo();
  });

  const btnHud = document.getElementById('btn-hud');
  btnHud.addEventListener('click', () => {
    state.mostrarHud = !state.mostrarHud;
    btnHud.textContent = `HUD: ${state.mostrarHud ? 'ON' : 'OFF'}`;
    renderTodo();
  });

  document.getElementById('btn-fullscreen').addEventListener('click', () => {
    if (document.fullscreenElement) document.exitFullscreen();
    else if (wrapEl.requestFullscreen) wrapEl.requestFullscreen();
  });

  document.querySelectorAll('.btn-opt[data-clima]').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.btn-opt[data-clima]').forEach(b => b.classList.remove('is-active'));
      btn.classList.add('is-active');
      state.clima = btn.dataset.clima || 'normal';
      renderTodo();
    });
  });

  const btnSynth = document.getElementById('btn-synth');
  const syncSynthBtn = () => {
    if (!btnSynth) return;
    const on = renderer.audioCtrl.isPlaying();
    btnSynth.classList.toggle('is-active', on);
    btnSynth.textContent = on ? '♪ Synth: ON' : '♪ Synth Lo-Fi';
  };
  if (btnSynth) {
    btnSynth.addEventListener('click', () => {
      renderer.audioCtrl.toggleSynth();
      syncSynthBtn();
      renderTodo();
    });
  }

  const btnEvento = document.getElementById('btn-evento');
  if (btnEvento) {
    btnEvento.addEventListener('click', () => {
      const elegido = renderer.dispararEvento();
      sincronizaAuxiliares();
      renderTodo();
      const orig = btnEvento.textContent;
      btnEvento.textContent = `✦ ${elegido.toUpperCase()}`;
      setTimeout(() => { btnEvento.textContent = orig; }, 1600);
    });
  }

  const btnCompact = document.getElementById('btn-hud-compact');
  if (btnCompact) {
    btnCompact.addEventListener('click', () => {
      state.hudCompacto = !state.hudCompacto;
      btnCompact.classList.toggle('is-active', state.hudCompacto);
      renderTodo();
    });
  }

  const btnParallax = document.getElementById('btn-parallax');
  if (btnParallax) {
    btnParallax.addEventListener('click', () => {
      state.parallax = !state.parallax;
      if (!state.parallax) { state.parallaxX = 0; state.parallaxY = 0; }
      btnParallax.classList.toggle('is-active', state.parallax);
      renderTodo();
    });
  }

  if (wrapEl) {
    wrapEl.addEventListener('mousemove', e => {
      if (!state.parallax) return;
      const r = wrapEl.getBoundingClientRect();
      state.parallaxX = ((e.clientX - r.left) / Math.max(1, r.width) - 0.5) * 2;
      state.parallaxY = ((e.clientY - r.top) / Math.max(1, r.height) - 0.5) * 2;
    });
    wrapEl.addEventListener('mouseleave', () => {
      state.parallaxX = 0;
      state.parallaxY = 0;
    });
  }

  function exportarPng(w, h, etiqueta) {
    const out = document.createElement('canvas');
    out.width = w;
    out.height = h;
    const octx = out.getContext('2d');
    octx.imageSmoothingEnabled = false;
    const scale = Math.max(w / canvas.width, h / canvas.height);
    const dw = Math.round(canvas.width * scale);
    const dh = Math.round(canvas.height * scale);
    const dx = Math.round((w - dw) / 2);
    const dy = Math.round((h - dh) / 2);
    octx.drawImage(canvas, dx, dy, dw, dh);
    try {
      const link = document.createElement('a');
      link.download = `pixelzen-${state.tema}-${etiqueta}.png`;
      link.href = out.toDataURL('image/png');
      link.click();
    } catch (_err) {
      const btn = document.getElementById(etiqueta === '4k' ? 'btn-export-4k' : 'btn-export-1080');
      if (btn) {
        const orig = btn.textContent;
        btn.textContent = '⚠ Abrir vía http://';
        setTimeout(() => { btn.textContent = orig; }, 2200);
      }
    }
  }
  const btn4k = document.getElementById('btn-export-4k');
  const btn1080 = document.getElementById('btn-export-1080');
  if (btn4k) btn4k.addEventListener('click', () => exportarPng(3840, 2160, '4k'));
  if (btn1080) btn1080.addEventListener('click', () => exportarPng(1920, 1080, '1080p'));

  const wireHud = (id, fn) => {
    const el = document.getElementById(id);
    if (el) el.addEventListener('click', ev => { ev.stopPropagation(); fn(); syncSynthBtn(); renderTodo(); });
  };
  wireHud('btn-audio-play', () => renderer.audioCtrl.toggleSynth());
  wireHud('btn-audio-prev', () => renderer.audioCtrl.prevTrack());
  wireHud('btn-audio-next', () => renderer.audioCtrl.nextTrack());
  wireHud('btn-foco-toggle', () => renderer.toggleFoco());
  wireHud('btn-foco-reset', () => renderer.resetFoco());
  wireHud('btn-foco-mode', () => renderer.setFocoModo(!state.foco.descanso));

  /* GALERÍA DINÁMICA DE 15 MUNDOS × 3 ESCENAS */
  const gridEl = document.getElementById('worlds-grid');
  const cardCtrl = {};
  const PREVIEW_FALLBACK_BASE = 'file:///C:/Users/david/.gemini/antigravity-cli/brain/8747b389-799a-4632-897a-f7f55a4233c0/scratch/out_root/docs/';

  function previewUrl(id, pan, fase) {
    const pref = pan === 'm2' ? 'm2-' : pan === 'm3' ? 'm3-' : '';
    return `previews/${id}/${pref}${fase}.png`;
  }

  function setPreviewImg(imgEl, relUrl) {
    if (!imgEl) return;
    delete imgEl.dataset.fbApplied;
    imgEl.onerror = function () {
      if (this.dataset.fbApplied === '1') return;
      this.dataset.fbApplied = '1';
      this.src = PREVIEW_FALLBACK_BASE + relUrl;
    };
    imgEl.src = relUrl;
  }

  function renderCards() {
    gridEl.innerHTML = '';
    for (const w of WORLDS) {
      const card = document.createElement('article');
      card.className = 'world-card';
      card.dataset.world = w.id;
      card.dataset.cat = w.cat;
      card.innerHTML = `
        <div class="world-media">
          <img alt="${w.titulo} (${w.m1.name})" loading="lazy" />
          <span class="world-screen-pill">M1 · ${w.m1.name}</span>
          <div class="phase-switch">
            <div class="phase-sub">
              <button class="is-active" data-pan="m1" title="Monitor 1 Principal">M1</button>
              <button data-pan="m2" title="Monitor 2 Continuación">M2</button>
              <button data-pan="m3" title="Pantalla de Bloqueo">M3</button>
            </div>
            <div class="phase-sub">
              <button data-fase="dia">Día</button>
              <button class="is-active" data-fase="dorado">Dorado</button>
              <button data-fase="noche">Noche</button>
            </div>
          </div>
        </div>
        <div class="world-body">
          <div class="world-top">
            <h3>${w.titulo}</h3>
            <span class="world-serie">${w.serie}</span>
          </div>
          <div class="world-scene-sub">${w.m1.sub}</div>
          <p>${w.m1.desc}</p>
          <div class="world-actions">
            <button class="btn-mini btn-inspect">🔍 3 Vistas</button>
            <button class="btn-mini btn-try" style="border-color:var(--border-gold);color:var(--gold)">▶ Probar en vivo</button>
          </div>
        </div>
      `;

      const img = card.querySelector('.world-media img');
      const pill = card.querySelector('.world-screen-pill');
      const subEl = card.querySelector('.world-scene-sub');
      const descEl = card.querySelector('.world-body p');
      const estadoCard = { pan: 'm1', fase: 'dorado' };
      setPreviewImg(img, previewUrl(w.id, estadoCard.pan, estadoCard.fase));

      function syncCard() {
        const info = w[estadoCard.pan];
        setPreviewImg(img, previewUrl(w.id, estadoCard.pan, estadoCard.fase));
        img.alt = `${w.titulo} — ${info.name}`;
        pill.textContent = `${estadoCard.pan.toUpperCase()} · ${info.name}`;
        subEl.textContent = info.sub;
        descEl.textContent = info.desc;
        card.querySelectorAll('button[data-pan]').forEach(b => b.classList.toggle('is-active', b.dataset.pan === estadoCard.pan));
        card.querySelectorAll('button[data-fase]').forEach(b => b.classList.toggle('is-active', b.dataset.fase === estadoCard.fase));
      }

      cardCtrl[w.id] = { estado: estadoCard, sync: syncCard };

      card.querySelector('.phase-switch').addEventListener('click', e => e.stopPropagation());
      card.querySelectorAll('button[data-pan]').forEach(btn => {
        btn.addEventListener('click', () => { estadoCard.pan = btn.dataset.pan; syncCard(); });
      });
      card.querySelectorAll('button[data-fase]').forEach(btn => {
        btn.addEventListener('click', () => { estadoCard.fase = btn.dataset.fase; syncCard(); });
      });
      card.querySelector('.world-media').addEventListener('click', () => abreModal(w.id, estadoCard.pan, estadoCard.fase));
      card.querySelector('.btn-inspect').addEventListener('click', () => abreModal(w.id, estadoCard.pan, estadoCard.fase));
      card.querySelector('.btn-try').addEventListener('click', () => {
        seleccionarTema(w.id);
        document.getElementById('visor').scrollIntoView({ behavior: 'smooth' });
      });

      gridEl.appendChild(card);
    }
  }
  renderCards();

  document.querySelectorAll('#cat-filters button[data-cat]').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('#cat-filters button[data-cat]').forEach(b => b.classList.remove('is-active'));
      btn.classList.add('is-active');
      const cat = btn.dataset.cat;
      document.querySelectorAll('.world-card').forEach(c => {
        c.classList.toggle('is-hidden', cat !== 'all' && c.dataset.cat !== cat);
      });
    });
  });

  document.querySelectorAll('button[data-global-pan]').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('button[data-global-pan]').forEach(b => b.classList.remove('is-active'));
      btn.classList.add('is-active');
      const p = btn.dataset.globalPan;
      Object.values(cardCtrl).forEach(ctrl => { ctrl.estado.pan = p; ctrl.sync(); });
    });
  });

  document.querySelectorAll('button[data-global-fase]').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('button[data-global-fase]').forEach(b => b.classList.remove('is-active'));
      btn.classList.add('is-active');
      const f = btn.dataset.globalFase;
      Object.values(cardCtrl).forEach(ctrl => { ctrl.estado.fase = f; ctrl.sync(); });
    });
  });

  /* MODAL LIGHTBOX 3 PANTALLAS */
  const modalEl = document.getElementById('world-modal');
  let modalState = { id: 'fittoa', pan: 'm1', fase: 'dorado' };

  function pintaModal() {
    const w = WORLDS.find(x => x.id === modalState.id) || WORLDS[0];
    const info = w[modalState.pan];
    document.getElementById('modal-serie').textContent = `${w.serie} · ID: ${w.id}`;
    document.getElementById('modal-title').textContent = `${w.titulo} — ${info.name}`;
    document.getElementById('modal-sub').textContent = info.sub;
    document.getElementById('modal-desc').textContent = info.desc;
    setPreviewImg(document.getElementById('modal-img'), previewUrl(w.id, modalState.pan, modalState.fase));
    document.getElementById('modal-quote').textContent = w.cita;

    document.querySelectorAll('#modal-pan-btns button').forEach(b => b.classList.toggle('is-active', b.dataset.mpan === modalState.pan));
    document.querySelectorAll('#modal-fase-btns button').forEach(b => b.classList.toggle('is-active', b.dataset.mfase === modalState.fase));

    const trip = document.getElementById('modal-triptych');
    trip.innerHTML = '';
    for (const pan of ['m1', 'm2', 'm3']) {
      const div = document.createElement('div');
      div.className = 'trip-thumb' + (modalState.pan === pan ? ' is-active' : '');
      div.innerHTML = `<img alt="${w[pan].name}" /><span>${pan.toUpperCase()} · ${w[pan].name}</span>`;
      setPreviewImg(div.querySelector('img'), previewUrl(w.id, pan, modalState.fase));
      div.addEventListener('click', () => { modalState.pan = pan; pintaModal(); });
      trip.appendChild(div);
    }
  }

  function abreModal(id, pan = 'm1', fase = 'dorado') {
    modalState = { id, pan, fase };
    pintaModal();
    modalEl.classList.add('is-open');
    modalEl.setAttribute('aria-hidden', 'false');
  }

  function cierraModal() {
    modalEl.classList.remove('is-open');
    modalEl.setAttribute('aria-hidden', 'true');
  }

  document.querySelectorAll('#modal-pan-btns button').forEach(b => b.addEventListener('click', () => { modalState.pan = b.dataset.mpan; pintaModal(); }));
  document.querySelectorAll('#modal-fase-btns button').forEach(b => b.addEventListener('click', () => { modalState.fase = b.dataset.mfase; pintaModal(); }));
  document.getElementById('modal-close').addEventListener('click', cierraModal);
  modalEl.addEventListener('click', e => { if (e.target === modalEl) cierraModal(); });
  document.addEventListener('keydown', e => { if (e.key === 'Escape') cierraModal(); });
  document.getElementById('modal-try').addEventListener('click', () => {
    cierraModal();
    seleccionarTema(modalState.id);
    document.getElementById('visor').scrollIntoView({ behavior: 'smooth' });
  });

  document.getElementById('btn-modal-active').addEventListener('click', () => abreModal(state.tema, 'm1', 'dorado'));
  document.getElementById('btn-stage-inspect').addEventListener('click', () => abreModal(state.tema, 'm1', 'dorado'));

  /* GENERADOR DE COMANDO DE INSTALACIÓN */
  const genMundo = document.getElementById('gen-mundo');
  const genModo = document.getElementById('gen-modo');
  const genMon = document.getElementById('gen-mon');
  const genCmd = document.getElementById('gen-cmd');
  const genCopy = document.getElementById('gen-copy');

  function actualizaComando() {
    if (!genMundo || !genCmd) return;
    const m = genMundo.value;
    const mod = genModo.value;
    const mon = genMon.value;
    const flagModo = mod === '21:30' ? '--hora 21:30' : `--${mod}`;
    const cmd = `python windows/pixelzen_win.py --tema ${m} ${flagModo} --monitores ${mon}`;
    genCmd.textContent = cmd;
    genCopy.dataset.copy = cmd;
  }
  [genMundo, genModo, genMon].forEach(el => { if (el) el.addEventListener('change', actualizaComando); });
  actualizaComando();

  /* TABS SO Y COPIAR AL PORTAPAPELES */
  document.querySelectorAll('.os-tab').forEach(tab => {
    tab.addEventListener('click', () => {
      document.querySelectorAll('.os-tab').forEach(t => t.classList.remove('is-active'));
      document.querySelectorAll('.os-pane').forEach(p => p.classList.remove('is-active'));
      tab.classList.add('is-active');
      const pane = document.querySelector(`.os-pane[data-pane="${tab.dataset.os}"]`);
      if (pane) pane.classList.add('is-active');
    });
  });

  document.querySelectorAll('.copy-btn, #btn-copy-oneliner').forEach(btn => {
    btn.addEventListener('click', async () => {
      try {
        await navigator.clipboard.writeText(btn.dataset.copy);
        const orig = btn.textContent;
        btn.textContent = '✓ ¡Copiado!';
        setTimeout(() => { btn.textContent = orig; }, 1400);
      } catch {
        btn.textContent = 'Usa Ctrl+C';
      }
    });
  });

  /* COMPARADOR DIVIDIDO DE FASES */
  const cmpMundo = document.getElementById('cmp-mundo');
  const cmpRange = document.getElementById('cmp-range');
  const cmpStage = document.getElementById('cmp-stage');
  const cmpImgL = document.getElementById('cmp-img-left');
  const cmpImgR = document.getElementById('cmp-img-right');
  const cmpLblL = document.getElementById('cmp-lbl-left');
  const cmpLblR = document.getElementById('cmp-lbl-right');
  const cmpState = { id: 'jujutsu-kaisen', pan: 'm1', left: 'dia', right: 'noche' };
  const phaseNames = { dia: 'DÍA', dorado: 'DORADO', noche: 'NOCHE' };

  function setImgWithFallback(imgEl, rel) {
    if (!imgEl) return;
    imgEl.dataset.fbApplied = '';
    imgEl.onerror = () => {
      if (imgEl.dataset.fbApplied === '1') return;
      imgEl.dataset.fbApplied = '1';
      imgEl.src = PREVIEW_FALLBACK_BASE + rel;
    };
    imgEl.src = rel;
  }

  function actualizaComparador() {
    if (!cmpStage) return;
    setImgWithFallback(cmpImgL, previewUrl(cmpState.id, cmpState.pan, cmpState.left));
    setImgWithFallback(cmpImgR, previewUrl(cmpState.id, cmpState.pan, cmpState.right));
    if (cmpLblL) cmpLblL.textContent = phaseNames[cmpState.left] || cmpState.left.toUpperCase();
    if (cmpLblR) cmpLblR.textContent = phaseNames[cmpState.right] || cmpState.right.toUpperCase();
  }

  if (cmpMundo && cmpStage) {
    for (const w of WORLDS) {
      const opt = document.createElement('option');
      opt.value = w.id;
      opt.textContent = `${w.anime || w.serie} · ${w.titulo}`;
      cmpMundo.appendChild(opt);
    }
    cmpMundo.value = cmpState.id;
    cmpMundo.addEventListener('change', () => { cmpState.id = cmpMundo.value; actualizaComparador(); });
    if (cmpRange) {
      cmpRange.addEventListener('input', () => {
        cmpStage.style.setProperty('--split', `${cmpRange.value}%`);
      });
    }
    document.querySelectorAll('[data-cmp-pan]').forEach(btn => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('[data-cmp-pan]').forEach(b => b.classList.remove('is-active'));
        btn.classList.add('is-active');
        cmpState.pan = btn.dataset.cmpPan;
        actualizaComparador();
      });
    });
    document.querySelectorAll('[data-cmp-left]').forEach(btn => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('[data-cmp-left]').forEach(b => b.classList.remove('is-active'));
        btn.classList.add('is-active');
        cmpState.left = btn.dataset.cmpLeft;
        actualizaComparador();
      });
    });
    document.querySelectorAll('[data-cmp-right]').forEach(btn => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('[data-cmp-right]').forEach(b => b.classList.remove('is-active'));
        btn.classList.add('is-active');
        cmpState.right = btn.dataset.cmpRight;
        actualizaComparador();
      });
    });
    actualizaComparador();
  }

  setInterval(() => { state.tick++; renderTodo(); }, 100);
  seleccionaYCarga(state.tema);
})();
