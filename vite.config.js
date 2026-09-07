import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    // SPA fallback - serves index.html for all routes
    historyApiFallback: true,
  },
  build: {
    // Ensure SPA routing works on static hosts
    rollupOptions: {
      output: {
        manualChunks: undefined,
      },
    },
  },
})
