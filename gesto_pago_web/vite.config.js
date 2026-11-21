import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    proxy: {
      '/auth': 'http://localhost:8080',
      '/catalogo': 'http://localhost:8080',
      '/pagos': 'http://localhost:8080',
      '/api': 'http://localhost:8081',
    },
  },
})
