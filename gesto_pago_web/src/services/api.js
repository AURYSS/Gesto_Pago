// Cliente de API para GestoPago Web

const API_BASE = import.meta.env.VITE_API_URL || '';

let onSessionRevokedCallback = null;

export function setSessionRevokedHandler(handler) {
  onSessionRevokedCallback = handler;
}

export async function request(endpoint, options = {}) {
  const token = localStorage.getItem('gp_access_token');

  const headers = {
    'Content-Type': 'application/json',
    ...(options.headers || {}),
  };

  if (token && !headers.Authorization) {
    headers.Authorization = `Bearer ${token}`;
  }

  const url = `${API_BASE}${endpoint}`;

  try {
    const response = await fetch(url, {
      ...options,
      headers,
    });

    // Manejo de revocación de sesión por inicio en móvil (401 con SESION_REVOCADA / AUTH-009)
    if (response.status === 401) {
      let data = {};
      try {
        data = await response.clone().json();
      } catch (_) {}

      const msg = data.mensaje || data.error || '';
      const codigo = data.codigo || data.codigoEstado || '';

      if (
        codigo === 'AUTH-009' ||
        msg.toUpperCase().includes('REVOCADA') ||
        msg.toUpperCase().includes('OTRO DISPOSITIVO') ||
        endpoint === '/auth/validar-sesion'
      ) {
        localStorage.removeItem('gp_access_token');
        localStorage.removeItem('gp_refresh_token');
        localStorage.removeItem('gp_user');
        if (onSessionRevokedCallback) {
          onSessionRevokedCallback(
            data.mensaje || 'Se inicio sesion en otro dispositivo.'
          );
        }
      }
    }

    return response;
  } catch (error) {
    console.error('Error en petición de red:', error);
    throw error;
  }
}

export const api = {
  request,
  // --- Autenticación y 2FA ---
  async login(email, password) {
    const res = await request('/auth/login', {
      method: 'POST',
      body: JSON.stringify({
        email: email.trim().toLowerCase(),
        password,
        dispositivo: 'WEB',
      }),
    });
    const data = await res.json();
    return { status: res.status, ok: res.ok, data };
  },

  async verify2Fa(tempToken, codigo, forzarCierre = false) {
    const res = await request('/auth/2fa/verify', {
      method: 'POST',
      body: JSON.stringify({
        tempToken,
        codigo: codigo.trim(),
        forzarCierre,
      }),
    });
    const data = await res.json();
    return { status: res.status, ok: res.ok, data };
  },

  async logout() {
    const refreshToken = localStorage.getItem('gp_refresh_token');
    try {
      await request('/auth/logout', {
        method: 'POST',
        headers: refreshToken ? { Authorization: `Refresh ${refreshToken}` } : {},
      });
    } catch (_) {
      // Ignorar error al salir
    } finally {
      localStorage.removeItem('gp_access_token');
      localStorage.removeItem('gp_refresh_token');
      localStorage.removeItem('gp_user');
    }
  },

  // --- Catálogo Comercial ---
  async getMarcas() {
    const res = await request('/catalogo/marcas');
    if (!res.ok) throw new Error('No se pudo cargar el catálogo de marcas');
    return await res.json();
  },

  async getProductos() {
    const res = await request('/catalogo/productos');
    if (!res.ok) throw new Error('No se pudo cargar la lista de productos');
    return await res.json();
  },

  // --- Pagos y Transacciones ---
  async crearTransaccion(pagoData) {
    const res = await request('/pagos/transacciones', {
      method: 'POST',
      body: JSON.stringify(pagoData),
    });
    const data = await res.json();
    return { status: res.status, ok: res.ok, data };
  },

  async getHistorial() {
    const res = await request('/pagos/transacciones');
    if (!res.ok) throw new Error('No se pudo obtener el historial');
    return await res.json();
  },
};
