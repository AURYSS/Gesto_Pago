import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import ConflictModal from './ConflictModal';
import { ShieldCheck, ArrowLeft, ArrowRight } from 'lucide-react';

export default function TwoFactorModal() {
  const { tempAuth, verify2Fa, cancel2Fa, loading } = useAuth();
  const [codigo, setCodigo] = useState('');
  const [error, setError] = useState(null);

  // Estado para el modal de conflicto concurrente (409)
  const [conflictOpen, setConflictOpen] = useState(false);
  const [conflictDispositivo, setConflictDispositivo] = useState('Móvil');

  if (!tempAuth) return null;

  const handleSubmit = async (e, forzarCierre = false) => {
    if (e) e.preventDefault();
    if (!codigo || codigo.trim().length !== 6) {
      setError('Por favor ingresa un código de 6 dígitos');
      return;
    }

    setError(null);

    try {
      const result = await verify2Fa(codigo.trim(), forzarCierre);

      if (result.conflict) {
        setConflictDispositivo(result.dispositivoActivo || 'Móvil');
        setConflictOpen(true);
      }
    } catch (err) {
      setError(err.message || 'Código 2FA incorrecto o expirado');
    }
  };

  const handleConfirmConflict = async () => {
    setConflictOpen(false);
    await handleSubmit(null, true); // Enviar forzarCierre: true
  };

  return (
    <>
      <div className="modal-overlay">
        <div className="modal-card">
          <div className="modal-header">
            <div
              className="modal-icon-wrap"
              style={{
                background: 'rgba(16, 185, 129, 0.15)',
                border: '2px solid rgba(16, 185, 129, 0.4)',
                color: 'var(--primary)',
              }}
            >
              <ShieldCheck size={32} />
            </div>
            <h2 className="modal-title">Verificación de Doble Factor</h2>
            <p className="modal-subtitle">
              Revisa tu bandeja de entrada o spam. Ingresa el código OTP de 6 dígitos enviado a:<br />
              <strong style={{ color: 'var(--text-main)', fontSize: '0.95rem' }}>
                {tempAuth.correoEnmascarado || tempAuth.email}
              </strong>
            </p>
          </div>

          {error && (
            <div className="alert-banner danger">
              <span>{error}</span>
            </div>
          )}

          <form onSubmit={(e) => handleSubmit(e, false)}>
            <div className="form-group">
              <label className="form-label" style={{ textAlign: 'center' }}>
                Código de verificación (6 dígitos)
              </label>
              <input
                type="text"
                maxLength={6}
                value={codigo}
                onChange={(e) => setCodigo(e.target.value.replace(/\D/g, ''))}
                placeholder="000000"
                className="input-field otp-input"
                autoFocus
                disabled={loading}
              />
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem', marginTop: '1.5rem' }}>
              <button
                type="submit"
                className="btn btn-primary"
                disabled={loading || codigo.length !== 6}
                style={{ width: '100%', padding: '0.85rem' }}
              >
                {loading ? (
                  'Verificando código...'
                ) : (
                  <>
                    <span>Verificar e Iniciar Sesión</span>
                    <ArrowRight size={18} />
                  </>
                )}
              </button>

              <button
                type="button"
                className="btn btn-secondary"
                onClick={cancel2Fa}
                disabled={loading}
                style={{ width: '100%' }}
              >
                <ArrowLeft size={16} />
                <span>Volver al inicio de sesión</span>
              </button>
            </div>
          </form>
        </div>
      </div>

      {/* Modal interactivo de conflicto de sesión activa */}
      <ConflictModal
        isOpen={conflictOpen}
        dispositivo={conflictDispositivo}
        onConfirm={handleConfirmConflict}
        onCancel={() => setConflictOpen(false)}
        loading={loading}
      />
    </>
  );
}
