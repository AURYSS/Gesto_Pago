import React, { useState, useEffect, useMemo } from 'react';
import { api } from '../services/api';
import PagoModal from './PagoModal';
import {
  Search,
  ShoppingBag,
  Sparkles,
  Zap,
  Phone,
  Droplets,
  Flame,
  Tv,
  RefreshCw,
} from 'lucide-react';

export default function CatalogoGrid({ onPagoRealizado }) {
  const [marcas, setMarcas] = useState([]);
  const [productos, setProductos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const [categoriaSeleccionada, setCategoriaSeleccionada] = useState('TODOS');
  const [busqueda, setBusqueda] = useState('');

  // Modal de Pago
  const [pagoModal, setPagoModal] = useState({
    isOpen: false,
    producto: null,
    marca: null,
  });

  const cargarCatalogo = async () => {
    setLoading(true);
    setError(null);
    try {
      const [marcasData, prodsData] = await Promise.all([
        api.getMarcas().catch(() => ({ marcas: [] })),
        api.getProductos().catch(() => []),
      ]);

      const listaMarcas = marcasData.marcas || (Array.isArray(marcasData) ? marcasData : []);
      setMarcas(listaMarcas);
      setProductos(Array.isArray(prodsData) ? prodsData : []);
    } catch (err) {
      setError('No se pudo cargar el catálogo comercial.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    cargarCatalogo();
  }, []);

  const CATEGORIAS_DEF = {
    1: 'TELEFONÍA',
    2: 'INTERNET',
    3: 'TELEVISIÓN',
    4: 'LUZ / ELECTRICIDAD',
    5: 'GAS',
    6: 'AGUA',
    7: 'PEAJES',
    8: 'GOBIERNO',
    9: 'VENTA POR CATÁLOGO',
    10: 'FINANCIERO',
    11: 'ENTRETENIMIENTO',
    12: 'SEGUROS',
    13: 'OTROS',
  };

  // Extraer categorías únicas
  const categorias = useMemo(() => {
    const cats = new Set();
    marcas.forEach((m) => {
      if (m.categoria) cats.add(m.categoria.toUpperCase());
    });
    productos.forEach((p) => {
      const cat = p.categoria || CATEGORIAS_DEF[p.idCatTipoServicio];
      if (cat) cats.add(cat.toUpperCase());
    });
    return ['TODOS', ...Array.from(cats).sort()];
  }, [marcas, productos]);

  // Lista combinada de items a mostrar
  const itemsFiltrados = useMemo(() => {
    let items = [];

    if (productos.length > 0) {
      items = productos.map((p) => {
        const sServicio = (p.servicio || '').toLowerCase();
        const marcaAsociada = marcas.find((m) => {
          if (!m) return false;
          const sNombre = (m.nombre || '').toLowerCase();
          const sSlug = (m.slug || '').toLowerCase();
          return sServicio.includes(sNombre) || sNombre.includes(sServicio) || sServicio.replace(/\s+/g, '').includes(sSlug);
        });

        const cat = p.categoria || CATEGORIAS_DEF[p.idCatTipoServicio] || marcaAsociada?.categoria || 'OTROS';

        return {
          id: `${p.idServicio}-${p.idProducto}`,
          idProducto: p.idProducto,
          idServicio: p.idServicio,
          nombre: p.producto || p.nombre || 'Servicio',
          servicio: p.servicio,
          descripcion: p.legend || p.descripcion || `Pago disponible para ${p.servicio || 'el servicio'}`,
          precio: p.precio != null ? p.precio : p.monto,
          categoria: cat.toUpperCase(),
          marca: marcaAsociada || { nombre: p.servicio || 'GestoPago', color: '#10b981' },
        };
      });
    }

    // Filtrar por categoría
    if (categoriaSeleccionada !== 'TODOS') {
      items = items.filter((item) => item.categoria === categoriaSeleccionada);
    }

    // Filtrar por búsqueda
    if (busqueda.trim()) {
      const q = busqueda.trim().toLowerCase();
      items = items.filter(
        (item) =>
          item.nombre.toLowerCase().includes(q) ||
          item.descripcion.toLowerCase().includes(q) ||
          (item.servicio && item.servicio.toLowerCase().includes(q)) ||
          item.marca.nombre.toLowerCase().includes(q)
      );
    }

    return items;
  }, [marcas, productos, categoriaSeleccionada, busqueda]);

  const abrirPago = (item) => {
    setPagoModal({
      isOpen: true,
      producto: item,
      marca: item.marca,
    });
  };

  const getIconoCategoria = (cat) => {
    switch (cat) {
      case 'TELEFONIA':
      case 'TELEFONÍA':
        return <Phone size={14} />;
      case 'LUZ':
      case 'ELECTRICIDAD':
        return <Zap size={14} />;
      case 'AGUA':
        return <Droplets size={14} />;
      case 'GAS':
        return <Flame size={14} />;
      case 'ENTRETENIMIENTO':
      case 'STREAMING':
        return <Tv size={14} />;
      default:
        return <Sparkles size={14} />;
    }
  };

  return (
    <div>
      {/* Header de la sección */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', marginBottom: '1.75rem', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <h1 style={{ fontSize: '1.85rem', fontWeight: 800, letterSpacing: '-0.02em', marginBottom: '0.4rem' }}>
            Catálogo Comercial
          </h1>
          <p style={{ color: 'var(--text-muted)', fontSize: '0.95rem' }}>
            Explora y realiza pagos de servicios y recargas en tiempo real.
          </p>
        </div>

        <button
          className="btn btn-secondary"
          onClick={cargarCatalogo}
          disabled={loading}
          style={{ fontSize: '0.85rem', padding: '0.5rem 1rem' }}
        >
          <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
          <span>Actualizar</span>
        </button>
      </div>

      {/* Barra de filtros y búsqueda */}
      <div className="filter-bar">
        <div className="pills-group">
          {categorias.map((cat) => (
            <button
              key={cat}
              className={`pill-btn ${categoriaSeleccionada === cat ? 'active' : ''}`}
              onClick={() => setCategoriaSeleccionada(cat)}
            >
              <span style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
                {cat !== 'TODOS' && getIconoCategoria(cat)}
                {cat}
              </span>
            </button>
          ))}
        </div>

        <div className="search-wrap">
          <Search size={18} />
          <input
            type="text"
            className="input-field search-input"
            placeholder="Buscar por marca o servicio..."
            value={busqueda}
            onChange={(e) => setBusqueda(e.target.value)}
          />
        </div>
      </div>

      {/* Loading state */}
      {loading && (
        <div style={{ textAlign: 'center', padding: '4rem 0', color: 'var(--text-muted)' }}>
          <RefreshCw size={36} className="animate-spin" style={{ margin: '0 auto 1rem', color: 'var(--primary)' }} />
          <div>Cargando productos y servicios autorizados...</div>
        </div>
      )}

      {/* Error state */}
      {error && !loading && (
        <div className="alert-banner danger">
          <div>{error}</div>
        </div>
      )}

      {/* Empty state */}
      {!loading && !error && itemsFiltrados.length === 0 && (
        <div
          style={{
            textAlign: 'center',
            padding: '4rem 2rem',
            background: 'var(--bg-card)',
            borderRadius: '16px',
            border: '1px dashed var(--border-color)',
          }}
        >
          <ShoppingBag size={48} color="var(--text-dim)" style={{ margin: '0 auto 1rem' }} />
          <h3 style={{ fontSize: '1.2rem', marginBottom: '0.5rem' }}>No se encontraron servicios</h3>
          <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem' }}>
            Prueba ajustando el filtro de categoría o los términos de búsqueda.
          </p>
        </div>
      )}

      {/* Grid de Productos adaptado a pantalla ancha */}
      {!loading && !error && itemsFiltrados.length > 0 && (
        <div className="catalog-grid">
          {itemsFiltrados.map((item) => {
            const marcaColor = item.marca?.color || '#10b981';
            return (
              <div key={item.id} className="product-card">
                {/* Barra de color de la marca */}
                <div
                  className="product-card-bar"
                  style={{ backgroundColor: marcaColor }}
                />

                <div className="product-header">
                  <span
                    className="brand-badge"
                    style={{
                      borderLeft: `3px solid ${marcaColor}`,
                      background: 'rgba(255, 255, 255, 0.04)',
                    }}
                  >
                    {item.marca?.nombre || 'GestoPago'}
                  </span>
                  <span style={{ fontSize: '0.75rem', color: 'var(--text-dim)' }}>
                    {item.categoria}
                  </span>
                </div>

                <h3 className="product-name">{item.nombre}</h3>
                <p className="product-desc">{item.descripcion}</p>

                <div className="product-footer">
                  <div>
                    {item.precio ? (
                      <div>
                        <span className="price-tag">${Number(item.precio).toFixed(2)}</span>
                        <span className="price-sub">Precio fijo</span>
                      </div>
                    ) : (
                      <div>
                        <span className="price-tag" style={{ color: 'var(--text-main)', fontSize: '1.05rem' }}>
                          Variable
                        </span>
                        <span className="price-sub">Según recibo</span>
                      </div>
                    )}
                  </div>

                  <button
                    className="btn btn-primary"
                    onClick={() => abrirPago(item)}
                    style={{ padding: '0.5rem 1rem', fontSize: '0.85rem' }}
                  >
                    Pagar
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Modal de Pago / Compra */}
      {pagoModal.isOpen && (
        <PagoModal
          producto={pagoModal.producto}
          marca={pagoModal.marca}
          onClose={() => setPagoModal({ isOpen: false, producto: null, marca: null })}
          onPagoCompletado={() => {
            if (onPagoRealizado) onPagoRealizado();
          }}
        />
      )}
    </div>
  );
}
