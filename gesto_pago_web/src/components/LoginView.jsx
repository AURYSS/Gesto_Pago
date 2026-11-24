import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import {
  CreditCard,
  Mail,
  Lock,
  LogIn,
  UserPlus,
  AlertCircle,
  AlertTriangle,
  Eye,
  EyeOff,
  CheckCircle2,
  XCircle,
  ShieldCheck,
  Info,
  Building,
  Phone,
  Briefcase,
  DollarSign,
  ArrowRight,
  ArrowLeft,
  Check,
} from 'lucide-react';

export default function LoginView() {
  const { login, registerPersonaFisica, revocationMessage, clearRevocationMessage, loading } = useAuth();
  const [tab, setTab] = useState('login'); // 'login' | 'register'
  const [step, setStep] = useState(1); // 1: Personales, 2: Domicilio & Contacto, 3: Laboral & Acceso

  // Form states - Login
  const [loginEmail, setLoginEmail] = useState('');
  const [loginPassword, setLoginPassword] = useState('');
  const [showLoginPassword, setShowLoginPassword] = useState(false);

  // Form states - Register (Persona Física - Proyecto Integrador)
  const [formData, setFormData] = useState({
    // Datos Personales
    nombre: '',
    segundoNombre: '',
    apellidoPaterno: '',
    apellidoMaterno: '',
    fechaNacimiento: '',
    curp: '',
    rfc: '',
    sexo: 'H',
    nacionalidad: 'Mexicana',
    estadoCivil: 'Soltero(a)',

    // Contacto
    correo: '',
    telefonoMovil: '',
    telefonoAlternativo: '',

    // Domicilio
    calle: '',
    numeroExterior: '',
    numeroInterior: '',
    colonia: '',
    municipio: '',
    estado: 'Guanajuato',
    codigoPostal: '',
    pais: 'México',

    // Laboral
    ocupacion: '',
    empresa: '',
    ingresoMensual: '',

    // Seguridad
    password: '',
    confirmPassword: '',
  });

  const [showRegPassword, setShowRegPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  // Rastreo de campos tocados
  const [touched, setTouched] = useState({});
  const [error, setError] = useState(null);
  const [successMsg, setSuccessMsg] = useState(null);

  const markTouched = (field) => {
    setTouched((prev) => ({ ...prev, [field]: true }));
  };

  const handleChange = (field, value) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
  };

  // --- VALIDACIONES DETALLADAS POR REGLA DE NEGOCIO ---
  const validateField = (field, val) => {
    const v = typeof val === 'string' ? val.trim() : val;

    switch (field) {
      // 1. Datos Personales
      case 'nombre':
        if (!v) return 'El nombre es obligatorio';
        if (v.length < 2 || v.length > 50) return 'Debe tener entre 2 y 50 caracteres';
        if (!/^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$/.test(v)) return 'Solo se permiten letras y espacios';
        return null;

      case 'segundoNombre':
        if (v && !/^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]*$/.test(v)) return 'Solo se permiten letras y espacios';
        return null;

      case 'apellidoPaterno':
        if (!v) return 'El apellido paterno es obligatorio';
        if (v.length < 2 || v.length > 50) return 'Debe tener entre 2 y 50 caracteres';
        if (!/^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$/.test(v)) return 'Solo se permiten letras y espacios';
        return null;

      case 'apellidoMaterno':
        if (!v) return 'El apellido materno es obligatorio';
        if (v.length < 2 || v.length > 50) return 'Debe tener entre 2 y 50 caracteres';
        if (!/^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$/.test(v)) return 'Solo se permiten letras y espacios';
        return null;

      case 'fechaNacimiento': {
        if (!v) return 'La fecha de nacimiento es obligatoria';
        const nac = new Date(v + 'T00:00:00');
        const hoy = new Date();
        if (nac > hoy) return 'La fecha de nacimiento no puede ser futura';
        let edad = hoy.getFullYear() - nac.getFullYear();
        const m = hoy.getMonth() - nac.getMonth();
        if (m < 0 || (m === 0 && hoy.getDate() < nac.getDate())) {
          edad--;
        }
        if (edad < 18) return 'El cliente debe ser mayor de edad (18 años o más)';
        return null;
      }

      case 'curp':
        if (!v) return 'La CURP es obligatoria';
        if (v.length !== 18) return 'La CURP debe contener exactamente 18 caracteres';
        if (!/^[A-Z]{4}\d{6}[HM][A-Z]{5}[A-Z\d]\d$/.test(v.toUpperCase())) {
          return 'Formato de CURP inválido (ej. ABCD010203HDFRRN09)';
        }
        return null;

      case 'rfc':
        if (!v) return 'El RFC es obligatorio';
        if (v.length < 12 || v.length > 13) return 'El RFC debe contener 12 o 13 caracteres';
        if (!/^[A-Z&Ñ]{3,4}\d{6}[A-V1-9][A-Z1-9][0-9A]$/.test(v.toUpperCase())) {
          return 'Formato de RFC inválido (ej. ABCD010203XX1)';
        }
        return null;

      case 'sexo':
        if (!v) return 'Selecciona el sexo';
        return null;

      case 'nacionalidad':
        if (!v) return 'La nacionalidad es obligatoria';
        return null;

      case 'estadoCivil':
        if (!v) return 'Selecciona el estado civil';
        return null;

      // 2. Contacto
      case 'correo':
        if (!v) return 'El correo electrónico es obligatorio';
        if (v.length > 100) return 'El correo no puede exceder 100 caracteres';
        if (!/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/.test(v)) {
          return 'Formato de correo inválido (ej. usuario@dominio.com)';
        }
        return null;

      case 'telefonoMovil':
        if (!v) return 'El teléfono móvil es obligatorio';
        if (!/^\d{10}$/.test(v)) return 'El teléfono debe contener exactamente 10 dígitos';
        return null;

      case 'telefonoAlternativo':
        if (v && !/^\d{10}$/.test(v)) return 'Debe contener exactamente 10 dígitos';
        return null;

      // 3. Domicilio
      case 'calle':
        if (!v) return 'La calle es obligatoria';
        return null;

      case 'numeroExterior':
        if (!v) return 'El número exterior es obligatorio';
        return null;

      case 'colonia':
        if (!v) return 'La colonia es obligatoria';
        return null;

      case 'municipio':
        if (!v) return 'El municipio es obligatorio';
        return null;

      case 'estado':
        if (!v) return 'El estado es obligatorio';
        return null;

      case 'codigoPostal':
        if (!v) return 'El código postal es obligatorio';
        if (!/^\d{5}$/.test(v)) return 'El C.P. debe contener exactamente 5 dígitos';
        return null;

      case 'pais':
        if (!v) return 'El país es obligatorio';
        return null;

      // 4. Laboral
      case 'ocupacion':
        if (!v) return 'La ocupación es obligatoria';
        return null;

      case 'empresa':
        if (!v) return 'La empresa es obligatoria';
        return null;

      case 'ingresoMensual':
        if (!v) return 'El ingreso mensual es obligatorio';
        if (isNaN(Number(v)) || Number(v) <= 0) return 'El ingreso mensual debe ser mayor a cero';
        return null;

      // 5. Contraseña
      case 'password':
        if (!val) return 'La contraseña es obligatoria';
        if (val.length < 8) return 'Mínimo 8 caracteres';
        if (val.length > 100) return 'Máximo 100 caracteres';
        if (!/[A-Z]/.test(val)) return 'Debe incluir al menos una mayúscula (A-Z)';
        if (!/[a-z]/.test(val)) return 'Debe incluir al menos una minúscula (a-z)';
        if (!/[0-9]/.test(val)) return 'Debe incluir al menos un número (0-9)';
        if (!/[!@#$%^&*()_+\-=[\]{};':"\\|,.<>/?]/.test(val)) {
          return 'Debe incluir al menos un carácter especial';
        }
        return null;

      case 'confirmPassword':
        if (!val) return 'Confirma tu contraseña';
        if (val !== formData.password) return 'Las contraseñas no coinciden';
        return null;

      default:
        return null;
    }
  };

  const errors = Object.keys(formData).reduce((acc, key) => {
    const err = validateField(key, formData[key]);
    if (err) acc[key] = err;
    return acc;
  }, {});

  // Validador por paso para el wizard
  const isStep1Valid =
    !errors.nombre &&
    !errors.segundoNombre &&
    !errors.apellidoPaterno &&
    !errors.apellidoMaterno &&
    !errors.fechaNacimiento &&
    !errors.curp &&
    !errors.rfc &&
    !errors.sexo &&
    !errors.nacionalidad &&
    !errors.estadoCivil;

  const isStep2Valid =
    !errors.correo &&
    !errors.telefonoMovil &&
    !errors.telefonoAlternativo &&
    !errors.calle &&
    !errors.numeroExterior &&
    !errors.colonia &&
    !errors.municipio &&
    !errors.estado &&
    !errors.codigoPostal &&
    !errors.pais;

  const isStep3Valid =
    !errors.ocupacion &&
    !errors.empresa &&
    !errors.ingresoMensual &&
    !errors.password &&
    !errors.confirmPassword;

  // Medidor de fortaleza de contraseña
  const reqLength = formData.password.length >= 8;
  const reqUpper = /[A-Z]/.test(formData.password);
  const reqLower = /[a-z]/.test(formData.password);
  const reqNumber = /[0-9]/.test(formData.password);
  const reqSpecial = /[!@#$%^&*()_+\-=[\]{};':"\\|,.<>/?]/.test(formData.password);
  const strengthScore = [reqLength, reqUpper, reqLower, reqNumber, reqSpecial].filter(Boolean).length;

  const getStrengthInfo = () => {
    if (!formData.password) return { label: 'Sin ingresar', color: 'transparent', width: '0%' };
    if (strengthScore <= 2) return { label: 'Débil', color: '#ef4444', width: '33%' };
    if (strengthScore <= 4) return { label: 'Media', color: '#f59e0b', width: '66%' };
    return { label: 'Fuerte', color: '#10b981', width: '100%' };
  };

  const strengthInfo = getStrengthInfo();

  const handleTabChange = (newTab) => {
    setTab(newTab);
    setError(null);
    setSuccessMsg(null);
    setStep(1);
    if (clearRevocationMessage) clearRevocationMessage();
  };

  const handleNextStep = (e) => {
    e.preventDefault();
    setError(null);

    if (step === 1) {
      ['nombre', 'apellidoPaterno', 'apellidoMaterno', 'fechaNacimiento', 'curp', 'rfc'].forEach(markTouched);
      if (!isStep1Valid) {
        setError('Por favor completa y corrige los campos de Datos Personales');
        return;
      }
      setStep(2);
    } else if (step === 2) {
      ['correo', 'telefonoMovil', 'calle', 'numeroExterior', 'colonia', 'municipio', 'estado', 'codigoPostal', 'pais'].forEach(markTouched);
      if (!isStep2Valid) {
        setError('Por favor completa y corrige los campos de Contacto y Domicilio');
        return;
      }
      setStep(3);
    }
  };

  const handlePrevStep = () => {
    setError(null);
    if (step > 1) setStep(step - 1);
  };

  const handleLoginSubmit = async (e) => {
    e.preventDefault();
    setError(null);
    setSuccessMsg(null);

    if (!loginEmail.trim() || !loginPassword) {
      setError('Por favor completa todos los campos para iniciar sesión');
      return;
    }

    try {
      await login(loginEmail, loginPassword);
      // Si requiere 2FA, se muestra el TwoFactorModal sin autocompletar ni exponer el código
    } catch (err) {
      setError(err.message || 'Error al iniciar sesión');
    }
  };

  const handleRegisterSubmit = async (e) => {
    e.preventDefault();
    setError(null);
    setSuccessMsg(null);

    // Marcar todos los campos como tocados
    Object.keys(formData).forEach(markTouched);

    if (!isStep1Valid || !isStep2Valid || !isStep3Valid) {
      setError('Por favor verifica todos los campos antes de completar el registro');
      return;
    }

    try {
      await registerPersonaFisica(formData);
      // El usuario queda autenticado automáticamente y su cuenta bancaria queda creada y activa
    } catch (err) {
      setError(err.message || 'Error al registrar el cliente');
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
          maxWidth: tab === 'register' ? '700px' : '460px',
          transition: 'max-width 0.3s ease',
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
            {tab === 'login'
              ? 'Acceso unificado al ecosistema de comercio digital'
              : 'Onboarding de Clientes: Registro de Persona Física y Apertura de Cuenta'}
          </p>
        </div>

        {/* Selector de pestañas */}
        <div className="auth-tabs">
          <button
            type="button"
            className={`auth-tab ${tab === 'login' ? 'active' : ''}`}
            onClick={() => handleTabChange('login')}
          >
            <LogIn size={16} />
            <span>Iniciar Sesión</span>
          </button>
          <button
            type="button"
            className={`auth-tab ${tab === 'register' ? 'active' : ''}`}
            onClick={() => handleTabChange('register')}
          >
            <UserPlus size={16} />
            <span>Crear Cuenta (Persona Física)</span>
          </button>
        </div>

        {/* Banner de sesión revocada */}
        {revocationMessage && (
          <div
            className="alert-banner warning"
            style={{ marginBottom: '1.25rem', borderLeft: '4px solid #f59e0b', padding: '1rem' }}
          >
            <AlertTriangle size={22} color="#f59e0b" style={{ flexShrink: 0, marginTop: '2px' }} />
            <div>
              <div style={{ fontWeight: 700, marginBottom: '4px', color: '#fef3c7' }}>Sesión finalizada</div>
              <div style={{ color: '#fef3c7', fontSize: '0.9rem' }}>{revocationMessage}</div>
            </div>
          </div>
        )}

        {/* Banner de error */}
        {error && (
          <div className="alert-banner danger">
            <AlertCircle size={20} style={{ flexShrink: 0, marginTop: '2px' }} />
            <div>{error}</div>
          </div>
        )}

        {/* Banner de éxito */}
        {successMsg && (
          <div className="alert-banner success">
            <CheckCircle2 size={20} style={{ flexShrink: 0, marginTop: '2px' }} />
            <div>{successMsg}</div>
          </div>
        )}

        {/* ========================================================= */}
        {/* FORMULARIO 1: INICIO DE SESIÓN                           */}
        {/* ========================================================= */}
        {tab === 'login' ? (
          <form onSubmit={handleLoginSubmit} noValidate>
            <div className="form-group">
              <label className="form-label">Correo electrónico</label>
              <div style={{ position: 'relative' }}>
                <input
                  type="email"
                  className="input-field"
                  placeholder="ejemplo@correo.com"
                  value={loginEmail}
                  onChange={(e) => setLoginEmail(e.target.value)}
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
                  type={showLoginPassword ? 'text' : 'password'}
                  className="input-field"
                  placeholder="••••••••"
                  value={loginPassword}
                  onChange={(e) => setLoginPassword(e.target.value)}
                  disabled={loading}
                  required
                  style={{ paddingLeft: '2.5rem', paddingRight: '2.5rem' }}
                />
                <Lock
                  size={18}
                  color="var(--text-dim)"
                  style={{ position: 'absolute', left: '0.85rem', top: '50%', transform: 'translateY(-50%)' }}
                />
                <button
                  type="button"
                  className="input-action-btn"
                  onClick={() => setShowLoginPassword(!showLoginPassword)}
                  title={showLoginPassword ? 'Ocultar contraseña' : 'Ver contraseña'}
                  tabIndex={-1}
                >
                  {showLoginPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
            </div>

            <button
              type="submit"
              className="btn btn-primary"
              disabled={loading}
              style={{ width: '100%', marginTop: '1.25rem', padding: '0.85rem' }}
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

            <div
              style={{
                marginTop: '1.5rem',
                textAlign: 'center',
                fontSize: '0.88rem',
                color: 'var(--text-muted)',
              }}
            >
              ¿Eres nuevo cliente persona física?{' '}
              <button
                type="button"
                onClick={() => handleTabChange('register')}
                style={{
                  background: 'none',
                  border: 'none',
                  color: 'var(--primary)',
                  fontWeight: 700,
                  cursor: 'pointer',
                  padding: 0,
                  textDecoration: 'underline',
                }}
              >
                Regístrate aquí
              </button>
            </div>
          </form>
        ) : (
          /* ========================================================= */
          /* FORMULARIO 2: ONBOARDING CLIENTE PERSONA FÍSICA          */
          /* ========================================================= */
          <form onSubmit={step === 3 ? handleRegisterSubmit : handleNextStep} noValidate>
            {/* Wizard Steps Navigation */}
            <div className="wizard-steps">
              <div className={`wizard-step-item ${step === 1 ? 'active' : ''} ${step > 1 ? 'completed' : ''}`}>
                <div className="step-num-badge">{step > 1 ? <Check size={12} /> : '1'}</div>
                <span>Datos Personales</span>
              </div>
              <div style={{ color: 'var(--border-color)' }}>&bull;&bull;&bull;</div>
              <div className={`wizard-step-item ${step === 2 ? 'active' : ''} ${step > 2 ? 'completed' : ''}`}>
                <div className="step-num-badge">{step > 2 ? <Check size={12} /> : '2'}</div>
                <span>Contacto y Domicilio</span>
              </div>
              <div style={{ color: 'var(--border-color)' }}>&bull;&bull;&bull;</div>
              <div className={`wizard-step-item ${step === 3 ? 'active' : ''}`}>
                <div className="step-num-badge">3</div>
                <span>Laboral y Cuenta</span>
              </div>
            </div>

            {/* PASO 1: DATOS PERSONALES */}
            {step === 1 && (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                <div className="form-grid-2">
                  {/* Nombre */}
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">
                      Primer nombre <span style={{ color: '#ef4444' }}>*</span>
                    </label>
                    <input
                      type="text"
                      className={`input-field ${touched.nombre && errors.nombre ? 'has-error' : ''}`}
                      placeholder="Ej. Juan"
                      value={formData.nombre}
                      onChange={(e) => handleChange('nombre', e.target.value)}
                      onBlur={() => markTouched('nombre')}
                      maxLength={50}
                    />
                    {touched.nombre && errors.nombre && (
                      <div className="field-error-msg">
                        <XCircle size={13} /> <span>{errors.nombre}</span>
                      </div>
                    )}
                  </div>

                  {/* Segundo Nombre (Opcional) */}
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">Segundo nombre (Opcional)</label>
                    <input
                      type="text"
                      className={`input-field ${touched.segundoNombre && errors.segundoNombre ? 'has-error' : ''}`}
                      placeholder="Ej. Carlos"
                      value={formData.segundoNombre}
                      onChange={(e) => handleChange('segundoNombre', e.target.value)}
                      onBlur={() => markTouched('segundoNombre')}
                      maxLength={50}
                    />
                    {touched.segundoNombre && errors.segundoNombre && (
                      <div className="field-error-msg">
                        <XCircle size={13} /> <span>{errors.segundoNombre}</span>
                      </div>
                    )}
                  </div>
                </div>

                <div className="form-grid-2">
                  {/* Apellido Paterno */}
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">
                      Apellido paterno <span style={{ color: '#ef4444' }}>*</span>
                    </label>
                    <input
                      type="text"
                      className={`input-field ${touched.apellidoPaterno && errors.apellidoPaterno ? 'has-error' : ''}`}
                      placeholder="Ej. Pérez"
                      value={formData.apellidoPaterno}
                      onChange={(e) => handleChange('apellidoPaterno', e.target.value)}
                      onBlur={() => markTouched('apellidoPaterno')}
                      maxLength={50}
                    />
                    {touched.apellidoPaterno && errors.apellidoPaterno && (
                      <div className="field-error-msg">
                        <XCircle size={13} /> <span>{errors.apellidoPaterno}</span>
                      </div>
                    )}
                  </div>

                  {/* Apellido Materno */}
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">
                      Apellido materno <span style={{ color: '#ef4444' }}>*</span>
                    </label>
                    <input
                      type="text"
                      className={`input-field ${touched.apellidoMaterno && errors.apellidoMaterno ? 'has-error' : ''}`}
                      placeholder="Ej. García"
                      value={formData.apellidoMaterno}
                      onChange={(e) => handleChange('apellidoMaterno', e.target.value)}
                      onBlur={() => markTouched('apellidoMaterno')}
                      maxLength={50}
                    />
                    {touched.apellidoMaterno && errors.apellidoMaterno && (
                      <div className="field-error-msg">
                        <XCircle size={13} /> <span>{errors.apellidoMaterno}</span>
                      </div>
                    )}
                  </div>
                </div>

                <div className="form-grid-2">
                  {/* Fecha de Nacimiento */}
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">
                      Fecha de nacimiento (Mayor de 18 años) <span style={{ color: '#ef4444' }}>*</span>
                    </label>
                    <div style={{ position: 'relative' }}>
                      <input
                        type="date"
                        className={`input-field ${touched.fechaNacimiento && errors.fechaNacimiento ? 'has-error' : ''}`}
                        value={formData.fechaNacimiento}
                        onChange={(e) => handleChange('fechaNacimiento', e.target.value)}
                        onBlur={() => markTouched('fechaNacimiento')}
                      />
                    </div>
                    {touched.fechaNacimiento && errors.fechaNacimiento && (
                      <div className="field-error-msg">
                        <XCircle size={13} /> <span>{errors.fechaNacimiento}</span>
                      </div>
                    )}
                  </div>

                  {/* Sexo */}
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">
                      Sexo <span style={{ color: '#ef4444' }}>*</span>
                    </label>
                    <select
                      className="input-field"
                      value={formData.sexo}
                      onChange={(e) => handleChange('sexo', e.target.value)}
                    >
                      <option value="H">Hombre (H)</option>
                      <option value="M">Mujer (M)</option>
                    </select>
                  </div>
                </div>

                <div className="form-grid-2">
                  {/* CURP */}
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">
                      CURP (18 caracteres) <span style={{ color: '#ef4444' }}>*</span>
                    </label>
                    <input
                      type="text"
                      className={`input-field ${touched.curp && errors.curp ? 'has-error' : ''}`}
                      placeholder="ABCD010203HDFRRN09"
                      value={formData.curp}
                      onChange={(e) => handleChange('curp', e.target.value.toUpperCase())}
                      onBlur={() => markTouched('curp')}
                      maxLength={18}
                      style={{ textTransform: 'uppercase' }}
                    />
                    {touched.curp && errors.curp && (
                      <div className="field-error-msg">
                        <XCircle size={13} /> <span>{errors.curp}</span>
                      </div>
                    )}
                  </div>

                  {/* RFC */}
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">
                      RFC (12 o 13 caracteres) <span style={{ color: '#ef4444' }}>*</span>
                    </label>
                    <input
                      type="text"
                      className={`input-field ${touched.rfc && errors.rfc ? 'has-error' : ''}`}
                      placeholder="ABCD010203XX1"
                      value={formData.rfc}
                      onChange={(e) => handleChange('rfc', e.target.value.toUpperCase())}
                      onBlur={() => markTouched('rfc')}
                      maxLength={13}
                      style={{ textTransform: 'uppercase' }}
                    />
                    {touched.rfc && errors.rfc && (
                      <div className="field-error-msg">
                        <XCircle size={13} /> <span>{errors.rfc}</span>
                      </div>
                    )}
                  </div>
                </div>

                <div className="form-grid-2">
                  {/* Nacionalidad */}
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">
                      Nacionalidad <span style={{ color: '#ef4444' }}>*</span>
                    </label>
                    <input
                      type="text"
                      className="input-field"
                      placeholder="Mexicana"
                      value={formData.nacionalidad}
                      onChange={(e) => handleChange('nacionalidad', e.target.value)}
                    />
                  </div>

                  {/* Estado Civil */}
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">
                      Estado Civil <span style={{ color: '#ef4444' }}>*</span>
                    </label>
                    <select
                      className="input-field"
                      value={formData.estadoCivil}
                      onChange={(e) => handleChange('estadoCivil', e.target.value)}
                    >
                      <option value="Soltero(a)">Soltero(a)</option>
                      <option value="Casado(a)">Casado(a)</option>
                      <option value="Divorciado(a)">Divorciado(a)</option>
                      <option value="Viudo(a)">Viudo(a)</option>
                      <option value="Unión Libre">Unión Libre</option>
                    </select>
                  </div>
                </div>
              </div>
            )}

            {/* PASO 2: CONTACTO Y DOMICILIO */}
            {step === 2 && (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                {/* Correo Electrónico */}
                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label className="form-label">
                    Correo electrónico (Usuario de acceso y 2FA) <span style={{ color: '#ef4444' }}>*</span>
                  </label>
                  <div style={{ position: 'relative' }}>
                    <input
                      type="email"
                      className={`input-field ${touched.correo && errors.correo ? 'has-error' : ''}`}
                      placeholder="ejemplo@correo.com"
                      value={formData.correo}
                      onChange={(e) => handleChange('correo', e.target.value)}
                      onBlur={() => markTouched('correo')}
                      maxLength={100}
                      style={{ paddingLeft: '2.5rem' }}
                    />
                    <Mail
                      size={18}
                      color="var(--text-dim)"
                      style={{ position: 'absolute', left: '0.85rem', top: '50%', transform: 'translateY(-50%)' }}
                    />
                  </div>
                  {touched.correo && errors.correo ? (
                    <div className="field-error-msg">
                      <XCircle size={13} /> <span>{errors.correo}</span>
                    </div>
                  ) : (
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem', marginTop: '0.3rem', fontSize: '0.75rem', color: 'var(--text-dim)' }}>
                      <Info size={13} color="#10b981" />
                      <span>Este correo será tu nombre de usuario y donde recibirás tus códigos 2FA.</span>
                    </div>
                  )}
                </div>

                {/* Teléfonos */}
                <div className="form-grid-2">
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">
                      Teléfono móvil (10 dígitos) <span style={{ color: '#ef4444' }}>*</span>
                    </label>
                    <div style={{ position: 'relative' }}>
                      <input
                        type="tel"
                        className={`input-field ${touched.telefonoMovil && errors.telefonoMovil ? 'has-error' : ''}`}
                        placeholder="4181234567"
                        value={formData.telefonoMovil}
                        onChange={(e) => handleChange('telefonoMovil', e.target.value.replace(/\D/g, ''))}
                        onBlur={() => markTouched('telefonoMovil')}
                        maxLength={10}
                        style={{ paddingLeft: '2.5rem' }}
                      />
                      <Phone
                        size={18}
                        color="var(--text-dim)"
                        style={{ position: 'absolute', left: '0.85rem', top: '50%', transform: 'translateY(-50%)' }}
                      />
                    </div>
                    {touched.telefonoMovil && errors.telefonoMovil && (
                      <div className="field-error-msg">
                        <XCircle size={13} /> <span>{errors.telefonoMovil}</span>
                      </div>
                    )}
                  </div>

                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">Teléfono alternativo (Opcional)</label>
                    <input
                      type="tel"
                      className={`input-field ${touched.telefonoAlternativo && errors.telefonoAlternativo ? 'has-error' : ''}`}
                      placeholder="4189876543"
                      value={formData.telefonoAlternativo}
                      onChange={(e) => handleChange('telefonoAlternativo', e.target.value.replace(/\D/g, ''))}
                      onBlur={() => markTouched('telefonoAlternativo')}
                      maxLength={10}
                    />
                    {touched.telefonoAlternativo && errors.telefonoAlternativo && (
                      <div className="field-error-msg">
                        <XCircle size={13} /> <span>{errors.telefonoAlternativo}</span>
                      </div>
                    )}
                  </div>
                </div>

                {/* Domicilio: Calle y Números */}
                <div className="form-grid-2">
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">
                      Calle <span style={{ color: '#ef4444' }}>*</span>
                    </label>
                    <input
                      type="text"
                      className={`input-field ${touched.calle && errors.calle ? 'has-error' : ''}`}
                      placeholder="Av. Hidalgo"
                      value={formData.calle}
                      onChange={(e) => handleChange('calle', e.target.value)}
                      onBlur={() => markTouched('calle')}
                    />
                    {touched.calle && errors.calle && (
                      <div className="field-error-msg">
                        <XCircle size={13} /> <span>{errors.calle}</span>
                      </div>
                    )}
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.5rem' }}>
                    <div className="form-group" style={{ marginBottom: 0 }}>
                      <label className="form-label">
                        No. Ext <span style={{ color: '#ef4444' }}>*</span>
                      </label>
                      <input
                        type="text"
                        className={`input-field ${touched.numeroExterior && errors.numeroExterior ? 'has-error' : ''}`}
                        placeholder="123"
                        value={formData.numeroExterior}
                        onChange={(e) => handleChange('numeroExterior', e.target.value)}
                        onBlur={() => markTouched('numeroExterior')}
                      />
                    </div>
                    <div className="form-group" style={{ marginBottom: 0 }}>
                      <label className="form-label">No. Int</label>
                      <input
                        type="text"
                        className="input-field"
                        placeholder="A-2"
                        value={formData.numeroInterior}
                        onChange={(e) => handleChange('numeroInterior', e.target.value)}
                      />
                    </div>
                  </div>
                </div>

                {/* Domicilio: Colonia y Código Postal */}
                <div className="form-grid-2">
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">
                      Colonia <span style={{ color: '#ef4444' }}>*</span>
                    </label>
                    <input
                      type="text"
                      className={`input-field ${touched.colonia && errors.colonia ? 'has-error' : ''}`}
                      placeholder="Centro"
                      value={formData.colonia}
                      onChange={(e) => handleChange('colonia', e.target.value)}
                      onBlur={() => markTouched('colonia')}
                    />
                    {touched.colonia && errors.colonia && (
                      <div className="field-error-msg">
                        <XCircle size={13} /> <span>{errors.colonia}</span>
                      </div>
                    )}
                  </div>

                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">
                      Código Postal (5 dígitos) <span style={{ color: '#ef4444' }}>*</span>
                    </label>
                    <input
                      type="text"
                      className={`input-field ${touched.codigoPostal && errors.codigoPostal ? 'has-error' : ''}`}
                      placeholder="37800"
                      value={formData.codigoPostal}
                      onChange={(e) => handleChange('codigoPostal', e.target.value.replace(/\D/g, ''))}
                      onBlur={() => markTouched('codigoPostal')}
                      maxLength={5}
                    />
                    {touched.codigoPostal && errors.codigoPostal && (
                      <div className="field-error-msg">
                        <XCircle size={13} /> <span>{errors.codigoPostal}</span>
                      </div>
                    )}
                  </div>
                </div>

                {/* Domicilio: Municipio, Estado y País */}
                <div className="form-grid-2">
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">
                      Municipio / Alcaldía <span style={{ color: '#ef4444' }}>*</span>
                    </label>
                    <input
                      type="text"
                      className={`input-field ${touched.municipio && errors.municipio ? 'has-error' : ''}`}
                      placeholder="Dolores Hidalgo"
                      value={formData.municipio}
                      onChange={(e) => handleChange('municipio', e.target.value)}
                      onBlur={() => markTouched('municipio')}
                    />
                    {touched.municipio && errors.municipio && (
                      <div className="field-error-msg">
                        <XCircle size={13} /> <span>{errors.municipio}</span>
                      </div>
                    )}
                  </div>

                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">
                      Estado <span style={{ color: '#ef4444' }}>*</span>
                    </label>
                    <input
                      type="text"
                      className={`input-field ${touched.estado && errors.estado ? 'has-error' : ''}`}
                      placeholder="Guanajuato"
                      value={formData.estado}
                      onChange={(e) => handleChange('estado', e.target.value)}
                      onBlur={() => markTouched('estado')}
                    />
                  </div>
                </div>
              </div>
            )}

            {/* PASO 3: INFORMACIÓN LABORAL Y SEGURIDAD */}
            {step === 3 && (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                {/* Ocupación y Empresa */}
                <div className="form-grid-2">
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">
                      Ocupación <span style={{ color: '#ef4444' }}>*</span>
                    </label>
                    <div style={{ position: 'relative' }}>
                      <input
                        type="text"
                        className={`input-field ${touched.ocupacion && errors.ocupacion ? 'has-error' : ''}`}
                        placeholder="Ingeniero en Software"
                        value={formData.ocupacion}
                        onChange={(e) => handleChange('ocupacion', e.target.value)}
                        onBlur={() => markTouched('ocupacion')}
                        style={{ paddingLeft: '2.5rem' }}
                      />
                      <Briefcase
                        size={18}
                        color="var(--text-dim)"
                        style={{ position: 'absolute', left: '0.85rem', top: '50%', transform: 'translateY(-50%)' }}
                      />
                    </div>
                    {touched.ocupacion && errors.ocupacion && (
                      <div className="field-error-msg">
                        <XCircle size={13} /> <span>{errors.ocupacion}</span>
                      </div>
                    )}
                  </div>

                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">
                      Empresa <span style={{ color: '#ef4444' }}>*</span>
                    </label>
                    <div style={{ position: 'relative' }}>
                      <input
                        type="text"
                        className={`input-field ${touched.empresa && errors.empresa ? 'has-error' : ''}`}
                        placeholder="Tech Solutions S.A."
                        value={formData.empresa}
                        onChange={(e) => handleChange('empresa', e.target.value)}
                        onBlur={() => markTouched('empresa')}
                        style={{ paddingLeft: '2.5rem' }}
                      />
                      <Building
                        size={18}
                        color="var(--text-dim)"
                        style={{ position: 'absolute', left: '0.85rem', top: '50%', transform: 'translateY(-50%)' }}
                      />
                    </div>
                    {touched.empresa && errors.empresa && (
                      <div className="field-error-msg">
                        <XCircle size={13} /> <span>{errors.empresa}</span>
                      </div>
                    )}
                  </div>
                </div>

                {/* Ingreso Mensual */}
                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label className="form-label">
                    Ingreso mensual ($ MXN - Mayor a cero) <span style={{ color: '#ef4444' }}>*</span>
                  </label>
                  <div style={{ position: 'relative' }}>
                    <input
                      type="number"
                      step="any"
                      min="1"
                      className={`input-field ${touched.ingresoMensual && errors.ingresoMensual ? 'has-error' : ''}`}
                      placeholder="18000.00"
                      value={formData.ingresoMensual}
                      onChange={(e) => handleChange('ingresoMensual', e.target.value)}
                      onBlur={() => markTouched('ingresoMensual')}
                      style={{ paddingLeft: '2.5rem' }}
                    />
                    <DollarSign
                      size={18}
                      color="var(--text-dim)"
                      style={{ position: 'absolute', left: '0.85rem', top: '50%', transform: 'translateY(-50%)' }}
                    />
                  </div>
                  {touched.ingresoMensual && errors.ingresoMensual && (
                    <div className="field-error-msg">
                      <XCircle size={13} /> <span>{errors.ingresoMensual}</span>
                    </div>
                  )}
                </div>

                {/* Contraseña y Confirmación */}
                <div className="form-grid-2">
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">
                      Contraseña de acceso <span style={{ color: '#ef4444' }}>*</span>
                    </label>
                    <div style={{ position: 'relative' }}>
                      <input
                        type={showRegPassword ? 'text' : 'password'}
                        className={`input-field ${touched.password && errors.password ? 'has-error' : ''}`}
                        placeholder="Mínimo 8 caracteres"
                        value={formData.password}
                        onChange={(e) => handleChange('password', e.target.value)}
                        onBlur={() => markTouched('password')}
                        maxLength={100}
                        style={{ paddingLeft: '2.5rem', paddingRight: '2.5rem' }}
                      />
                      <Lock
                        size={18}
                        color="var(--text-dim)"
                        style={{ position: 'absolute', left: '0.85rem', top: '50%', transform: 'translateY(-50%)' }}
                      />
                      <button
                        type="button"
                        className="input-action-btn"
                        onClick={() => setShowRegPassword(!showRegPassword)}
                        tabIndex={-1}
                      >
                        {showRegPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                      </button>
                    </div>
                  </div>

                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">
                      Confirmar contraseña <span style={{ color: '#ef4444' }}>*</span>
                    </label>
                    <div style={{ position: 'relative' }}>
                      <input
                        type={showConfirmPassword ? 'text' : 'password'}
                        className={`input-field ${
                          touched.confirmPassword && errors.confirmPassword ? 'has-error' : ''
                        }`}
                        placeholder="Repite tu contraseña"
                        value={formData.confirmPassword}
                        onChange={(e) => handleChange('confirmPassword', e.target.value)}
                        onBlur={() => markTouched('confirmPassword')}
                        maxLength={100}
                        style={{ paddingLeft: '2.5rem', paddingRight: '2.5rem' }}
                      />
                      <ShieldCheck
                        size={18}
                        color="var(--text-dim)"
                        style={{ position: 'absolute', left: '0.85rem', top: '50%', transform: 'translateY(-50%)' }}
                      />
                      <button
                        type="button"
                        className="input-action-btn"
                        onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                        tabIndex={-1}
                      >
                        {showConfirmPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                      </button>
                    </div>
                  </div>
                </div>

                {/* Fortaleza de contraseña */}
                {formData.password && (
                  <div className="password-strength-container" style={{ marginTop: '0.4rem' }}>
                    <div className="password-strength-info">
                      <span style={{ color: 'var(--text-muted)' }}>Fortaleza:</span>
                      <strong style={{ color: strengthInfo.color }}>{strengthInfo.label}</strong>
                    </div>
                    <div className="password-strength-bar-bg">
                      <div
                        className="password-strength-segment"
                        style={{ background: strengthScore >= 1 ? strengthInfo.color : 'rgba(255,255,255,0.1)' }}
                      />
                      <div
                        className="password-strength-segment"
                        style={{ background: strengthScore >= 3 ? strengthInfo.color : 'rgba(255,255,255,0.1)' }}
                      />
                      <div
                        className="password-strength-segment"
                        style={{ background: strengthScore >= 5 ? strengthInfo.color : 'rgba(255,255,255,0.1)' }}
                      />
                    </div>
                  </div>
                )}

                {/* Checklist de Requisitos de Contraseña */}
                <div className="password-requirements-list">
                  <div className={`req-item ${reqLength ? 'met' : ''}`}>
                    {reqLength ? <CheckCircle2 size={13} /> : <XCircle size={13} />}
                    <span>Mínimo 8 caracteres</span>
                  </div>
                  <div className={`req-item ${reqUpper ? 'met' : ''}`}>
                    {reqUpper ? <CheckCircle2 size={13} /> : <XCircle size={13} />}
                    <span>Una mayúscula (A-Z)</span>
                  </div>
                  <div className={`req-item ${reqLower ? 'met' : ''}`}>
                    {reqLower ? <CheckCircle2 size={13} /> : <XCircle size={13} />}
                    <span>Una minúscula (a-z)</span>
                  </div>
                  <div className={`req-item ${reqNumber ? 'met' : ''}`}>
                    {reqNumber ? <CheckCircle2 size={13} /> : <XCircle size={13} />}
                    <span>Un número (0-9)</span>
                  </div>
                  <div className={`req-item ${reqSpecial ? 'met' : ''}`}>
                    {reqSpecial ? <CheckCircle2 size={13} /> : <XCircle size={13} />}
                    <span>Carácter especial (!@#$)</span>
                  </div>
                </div>

                {touched.password && errors.password && (
                  <div className="field-error-msg">
                    <XCircle size={13} /> <span>{errors.password}</span>
                  </div>
                )}
                {touched.confirmPassword && errors.confirmPassword && (
                  <div className="field-error-msg">
                    <XCircle size={13} /> <span>{errors.confirmPassword}</span>
                  </div>
                )}

                {/* Tarjeta de Apertura Automática de Cuenta */}
                <div className="account-info-card">
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.3rem' }}>
                    <ShieldCheck size={18} color="#10b981" />
                    <strong style={{ fontSize: '0.88rem', color: '#34d399' }}>
                      Apertura Automática de Cuenta Bancaria
                    </strong>
                  </div>
                  <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)', margin: 0, lineHeight: 1.4 }}>
                    Al completar este registro, el sistema creará tu cuenta con número único <strong>UUID</strong>,
                    asignará estatus <strong>ACTIVA</strong> con saldo inicial <strong>$0.00 MXN</strong> y
                    habilitará tus credenciales con autenticación 2FA.
                  </p>
                </div>
              </div>
            )}

            {/* Botones de Navegación del Wizard */}
            <div style={{ display: 'flex', gap: '0.75rem', marginTop: '1.5rem' }}>
              {step > 1 && (
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={handlePrevStep}
                  disabled={loading}
                  style={{ flex: 1, padding: '0.85rem' }}
                >
                  <ArrowLeft size={16} />
                  <span>Anterior</span>
                </button>
              )}

              {step < 3 ? (
                <button
                  type="submit"
                  className="btn btn-primary"
                  style={{ flex: 1, padding: '0.85rem' }}
                >
                  <span>Siguiente paso</span>
                  <ArrowRight size={16} />
                </button>
              ) : (
                <button
                  type="submit"
                  className="btn btn-primary"
                  disabled={loading || !isStep1Valid || !isStep2Valid || !isStep3Valid}
                  style={{ flex: 1, padding: '0.85rem' }}
                >
                  {loading ? (
                    'Procesando onboarding...'
                  ) : (
                    <>
                      <UserPlus size={18} />
                      <span>Registrar y Abrir Cuenta</span>
                    </>
                  )}
                </button>
              )}
            </div>

            <div
              style={{
                marginTop: '1.25rem',
                textAlign: 'center',
                fontSize: '0.88rem',
                color: 'var(--text-muted)',
              }}
            >
              ¿Ya tienes una cuenta registrada?{' '}
              <button
                type="button"
                onClick={() => handleTabChange('login')}
                style={{
                  background: 'none',
                  border: 'none',
                  color: 'var(--primary)',
                  fontWeight: 700,
                  cursor: 'pointer',
                  padding: 0,
                  textDecoration: 'underline',
                }}
              >
                Inicia sesión aquí
              </button>
            </div>
          </form>
        )}

        {/* Footer */}
        <div
          style={{
            marginTop: '1.75rem',
            paddingTop: '1.25rem',
            borderTop: '1px solid var(--border-color)',
            textAlign: 'center',
            fontSize: '0.8rem',
            color: 'var(--text-dim)',
            lineHeight: 1.5,
          }}
        >
          Proyecto Integrador &bull; Onboarding de Clientes Personas Físicas
          <br />
          Autenticación 2FA por correo electrónico y apertura automática de cuenta bancaria.
        </div>
      </div>
    </div>
  );
}
