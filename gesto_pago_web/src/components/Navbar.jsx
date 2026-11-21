import React from 'react';
import { useAuth } from '../context/AuthContext';
import {
  CreditCard,
  ShoppingBag,
  History,
  LogOut,
  User,
  ShieldCheck,
} from 'lucide-react';

export default function Navbar({ activeTab, setActiveTab }) {
  const { user, logout, loading } = useAuth();

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

        {/* User profile & Logout */}
        <div className="user-section">
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
