enum EstadoTransaccion {
  pendiente,
  enProceso,
  aprobada,
  fallida;

  static EstadoTransaccion fromApi(String valor) {
    switch (valor.toUpperCase()) {
      case 'PENDIENTE':
        return EstadoTransaccion.pendiente;
      case 'EN_PROCESO':
      case 'PROCESANDO':
        return EstadoTransaccion.enProceso;
      case 'APROBADA':
      case 'APROBADO':
      case 'EXITOSA':
        return EstadoTransaccion.aprobada;
      default:
        return EstadoTransaccion.fallida;
    }
  }
}