import React, { useState, useEffect } from 'react';
import { api } from '../services/api';
import {
  History,
  CheckCircle2,
  Clock,
  XCircle,
  RefreshCw,
  Search,
  ExternalLink,
  Receipt,
  Smartphone,
  Globe,
} from 'lucide-react';

export default function HistorialView() {
  const [transacciones, setTransacciones] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [busqueda, setBusqueda] = useState('');
  const [txDetalle, setTxDetalle] = useState(null);

  const cargarHistorial = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await api.getHistorial();
      setTransacciones(Array.isArray(data) ? data : []);
    } catch (err) {
      setError('No se pudo cargar el historial de transacciones.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    cargarHistorial();
  }, []);

  const transaccionesFiltradas = transacciones.filter((tx) => {
    if (!busqueda.trim()) return true;
    const q = busqueda.trim().toLowerCase();
    return (
      (tx.servicio && tx.servicio.toLowerCase().includes(q)) ||
      (tx.producto && tx.producto.toLowerCase().includes(q)) ||
      (tx.referencia && tx.referencia.toLowerCase().includes(q)) ||
      (tx.numeroAutorizacion && tx.numeroAutorizacion.toLowerCase().includes(q)) ||
      String(tx.id).includes(q)
    );
  });

  const getStatusBadge = (estado) => {
    const est = (estado || '').toUpperCase();
    if (est === 'APROBADA' || est === 'EXITOSA') {
      return (
        <span className="status-badge aprobada">
          <CheckCircle2 size={13} />
          <span>Exitosa</span>
        </span>
      );
    }
    if (est === 'PENDIENTE' || est === 'EN_PROCESO') {
      return (
        <span className="status-badge pendiente">
          <Clock size={13} />
          <span>Pendiente</span>
        </span>
      );
    }
    return (
      <span className="status-badge rechazada">
        <XCircle size={13} />
        <span>Rechazada</span>
      </span>
    );
  };

  const formatearFecha = (fechaStr) => {
    if (!fechaStr) return 'Reciente';
    try {
      const d = new Date(fechaStr);
      if (isNaN(d.getTime())) return fechaStr;
      return d.toLocaleString('es-MX', {
        dateStyle: 'medium',
        timeStyle: 'short',
      });
    } catch {
      return fechaStr;
    }
  };

  return (
    <div>
      {/* Header */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'flex-end',
          marginBottom: '1.75rem',
          flexWrap: 'wrap',
          gap: '1rem',
        }}
      >
        <div>
          <h1
            style={{
              fontSize: '1.85rem',
              fontWeight: 800,
              letterSpacing: '-0.02em',
              marginBottom: '0.4rem',
            }}
          >
            Historial de Compras y Transacciones
          </h1>
          <p style={{ color: 'var(--text-muted)', fontSize: '0.95rem' }}>
            Registro unificado de operaciones comerciales realizadas en Web y Móvil.
          </p>
        </div>

        <button
          className="btn btn-secondary"
          onClick={cargarHistorial}
          disabled={loading}
          style={{ fontSize: '0.85rem', padding: '0.5rem 1rem' }}
        >
          <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
          <span>Actualizar Historial</span>
        </button>
      </div>

      {/* Ecosystem synergy note */}
      <div
        style={{
          background: 'rgba(16, 185, 129, 0.08)',
          border: '1px solid rgba(16, 185, 129, 0.25)',
          borderRadius: '12px',
          padding: '0.9rem 1.25rem',
          marginBottom: '1.5rem',
          fontSize: '0.88rem',
          color: '#a7f3d0',
          display: 'flex',
          alignItems: 'center',
          gap: '12px',
        }}
      >
        <div style={{ display: 'flex', gap: '4px', color: '#10b981' }}>
          <Globe size={18} />
          <Smartphone size={18} />
        </div>
        <div>
          <strong>Ecosistema Unificado:</strong> Este apartado consulta las APIs centrales de Gesto Pago.
          Cualquier compra exitosa realizada desde la aplicación móvil aparecerá automáticamente aquí.
        </div>
      </div>

      {/* Buscador */}
      <div style={{ marginBottom: '1.5rem', maxWidth: '380px' }}>
        <div className="search-wrap">
          <Search size={18} />
          <input
            type="text"
            className="input-field search-input"
            placeholder="Buscar por referencia, servicio o folio..."
            value={busqueda}
            onChange={(e) => setBusqueda(e.target.value)}
          />
        </div>
      </div>

      {/* Estado de Carga */}
      {loading && (
        <div style={{ textAlign: 'center', padding: '4rem 0', color: 'var(--text-muted)' }}>
          <RefreshCw size={36} className="animate-spin" style={{ margin: '0 auto 1rem', color: 'var(--primary)' }} />
          <div>Consultando transacciones en Gesto Pago...</div>
        </div>
      )}

      {/* Estado de Error */}
      {error && !loading && (
        <div className="alert-banner danger">
          <div>{error}</div>
        </div>
      )}

      {/* Estado Vacío */}
      {!loading && !error && transaccionesFiltradas.length === 0 && (
        <div
          style={{
            textAlign: 'center',
            padding: '4rem 2rem',
            background: 'var(--bg-card)',
            borderRadius: '16px',
            border: '1px dashed var(--border-color)',
          }}
        >
          <Receipt size={48} color="var(--text-dim)" style={{ margin: '0 auto 1rem' }} />
          <h3 style={{ fontSize: '1.2rem', marginBottom: '0.5rem' }}>No hay transacciones registradas</h3>
          <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem' }}>
            Las compras realizadas desde la app móvil o desde esta web se mostrarán en esta tabla.
          </p>
        </div>
      )}

      {/* Tabla de Transacciones */}
      {!loading && !error && transaccionesFiltradas.length > 0 && (
        <div className="table-container">
          <table className="data-table">
            <thead>
              <tr>
                <th>Folio</th>
                <th>Fecha y Hora</th>
                <th>Servicio / Producto</th>
                <th>Referencia</th>
                <th>Importe</th>
                <th>Estado</th>
                <th>Autorización</th>
                <th style={{ textAlign: 'right' }}>Acción</th>
              </tr>
            </thead>
            <tbody>
              {transaccionesFiltradas.map((tx) => (
                <tr key={tx.id}>
                  <td>
                    <span style={{ fontWeight: 700, color: 'var(--primary)' }}>
                      #{tx.id}
                    </span>
                  </td>
                  <td style={{ color: 'var(--text-muted)', whiteSpace: 'nowrap' }}>
                    {formatearFecha(tx.fecha)}
                  </td>
                  <td>
                    <div style={{ fontWeight: 600 }}>{tx.servicio || 'Servicio'}</div>
                    <div style={{ fontSize: '0.75rem', color: 'var(--text-dim)' }}>
                      {tx.producto || 'Pago general'}
                    </div>
                  </td>
                  <td>
                    <code
                      style={{
                        background: 'rgba(255, 255, 255, 0.06)',
                        padding: '0.2rem 0.5rem',
                        borderRadius: '6px',
                        fontSize: '0.82rem',
                      }}
                    >
                      {tx.referencia}
                    </code>
                  </td>
                  <td>
                    <span style={{ fontWeight: 700, color: '#f8fafc', fontSize: '0.95rem' }}>
                      ${Number(tx.monto || 0).toFixed(2)}
                    </span>
                    <span style={{ fontSize: '0.72rem', color: 'var(--text-dim)', marginLeft: '4px' }}>
                      MXN
                    </span>
                  </td>
                  <td>{getStatusBadge(tx.estado)}</td>
                  <td style={{ color: 'var(--text-muted)', fontSize: '0.82rem' }}>
                    {tx.numeroAutorizacion || tx.idTx || '-'}
                  </td>
                  <td style={{ textAlign: 'right' }}>
                    <button
                      className="btn btn-secondary"
                      onClick={() => setTxDetalle(tx)}
                      style={{ padding: '0.35rem 0.75rem', fontSize: '0.8rem' }}
                    >
                      Detalle
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Modal de Detalle de Transacción */}
      {txDetalle && (
        <div className="modal-overlay">
          <div className="modal-card" style={{ maxWidth: '480px' }}>
            <div className="modal-header">
              <div
                className="modal-icon-wrap"
                style={{
                  background: 'rgba(16, 185, 129, 0.15)',
                  color: 'var(--primary)',
                }}
              >
                <Receipt size={32} />
              </div>
              <h2 className="modal-title">Comprobante de Operación</h2>
              <p className="modal-subtitle">Folio Oficial #{txDetalle.id}</p>
            </div>

            <div
              style={{
                background: 'var(--bg-input)',
                borderRadius: '12px',
                padding: '1.25rem',
                fontSize: '0.9rem',
                lineHeight: 1.9,
                marginBottom: '1.5rem',
                border: '1px solid var(--border-color)',
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
                <span style={{ color: 'var(--text-muted)' }}>Estado:</span>
                <span>{getStatusBadge(txDetalle.estado)}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
                <span style={{ color: 'var(--text-muted)' }}>Servicio:</span>
                <strong style={{ color: 'var(--text-main)' }}>{txDetalle.servicio}</strong>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
                <span style={{ color: 'var(--text-muted)' }}>Producto:</span>
                <span>{txDetalle.producto}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
                <span style={{ color: 'var(--text-muted)' }}>Referencia:</span>
                <span>{txDetalle.referencia}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
                <span style={{ color: 'var(--text-muted)' }}>Importe:</span>
                <strong style={{ color: 'var(--primary)', fontSize: '1.05rem' }}>
                  ${Number(txDetalle.monto || 0).toFixed(2)} MXN
                </strong>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
                <span style={{ color: 'var(--text-muted)' }}>No. Autorización:</span>
                <span>{txDetalle.numeroAutorizacion || 'N/A'}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: 'var(--text-muted)' }}>Fecha de Operación:</span>
                <span>{formatearFecha(txDetalle.fecha)}</span>
              </div>
            </div>

            <button
              className="btn btn-primary"
              onClick={() => setTxDetalle(null)}
              style={{ width: '100%' }}
            >
              Cerrar
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
