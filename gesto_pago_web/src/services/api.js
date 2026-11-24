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

  async register(nombre, email, password) {
    const res = await request('/auth/register', {
      method: 'POST',
      body: JSON.stringify({
        nombre: nombre.trim(),
        email: email.trim().toLowerCase(),
        password,
      }),
    });
    const data = await res.json();
    return { status: res.status, ok: res.ok, data };
  },

  async registerPersonaFisica(data) {
    // 1. Intentar registrar en micro-usuarios (/api/clientes)
    let microData = null;
    try {
      const clientePayload = {
        cliente: {
          nombre: data.nombre.trim(),
          segundoNombre: data.segundoNombre?.trim() || null,
          apellidoPaterno: data.apellidoPaterno.trim(),
          apellidoMaterno: data.apellidoMaterno.trim(),
          fechaNacimiento: data.fechaNacimiento,
          curp: data.curp.trim().toUpperCase(),
          rfc: data.rfc.trim().toUpperCase(),
          sexo: data.sexo,
          nacionalidad: data.nacionalidad.trim(),
          estadoCivil: data.estadoCivil,
          correo: data.correo.trim().toLowerCase(),
          telefonoMovil: data.telefonoMovil.trim(),
          telefonoAlternativo: data.telefonoAlternativo?.trim() || null,
          ocupacion: data.ocupacion.trim(),
          empresa: data.empresa.trim(),
          ingresoMensual: parseFloat(data.ingresoMensual),
          domicilio: {
            calle: data.calle.trim(),
            numeroExterior: data.numeroExterior.trim(),
            numeroInterior: data.numeroInterior?.trim() || null,
            colonia: data.colonia.trim(),
            codigoPostal: data.codigoPostal.trim(),
            municipio: data.municipio.trim(),
            estado: data.estado.trim(),
            pais: data.pais.trim(),
          },
        },
        password: data.password,
      };

      const resMicro = await fetch('/api/clientes', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(clientePayload),
      });

      if (resMicro.ok) {
        microData = await resMicro.json();
      }
    } catch (_) {
      // Ignorar fallo si micro-usuarios no está levantado en puerto 8081
    }

    // 2. Registrar en api-gesto-pago (/auth/register) para autenticación unificada
    const fullName = `${data.nombre.trim()} ${data.apellidoPaterno.trim()}${
      data.apellidoMaterno ? ' ' + data.apellidoMaterno.trim() : ''
    }`;

    const resAuth = await request('/auth/register', {
      method: 'POST',
      body: JSON.stringify({
        nombre: fullName,
        email: data.correo.trim().toLowerCase(),
        password: data.password,
      }),
    });

    const authData = await resAuth.json();
    return {
      status: resAuth.status,
      ok: resAuth.ok,
      data: authData,
      microData,
    };
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
