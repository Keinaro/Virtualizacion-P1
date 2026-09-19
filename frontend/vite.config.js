import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    // En desarrollo, proxy hacia el gateway para usar las mismas
    // rutas /api/* que en producción.
    proxy: {
      '/api': 'http://localhost:8080'
    }
  }
})
