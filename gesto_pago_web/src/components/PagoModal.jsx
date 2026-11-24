import React, { useState } from 'react';
import { api } from '../services/api';
import {
  CreditCard,
  CheckCircle2,
  XCircle,
  Clock,
  AlertTriangle,
  Receipt,
  X,
  ArrowRight,
  ShieldCheck,
  Mail,
} from 'lucide-react';

export default function PagoModal({ producto, marca, onClose, onPagoCompletado }) {
  const [referencia, setReferencia] = useState('');
  const [monto, setMonto] = useState(
    producto?.precio ? Number(producto.precio).toFixed(2) : '100.00'
  );
  const [loading, setLoading] = useState(false);
  const [resultado, setResultado] = useState(null); // { estado, transaccion, error }

  React.useEffect(() => {
    if (producto) {
      setMonto(producto?.precio ? Number(producto.precio).toFixed(2) : '100.00');
      setReferencia('');
      setResultado(null);
    }
  }, [producto?.id, producto?.idServicio, producto?.idProducto]);

  if (!producto) return null;

  const esMontoFijo = producto.precio && Number(producto.precio) > 0;

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!referencia.trim()) {
      alert('Ingresa la referencia o número de servicio');
      return;
    }
    if (!monto || Number(monto) <= 0) {
      alert('Ingresa un monto válido mayor a 0');
      return;
    }

    if (!producto?.idServicio || !producto?.idProducto) {
      alert('Este producto no tiene un identificador de catálogo válido (idServicio / idProducto). Por favor selecciona un producto del catálogo.');
      return;
    }

    setLoading(true);

    try {
      const idempotencyKey =
        typeof crypto?.randomUUID === 'function'
          ? crypto.randomUUID()
          : `web-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;

      const payload = {
        idServicio: Number(producto.idServicio),
        idProducto: Number(producto.idProducto),
        referencia: referencia.trim(),
        monto: Number(monto),
        idempotencyKey,
      };

      const res = await api.crearTransaccion(payload);

      if (res.ok && res.data) {
        const tx = res.data;
        const estadoApi = (tx.estado || '').toUpperCase();

        if (estadoApi === 'APROBADA' || estadoApi === 'EXITOSA') {
          setResultado({ estado: 'EXITOSA', transaccion: tx });
        } else if (estadoApi === 'PENDIENTE' || estadoApi === 'EN_PROCESO') {
          setResultado({ estado: 'PENDIENTE', transaccion: tx });
        } else {
          setResultado({
            estado: 'RECHAZADA',
            transaccion: tx,
            mensaje: tx.errorMensaje || 'La transacción fue rechazada por el proveedor.',
          });
        }

        if (onPagoCompletado) {
          onPagoCompletado();
        }
      } else {
        setResultado({
          estado: 'RECHAZADA',
          mensaje:
            res.data?.message ||
            res.data?.mensaje ||
            res.data?.error ||
            'No se pudo completar la operación de pago.',
        });
      }
    } catch (err) {
      setResultado({
        estado: 'ERROR_COMUNICACION',
        mensaje:
          err.message ||
          'Error de comunicación con el servicio de pagos. Intenta nuevamente.',
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-overlay">
      <div className="modal-card" style={{ maxWidth: '540px' }}>
        {/* Close button */}
        <button
          onClick={onClose}
          style={{
            position: 'absolute',
            right: '1.25rem',
            top: '1.25rem',
            background: 'transparent',
            border: 'none',
            color: 'var(--text-dim)',
            cursor: 'pointer',
          }}
        >
          <X size={20} />
        </button>

        {/* Si aún no se procesa la transacción: Formulario de Pago */}
        {!resultado ? (
          <div>
            <div className="modal-header" style={{ textAlign: 'left', marginBottom: '1.25rem' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.5rem' }}>
                <span
                  className="brand-badge"
                  style={{
                    backgroundColor: marca?.color ? `${marca.color}22` : 'rgba(16, 185, 129, 0.15)',
                    color: marca?.color || 'var(--primary)',
                    border: `1px solid ${marca?.color || 'var(--primary)'}55`,
                  }}
                >
                  {marca?.nombre || 'Servicio'}
                </span>
                <span style={{ fontSize: '0.8rem', color: 'var(--text-dim)' }}>
                  ID: #{producto.idProducto || producto.id}
                </span>
              </div>
              <h2 className="modal-title" style={{ fontSize: '1.35rem' }}>
                {producto.nombre || 'Pago de Servicio'}
              </h2>
              <p className="modal-subtitle">
                {producto.descripcion || 'Ingresa los datos para confirmar la operación comercial'}
              </p>
            </div>

            <form onSubmit={handleSubmit}>
              <div className="form-group">
                <label className="form-label">
                  Referencia / Número de Teléfono / Contrato
                </label>
                <input
                  type="text"
                  className="input-field"
                  placeholder="Ej. 4181234567 o número de cuenta"
                  value={referencia}
                  onChange={(e) => setReferencia(e.target.value)}
                  disabled={loading}
                  required
                  autoFocus
                />
                <span style={{ fontSize: '0.75rem', color: 'var(--text-dim)' }}>
                  Asegúrate de capturar la referencia exactamente como aparece en tu recibo.
                </span>
              </div>

              <div className="form-group">
                <label className="form-label">Importe a Pagar ($ MXN)</label>
                <input
                  type="number"
                  step="0.50"
                  min="1"
                  className="input-field"
                  value={monto}
                  onChange={(e) => setMonto(e.target.value)}
                  disabled={loading || esMontoFijo}
                  required
                />
                {esMontoFijo && (
                  <span style={{ fontSize: '0.75rem', color: 'var(--primary)' }}>
                    Precio fijo estipulado por el catalogo oficial.
                  </span>
                )}
              </div>

              <div
                style={{
                  background: 'rgba(255, 255, 255, 0.03)',
                  border: '1px solid var(--border-color)',
                  borderRadius: '12px',
                  padding: '1rem',
                  margin: '1.25rem 0',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                }}
              >
                <div>
                  <div style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>Total a Pagar</div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-dim)' }}>Sin cargos ocultos</div>
                </div>
                <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--primary)' }}>
                  ${Number(monto || 0).toFixed(2)} <span style={{ fontSize: '0.9rem' }}>MXN</span>
                </div>
              </div>

              <div style={{ display: 'flex', gap: '0.75rem', justifyContent: 'flex-end' }}>
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={onClose}
                  disabled={loading}
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="btn btn-primary"
                  disabled={loading || !referencia.trim()}
                >
                  {loading ? (
                    'Procesando con Gesto Pago...'
                  ) : (
                    <>
                      <span>Confirmar Compra</span>
                      <ArrowRight size={16} />
                    </>
                  )}
                </button>
              </div>
            </form>
          </div>
        ) : (
          /* Vista del Resultado de la Compra */
          <div style={{ textAlign: 'center' }}>
            {resultado.estado === 'EXITOSA' && (
              <>
                <div
                  className="modal-icon-wrap"
                  style={{
                    background: 'rgba(16, 185, 129, 0.15)',
                    border: '2px solid rgba(16, 185, 129, 0.5)',
                    color: '#10b981',
                  }}
                >
                  <CheckCircle2 size={36} />
                </div>
                <h2 className="modal-title" style={{ color: '#34d399' }}>
                  ¡Compra Exitosa!
                </h2>
                <p className="modal-subtitle">
                  La transacción ha sido autorizada y procesada correctamente.
                </p>

                <div
                  style={{
                    background: 'var(--bg-input)',
                    border: '1px solid var(--border-color)',
                    borderRadius: '14px',
                    padding: '1.25rem',
                    margin: '1.5rem 0',
                    textAlign: 'left',
                    fontSize: '0.88rem',
                    lineHeight: 1.8,
                  }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: '1px solid rgba(255,255,255,0.06)', paddingBottom: '0.4rem', marginBottom: '0.4rem' }}>
                    <span style={{ color: 'var(--text-muted)' }}>Folio / ID:</span>
                    <strong style={{ color: 'var(--text-main)' }}>#{resultado.transaccion.id}</strong>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: '1px solid rgba(255,255,255,0.06)', paddingBottom: '0.4rem', marginBottom: '0.4rem' }}>
                    <span style={{ color: 'var(--text-muted)' }}>Autorización:</span>
                    <strong style={{ color: 'var(--primary)' }}>
                      {resultado.transaccion.numeroAutorizacion || 'AUT-' + resultado.transaccion.id}
                    </strong>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: '1px solid rgba(255,255,255,0.06)', paddingBottom: '0.4rem', marginBottom: '0.4rem' }}>
                    <span style={{ color: 'var(--text-muted)' }}>Servicio:</span>
                    <span>{resultado.transaccion.servicio || marca?.nombre}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: '1px solid rgba(255,255,255,0.06)', paddingBottom: '0.4rem', marginBottom: '0.4rem' }}>
                    <span style={{ color: 'var(--text-muted)' }}>Referencia:</span>
                    <span>{resultado.transaccion.referencia}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span style={{ color: 'var(--text-muted)' }}>Importe Pagado:</span>
                    <strong style={{ color: '#34d399', fontSize: '1rem' }}>
                      ${Number(resultado.transaccion.monto || monto).toFixed(2)} MXN
                    </strong>
                  </div>
                </div>

                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.5rem',
                    padding: '0.65rem 0.85rem',
                    background: 'rgba(16, 185, 129, 0.1)',
                    border: '1px solid rgba(16, 185, 129, 0.25)',
                    borderRadius: '10px',
                    fontSize: '0.8rem',
                    color: '#34d399',
                    marginBottom: '1rem',
                  }}
                >
                  <Mail size={16} style={{ flexShrink: 0 }} />
                  <span>Se ha notificado y enviado el comprobante de este movimiento a tu correo registrado.</span>
                </div>
              </>
            )}

            {resultado.estado === 'PENDIENTE' && (
              <>
                <div
                  className="modal-icon-wrap"
                  style={{
                    background: 'rgba(245, 158, 11, 0.15)',
                    border: '2px solid rgba(245, 158, 11, 0.5)',
                    color: '#f59e0b',
                  }}
                >
                  <Clock size={36} />
                </div>
                <h2 className="modal-title" style={{ color: '#fbbf24' }}>
                  Compra en Proceso / Pendiente
                </h2>
                <p className="modal-subtitle">
                  El proveedor ha recibido la solicitud y se encuentra procesándola.
                </p>
                <div style={{ margin: '1.5rem 0', color: 'var(--text-muted)', fontSize: '0.9rem' }}>
                  Folio: #{resultado.transaccion?.id}
                </div>
              </>
            )}

            {resultado.estado === 'RECHAZADA' && (
              <>
                <div
                  className="modal-icon-wrap"
                  style={{
                    background: 'rgba(239, 68, 68, 0.15)',
                    border: '2px solid rgba(239, 68, 68, 0.5)',
                    color: '#ef4444',
                  }}
                >
                  <XCircle size={36} />
                </div>
                <h2 className="modal-title" style={{ color: '#f87171' }}>
                  Compra Rechazada
                </h2>
                <p className="modal-subtitle">
                  {resultado.mensaje || 'No se pudo autorizar la operación de compra.'}
                </p>
              </>
            )}

            {resultado.estado === 'ERROR_COMUNICACION' && (
              <>
                <div
                  className="modal-icon-wrap"
                  style={{
                    background: 'rgba(239, 68, 68, 0.15)',
                    border: '2px solid rgba(239, 68, 68, 0.5)',
                    color: '#ef4444',
                  }}
                >
                  <AlertTriangle size={36} />
                </div>
                <h2 className="modal-title" style={{ color: '#f87171' }}>
                  Error de Comunicación
                </h2>
                <p className="modal-subtitle">
                  {resultado.mensaje}
                </p>
              </>
            )}

            <div style={{ marginTop: '1.75rem' }}>
              <button
                type="button"
                className="btn btn-primary"
                onClick={onClose}
                style={{ width: '100%' }}
              >
                Cerrar y continuar
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
