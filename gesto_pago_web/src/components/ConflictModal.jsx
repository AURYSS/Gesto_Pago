import React from 'react';
import { Smartphone, AlertTriangle, ArrowRight, Monitor } from 'lucide-react';

export default function ConflictModal({ isOpen, dispositivo, onConfirm, onCancel, loading }) {
  if (!isOpen) return null;

  const esWeb = (dispositivo || '').toUpperCase() === 'WEB';

  return (
    <div className="modal-overlay">
      <div className="modal-card" style={{ maxWidth: '480px' }}>
        <div className="modal-header">
          <div
            className="modal-icon-wrap"
            style={{
              background: 'rgba(245, 158, 11, 0.15)',
              border: '2px solid rgba(245, 158, 11, 0.4)',
              color: '#f59e0b',
            }}
          >
            {esWeb ? <Monitor size={32} /> : <Smartphone size={32} />}
          </div>
          <h2 className="modal-title">Sesion activa detectada</h2>
          <p className="modal-subtitle">
            Seguridad y control de sesion unica
          </p>
        </div>

        <div
          style={{
            background: 'rgba(245, 158, 11, 0.08)',
            border: '1px solid rgba(245, 158, 11, 0.25)',
            borderRadius: '12px',
            padding: '1.25rem',
            marginBottom: '1.5rem',
            fontSize: '0.92rem',
            lineHeight: 1.6,
            color: '#fef3c7',
          }}
        >
          <div style={{ display: 'flex', gap: '10px', alignItems: 'flex-start' }}>
            <AlertTriangle size={20} color="#f59e0b" style={{ flexShrink: 0, marginTop: '2px' }} />
            <div>
              Detectamos una sesion activa previa en <strong>{esWeb ? 'otro navegador o ventana Web' : 'la aplicacion movil'}</strong>.
              <br /><br />
              Para garantizar la seguridad de tu cuenta, solo se permite mantener <strong>una sesion activa a la vez</strong>.
              <br /><br />
              ¿Deseas cerrar la sesion anterior y continuar aqui?
            </div>
          </div>
        </div>

        <div style={{ display: 'flex', gap: '0.75rem', justifyContent: 'flex-end' }}>
          <button
            type="button"
            className="btn btn-secondary"
            onClick={onCancel}
            disabled={loading}
          >
            Cancelar
          </button>
          <button
            type="button"
            className="btn btn-primary"
            onClick={onConfirm}
            disabled={loading}
            style={{ background: '#f59e0b', color: '#000', fontWeight: 700 }}
          >
            {loading ? (
              'Cerrando sesion previa...'
            ) : (
              <>
                <span>Cerrar sesion anterior y continuar</span>
                <ArrowRight size={16} />
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
}
