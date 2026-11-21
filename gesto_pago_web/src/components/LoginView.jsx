import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { CreditCard, Mail, Lock, LogIn, AlertCircle, AlertTriangle } from 'lucide-react';

export default function LoginView() {
  const { login, revocationMessage, clearRevocationMessage, loading } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError(null);

    if (!email.trim() || !password) {
      setError('Por favor completa todos los campos');
      return;
    }

    try {
      await login(email, password);
      // Si requiere 2FA, el contexto cambia a step='2fa' y muestra TwoFactorModal
    } catch (err) {
      setError(err.message || 'Error al iniciar sesión');
    }
  };

  return (
    <div
      style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '1.5rem',
        background: 'radial-gradient(ellipse at top, #131a29 0%, #0a0e17 70%)',
      }}
    >
      <div
        className="modal-card"
        style={{
          maxWidth: '460px',
          boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.7)',
        }}
      >
        {/* Header */}
        <div className="modal-header">
          <div className="brand-icon" style={{ width: '56px', height: '56px', margin: '0 auto 1.25rem' }}>
            <CreditCard size={28} />
          </div>
          <h1 className="modal-title" style={{ fontSize: '1.5rem' }}>
            Gesto Pago Web
          </h1>
          <p className="modal-subtitle">
            Acceso unificado al ecosistema de comercio digital
          </p>
        </div>

        {/* Banner de sesion revocada (Cuando se abrio sesion en otro dispositivo o pestana) */}
        {revocationMessage && (
          <div className="alert-banner warning" style={{ marginBottom: '1.25rem', borderLeft: '4px solid #f59e0b', padding: '1rem' }}>
            <AlertTriangle size={22} color="#f59e0b" style={{ flexShrink: 0, marginTop: '2px' }} />
            <div>
              <div style={{ fontWeight: 700, marginBottom: '4px', color: '#fef3c7' }}>Sesion finalizada</div>
              <div style={{ color: '#fef3c7', fontSize: '0.9rem' }}>{revocationMessage}</div>
            </div>
          </div>
        )}

        {/* Error regular */}
        {error && (
          <div className="alert-banner danger">
            <AlertCircle size={20} style={{ flexShrink: 0, marginTop: '2px' }} />
            <div>{error}</div>
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label className="form-label">Correo electrónico</label>
            <div style={{ position: 'relative' }}>
              <input
                type="email"
                className="input-field"
                placeholder="ejemplo@correo.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                disabled={loading}
                required
                style={{ paddingLeft: '2.5rem' }}
              />
              <Mail
                size={18}
                color="var(--text-dim)"
                style={{ position: 'absolute', left: '0.85rem', top: '50%', transform: 'translateY(-50%)' }}
              />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Contraseña</label>
            <div style={{ position: 'relative' }}>
              <input
                type="password"
                className="input-field"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                disabled={loading}
                required
                style={{ paddingLeft: '2.5rem' }}
              />
              <Lock
                size={18}
                color="var(--text-dim)"
                style={{ position: 'absolute', left: '0.85rem', top: '50%', transform: 'translateY(-50%)' }}
              />
            </div>
          </div>

          <button
            type="submit"
            className="btn btn-primary"
            disabled={loading}
            style={{ width: '100%', marginTop: '1.5rem', padding: '0.85rem' }}
          >
            {loading ? (
              'Comprobando credenciales...'
            ) : (
              <>
                <LogIn size={18} />
                <span>Continuar a 2FA</span>
              </>
            )}
          </button>
        </form>

        <div
          style={{
            marginTop: '2rem',
            paddingTop: '1.25rem',
            borderTop: '1px solid var(--border-color)',
            textAlign: 'center',
            fontSize: '0.8rem',
            color: 'var(--text-dim)',
            lineHeight: 1.5,
          }}
        >
          Mismas credenciales que la aplicación móvil Flutter.
          <br />
          El sistema protege tu cuenta solicitando un código 2FA y garantizando una sola sesión activa.
        </div>
      </div>
    </div>
  );
}
