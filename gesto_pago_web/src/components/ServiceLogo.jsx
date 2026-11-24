import React, { useState } from 'react';
import { getServiceLogoUrl, getInitials, normalizeText } from '../utils/logoHelper';
import {
  Phone,
  Zap,
  Droplets,
  Flame,
  Tv,
  Car,
  Landmark,
  ShoppingBag,
  CreditCard,
  Gamepad2,
  Sparkles,
} from 'lucide-react';

export default function ServiceLogo({
  service = '',
  brand = null,
  category = '',
  size = 44,
  className = '',
  style = {},
  badgeBackground = '#ffffff',
}) {
  const [hasError, setHasError] = useState(false);

  const brandName = typeof brand === 'string' ? brand : brand?.nombre || '';
  const brandSlug = typeof brand === 'object' ? brand?.slug || '' : '';
  const brandColor = typeof brand === 'object' ? brand?.color : null;

  const logoUrl = getServiceLogoUrl(service, brandName, brandSlug);

  const displayName = brandName || service || 'Servicio';
  const initials = getInitials(displayName);

  const getCategoryFallbackIcon = (cat) => {
    const norm = normalizeText(cat);
    const iconSize = Math.max(14, Math.round(size * 0.45));
    if (norm.includes('telefon') || norm.includes('movil')) return <Phone size={iconSize} />;
    if (norm.includes('luz') || norm.includes('electricidad')) return <Zap size={iconSize} />;
    if (norm.includes('agua')) return <Droplets size={iconSize} />;
    if (norm.includes('gas')) return <Flame size={iconSize} />;
    if (norm.includes('tv') || norm.includes('television') || norm.includes('streaming') || norm.includes('entretenimiento')) {
      return <Tv size={iconSize} />;
    }
    if (norm.includes('peaje') || norm.includes('tag')) return <Car size={iconSize} />;
    if (norm.includes('gobierno')) return <Landmark size={iconSize} />;
    if (norm.includes('juego') || norm.includes('gaming')) return <Gamepad2 size={iconSize} />;
    if (norm.includes('catalogo') || norm.includes('tienda')) return <ShoppingBag size={iconSize} />;
    if (norm.includes('financier') || norm.includes('banco')) return <CreditCard size={iconSize} />;
    return <Sparkles size={iconSize} />;
  };

  const borderRadius = Math.max(8, Math.round(size * 0.25));

  // Si encontramos el logo y no ha habido error al cargarlo
  if (logoUrl && !hasError) {
    return (
      <div
        className={`service-logo-badge ${className}`}
        style={{
          width: `${size}px`,
          height: `${size}px`,
          minWidth: `${size}px`,
          minHeight: `${size}px`,
          borderRadius: `${borderRadius}px`,
          background: badgeBackground,
          padding: size >= 40 ? '5px' : '3px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          boxShadow: '0 2px 6px rgba(0, 0, 0, 0.25)',
          overflow: 'hidden',
          border: '1px solid rgba(255, 255, 255, 0.15)',
          ...style,
        }}
        title={displayName}
      >
        <img
          src={logoUrl}
          alt={displayName}
          onError={() => setHasError(true)}
          style={{
            maxWidth: '100%',
            maxHeight: '100%',
            width: 'auto',
            height: 'auto',
            objectFit: 'contain',
            display: 'block',
          }}
          loading="lazy"
        />
      </div>
    );
  }

  // Fallback: Insignia estilizada con Iniciales o Icono de Categoría
  const fallbackBg = brandColor
    ? `linear-gradient(135deg, ${brandColor}dd, ${brandColor}88)`
    : 'linear-gradient(135deg, #10b981, #047857)';

  return (
    <div
      className={`service-logo-fallback ${className}`}
      style={{
        width: `${size}px`,
        height: `${size}px`,
        minWidth: `${size}px`,
        minHeight: `${size}px`,
        borderRadius: `${borderRadius}px`,
        background: fallbackBg,
        color: '#ffffff',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontWeight: 700,
        fontSize: `${Math.max(10, Math.round(size * 0.35))}px`,
        letterSpacing: '-0.02em',
        boxShadow: '0 2px 6px rgba(0, 0, 0, 0.2)',
        border: '1px solid rgba(255, 255, 255, 0.2)',
        ...style,
      }}
      title={displayName}
    >
      {category ? getCategoryFallbackIcon(category) : initials}
    </div>
  );
}
