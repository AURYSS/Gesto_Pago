import React, { useState, useEffect, useRef } from 'react';
import { useAuth } from '../context/AuthContext';
import { api } from '../services/api';
import {
  CreditCard,
  ShoppingBag,
  History,
  LogOut,
  User,
  ShieldCheck,
  Bell,
  CheckCircle2,
  Clock,
  ArrowRight,
  Mail,
  X,
} from 'lucide-react';

export default function Navbar({ activeTab, setActiveTab }) {
  const { user, logout, loading } = useAuth();
  const [showNotifications, setShowNotifications] = useState(false);
  const [movimientos, setMovimientos] = useState([]);
  const [hasUnread, setHasUnread] = useState(false);
  const dropdownRef = useRef(null);

  // Cargar últimos movimientos para el centro de notificaciones
  const cargarMovimientos = async () => {
    try {
      const data = await api.getHistorial();
      if (Array.isArray(data)) {
        // Tomar los últimos 6 movimientos
        const ultimos = data.slice(0, 6);
        setMovimientos(ultimos);
        if (ultimos.length > 0) {
          setHasUnread(true);
        }
      }
    } catch (_) {
      // Ignorar fallo de red silencioso
    }
  };

  useEffect(() => {
    if (user) {
      cargarMovimientos();
      // Polling sutil cada 10 segundos para actualizar movimientos
      const interval = setInterval(cargarMovimientos, 10000);
      return () => clearInterval(interval);
    }
  }, [user]);

  // Cerrar dropdown al hacer click afuera
  useEffect(() => {
    const handleClickOutside = (e) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target)) {
        setShowNotifications(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleToggleNotifications = () => {
    setShowNotifications((prev) => !prev);
    setHasUnread(false);
  };

  return (
    <nav className="navbar">
      <div className="navbar-inner">
        {/* Brand */}
        <div className="brand" onClick={() => setActiveTab('catalogo')}>
          <div className="brand-icon">
            <CreditCard size={22} />
          </div>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <span className="brand-title">Gesto Pago</span>
              <span className="badge-web">Plataforma Web</span>
            </div>
            <div style={{ fontSize: '0.72rem', color: 'var(--text-dim)', marginTop: '-2px' }}>
              Ecosistema de Comercio Digital
            </div>
          </div>
        </div>

        {/* Navigation Tabs */}
        <div className="nav-links">
          <button
            className={`nav-btn ${activeTab === 'catalogo' ? 'active' : ''}`}
            onClick={() => setActiveTab('catalogo')}
          >
            <ShoppingBag size={18} />
            <span>Catálogo de Servicios</span>
          </button>
          <button
            className={`nav-btn ${activeTab === 'historial' ? 'active' : ''}`}
            onClick={() => setActiveTab('historial')}
          >
            <History size={18} />
            <span>Historial de Compras</span>
          </button>
        </div>

        {/* User profile, Notifications & Logout */}
        <div className="user-section" style={{ position: 'relative' }} ref={dropdownRef}>
          {/* Botón de Notificaciones de Movimientos */}
          <button
            type="button"
            className="nav-btn"
            style={{
              position: 'relative',
              padding: '0.55rem',
              borderRadius: '10px',
              border: '1px solid var(--border-color)',
              background: showNotifications ? 'var(--bg-card-hover)' : 'var(--bg-card)',
            }}
            onClick={handleToggleNotifications}
            title="Notificaciones de movimientos transaccionales"
          >
            <Bell size={18} color={hasUnread ? '#34d399' : 'var(--text-muted)'} />
            {hasUnread && movimientos.length > 0 && (
              <span className="notification-badge-count">{movimientos.length}</span>
            )}
          </button>

          {/* Menú Desplegable de Notificaciones */}
          {showNotifications && (
            <div className="notifications-dropdown">
              <div className="notifications-header">
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <Bell size={16} color="#10b981" />
                  <strong style={{ fontSize: '0.9rem' }}>Movimientos Recientes</strong>
                </div>
                <button
                  type="button"
                  onClick={() => setShowNotifications(false)}
                  style={{ background: 'none', border: 'none', color: 'var(--text-dim)', cursor: 'pointer' }}
                >
                  <X size={16} />
                </button>
              </div>

              <div className="notifications-body">
                {movimientos.length === 0 ? (
                  <div style={{ padding: '2rem 1.5rem', textAlign: 'center', color: 'var(--text-dim)', fontSize: '0.85rem' }}>
                    <Clock size={28} style={{ margin: '0 auto 0.5rem', opacity: 0.5 }} />
                    <p>No tienes movimientos registrados recientemente.</p>
                  </div>
                ) : (
                  movimientos.map((m) => {
                    const est = (m.estado || '').toUpperCase();
                    const isOk = est === 'APROBADA' || est === 'EXITOSA';
                    return (
                      <div
                        key={m.id || m.upc}
                        className="notification-item"
                        onClick={() => {
                          setActiveTab('historial');
                          setShowNotifications(false);
                        }}
                      >
                        <div
                          style={{
                            width: '32px',
                            height: '32px',
                            borderRadius: '8px',
                            background: isOk ? 'rgba(16, 185, 129, 0.15)' : 'rgba(245, 158, 11, 0.15)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            flexShrink: 0,
                            marginTop: '2px',
                          }}
                        >
                          {isOk ? <CheckCircle2 size={16} color="#34d399" /> : <Clock size={16} color="#fbbf24" />}
                        </div>
                        <div style={{ flex: 1, minWidth: 0 }}>
                          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                            <strong style={{ fontSize: '0.85rem', color: 'var(--text-main)' }}>
                              {m.servicio || m.producto || 'Transacción'}
                            </strong>
                            <span style={{ fontSize: '0.82rem', fontWeight: 700, color: '#34d399' }}>
                              ${Number(m.monto || 0).toFixed(2)}
                            </span>
                          </div>
                          <div style={{ fontSize: '0.74rem', color: 'var(--text-dim)', marginTop: '2px' }}>
                            Folio: {m.upc || m.numeroAutorizacion || `#${m.id}`} &bull; Ref: {m.referencia}
                          </div>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '0.7rem', color: '#10b981', marginTop: '4px' }}>
                            <Mail size={11} />
                            <span>Comprobante notificado al correo</span>
                          </div>
                        </div>
                      </div>
                    );
                  })
                )}
              </div>

              {movimientos.length > 0 && (
                <div
                  style={{
                    padding: '0.65rem',
                    borderTop: '1px solid var(--border-color)',
                    textAlign: 'center',
                    background: '#0f1523',
                  }}
                >
                  <button
                    type="button"
                    onClick={() => {
                      setActiveTab('historial');
                      setShowNotifications(false);
                    }}
                    style={{
                      background: 'none',
                      border: 'none',
                      color: 'var(--primary)',
                      fontSize: '0.8rem',
                      fontWeight: 700,
                      cursor: 'pointer',
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: '4px',
                    }}
                  >
                    <span>Ver historial completo</span>
                    <ArrowRight size={14} />
                  </button>
                </div>
              )}
            </div>
          )}

          {/* Chip de Usuario */}
          {user && (
            <div className="user-chip">
              <div className="user-avatar">
                {user.nombre ? user.nombre.charAt(0).toUpperCase() : <User size={14} />}
              </div>
              <div>
                <div style={{ fontWeight: 600, fontSize: '0.85rem' }}>
                  {user.nombre || 'Usuario'}
                </div>
                <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>
                  {user.email}
                </div>
              </div>
              <span
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '4px',
                  fontSize: '0.7rem',
                  color: 'var(--primary)',
                  marginLeft: '0.4rem',
                  fontWeight: 600,
                }}
                title="Sesión activa y verificada"
              >
                <ShieldCheck size={14} /> Activo
              </span>
            </div>
          )}

          {/* Botón Salir */}
          <button
            className="logout-btn"
            onClick={logout}
            disabled={loading}
            title="Cerrar sesión de manera segura"
          >
            <LogOut size={16} />
            <span>Salir</span>
          </button>
        </div>
      </div>
    </nav>
  );
}
