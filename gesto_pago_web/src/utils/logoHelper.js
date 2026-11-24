// Helper para resolución y mapeo de logotipos de servicios y marcas oficiales

const BRAND_RULES = [
  // Telefonía & Móvil
  { keys: ['telcel', 'amigo'], file: 'telcel.svg' },
  { keys: ['at&t', 'att', 'at-t', 'at and t'], file: 'att.svg' },
  { keys: ['movistar'], file: 'movistar.png' },
  { keys: ['unefon'], file: 'unefon.png' },
  { keys: ['bait'], file: 'bait.png' },
  { keys: ['pillofon'], file: 'pillofon.png' },
  { keys: ['virgin mobile', 'virgin'], file: 'virgin_mobile.png' },

  // Internet, Cable & TV
  { keys: ['telmex', 'infinitum'], file: 'telmex.svg' },
  { keys: ['totalplay', 'total play'], file: 'totalplay.png' },
  { keys: ['izzi', 'wizz'], file: 'izzi.svg' },
  { keys: ['megacable'], file: 'megacable.svg' },
  { keys: ['dish'], file: 'dish.svg' },
  { keys: ['sky', 'vetv'], file: 'sky.svg' },
  { keys: ['startv', 'star tv', 'stargo'], file: 'startv.png' },
  { keys: ['axtel'], file: 'axtel.png' },

  // Servicios Básicos (Luz, Agua, Gas)
  { keys: ['cfe', 'comision federal'], file: 'cfe.svg' },
  { keys: ['naturgy', 'gas natural'], file: 'naturgy.png' },
  { keys: ['engie', 'maxigas'], file: 'engie.png' },
  { keys: ['zeta gas', 'zetagas'], file: 'zeta_gas.png' },
  { keys: ['sacmex', 'segiagua', 'agua cdmx'], file: 'sacmex.png' },

  // Peajes y Tags
  { keys: ['pase', 'tag pase'], file: 'pase.png' },
  { keys: ['televia', 'tag televia'], file: 'televia.png' },

  // Gobierno e Impuestos
  { keys: ['sat', 'impuestos sat'], file: 'sat.png' },
  { keys: ['infonavit'], file: 'infonavit.png' },
  { keys: ['ciudad de mexico', 'cdmx', 'tesoreria cdmx'], file: 'gob_cdmx.png' },
  { keys: ['estado de mexico', 'edomex'], file: 'gob_edomex.png' },

  // Streaming, Gaming & Entretenimiento
  { keys: ['netflix'], file: 'netflix.png' },
  { keys: ['spotify'], file: 'spotify.png' },
  { keys: ['amazon', 'prime video'], file: 'amazon.png' },
  { keys: ['apple', 'itunes'], file: 'apple.png' },
  { keys: ['google play', 'play store', 'googleplay'], file: 'google_play.png' },
  { keys: ['playstation', 'psn'], file: 'playstation.png' },
  { keys: ['xbox', 'game pass'], file: 'xbox.png' },
  { keys: ['nintendo'], file: 'nintendo.png' },
  { keys: ['steam'], file: 'steam.png' },
  { keys: ['free fire', 'freefire'], file: 'free_fire.png' },
  { keys: ['roblox'], file: 'roblox.png' },
  { keys: ['cinepolis', 'cinépolis'], file: 'cinepolis.png' },
  { keys: ['cinemex'], file: 'cinemex.png' },

  // Lifestyle, Café & Movilidad
  { keys: ['starbucks'], file: 'starbucks.png' },
  { keys: ['didi'], file: 'didi.png' },
  { keys: ['uber'], file: 'uber.png' },

  // Venta por Catálogo & Retail
  { keys: ['andrea'], file: 'andrea.png' },
  { keys: ['avon'], file: 'avon.png' },
  { keys: ['betterware'], file: 'betterware.png' },
  { keys: ['herbalife'], file: 'herbalife.png' },
  { keys: ['jafra'], file: 'jafra.png' },
  { keys: ['mary kay', 'marykay'], file: 'mary_kay.png' },
  { keys: ['natura'], file: 'natura.png' },
  { keys: ['price shoes', 'priceshoes'], file: 'price_shoes.png' },
  { keys: ['tupperware'], file: 'tupperware.png' },
];

export function normalizeText(text) {
  if (!text) return '';
  return String(text)
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .trim();
}

/**
 * Obtiene la ruta del logotipo oficial para un servicio / marca / producto
 */
export function getServiceLogoUrl(serviceName, brandName, slug) {
  const normCandidates = [
    normalizeText(slug),
    normalizeText(brandName),
    normalizeText(serviceName),
  ].filter(Boolean);

  if (normCandidates.length === 0) return null;

  for (const rule of BRAND_RULES) {
    for (const key of rule.keys) {
      for (const cand of normCandidates) {
        if (cand === key || cand.includes(key)) {
          return `/logos/${rule.file}`;
        }
      }
    }
  }

  return null;
}

/**
 * Obtiene las iniciales representativas de un servicio o marca
 */
export function getInitials(name) {
  if (!name) return 'GP';
  const clean = name.trim().replace(/[^a-zA-Z0-9\s]/g, '');
  const words = clean.split(/\s+/).filter(Boolean);
  if (words.length === 1) {
    return words[0].substring(0, 2).toUpperCase();
  }
  return (words[0][0] + words[1][0]).toUpperCase();
}
