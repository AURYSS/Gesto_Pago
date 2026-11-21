import React, { createContext, useContext, useState, useEffect } from 'react';
import { api, setSessionRevokedHandler } from '../services/api';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(() => {
    try {
      const saved = localStorage.getItem('gp_user');
      return saved ? JSON.parse(saved) : null;
    } catch {
      return null;
    }
  });

  const [token, setToken] = useState(() => localStorage.getItem('gp_access_token'));
  const [step, setStep] = useState('login'); // 'login' | '2fa'
  const [tempAuth, setTempAuth] = useState(null); // { tempToken, email, codigo2FaDev, correoEnmascarado }
  const [revocationMessage, setRevocationMessage] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    // Suscribirse a la deteccion en tiempo real de revocacion de sesion
    setSessionRevokedHandler((mensaje) => {
      setUser(null);
      setToken(null);
      setStep('login');
      setTempAuth(null);
      setRevocationMessage(mensaje || 'Se inicio sesion en otro dispositivo.');
    });
  }, []);

  // Heartbeat activo para detectar cierre de sesion instantaneo si se abrio sesion en otro dispositivo o pestana
  useEffect(() => {
    if (!token || !user) return;

    const interval = setInterval(async () => {
      try {
        await api.request('/auth/validar-sesion');
      } catch (_) {
        // En caso de 401 por sesion revocada, api.request ya dispara el handler automaticamente
      }
    }, 2000);

    return () => clearInterval(interval);
  }, [token, user]);

  const login = async (email, password) => {
    setLoading(true);
    setRevocationMessage(null);
    try {
      const res = await api.login(email, password);

      if (!res.ok) {
        throw new Error(res.data.mensaje || res.data.error || 'Credenciales inválidas');
      }

      if (res.data.requiere2Fa) {
        setTempAuth({
          tempToken: res.data.tempToken,
          email: email.trim().toLowerCase(),
          codigo2FaDev: res.data.codigo2FaDev,
          correoEnmascarado: res.data.correoEnmascarado,
          dispositivo: res.data.dispositivo || 'WEB',
        });
        setStep('2fa');
        return { requiere2Fa: true, data: res.data };
      }

      // Si no requirió 2FA (sesión directa)
      const userData = {
        email: email.trim().toLowerCase(),
        nombre: res.data.nombre || email,
        roles: res.data.roles || ['CLIENTE'],
      };
      localStorage.setItem('gp_access_token', res.data.accessToken);
      if (res.data.refreshToken) {
        localStorage.setItem('gp_refresh_token', res.data.refreshToken);
      }
      localStorage.setItem('gp_user', JSON.stringify(userData));
      setToken(res.data.accessToken);
      setUser(userData);
      setStep('login');
      setTempAuth(null);
      return { requiere2Fa: false };
    } finally {
      setLoading(false);
    }
  };

  const verify2Fa = async (codigo, forzarCierre = false) => {
    if (!tempAuth?.tempToken) {
      throw new Error('No hay sesión de verificación activa');
    }
    setLoading(true);
    try {
      const res = await api.verify2Fa(tempAuth.tempToken, codigo, forzarCierre);

      // Si hay conflicto de sesion activa en otro dispositivo (409 Conflict)
      if (res.status === 409 || res.data.sesionActivaEnOtroDispositivo) {
        return {
          conflict: true,
          dispositivoActivo: res.data.dispositivoActivo || 'OTRO',
          mensaje:
            res.data.mensaje ||
            'Existe una sesion activa previa. Confirme si desea cerrar la sesion anterior para continuar aqui.',
        };
      }

      if (!res.ok) {
        throw new Error(res.data.mensaje || 'Código de verificación incorrecto o expirado');
      }

      const userData = {
        email: tempAuth.email,
        nombre: res.data.nombre || tempAuth.email,
        roles: res.data.roles || ['CLIENTE'],
      };

      localStorage.setItem('gp_access_token', res.data.accessToken);
      if (res.data.refreshToken) {
        localStorage.setItem('gp_refresh_token', res.data.refreshToken);
      }
      localStorage.setItem('gp_user', JSON.stringify(userData));
      setToken(res.data.accessToken);
      setUser(userData);
      setStep('login');
      setTempAuth(null);

      return { success: true };
    } finally {
      setLoading(false);
    }
  };

  const cancel2Fa = () => {
    setStep('login');
    setTempAuth(null);
  };

  const logout = async () => {
    setLoading(true);
    try {
      await api.logout();
    } finally {
      setUser(null);
      setToken(null);
      setStep('login');
      setTempAuth(null);
      setLoading(false);
    }
  };

  const clearRevocationMessage = () => {
    setRevocationMessage(null);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        isAuthenticated: !!token && !!user,
        step,
        tempAuth,
        revocationMessage,
        loading,
        login,
        verify2Fa,
        cancel2Fa,
        logout,
        clearRevocationMessage,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth debe usarse dentro de un AuthProvider');
  }
  return context;
}
