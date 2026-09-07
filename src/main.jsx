import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import { CartProvider } from './context/CartContext.jsx'
import './index.css'
import './styles/admin.css'
import App from './App.jsx'

// — Global chunk-load recovery (stale deploy: Coupons-B6BT1yjJ.js etc) —
if (typeof window !== 'undefined') {
  const isChunkErr = (msg = '') => {
    const m = String(msg).toLowerCase();
    return m.includes('failed to fetch dynamically imported module') || m.includes('loading chunk') || m.includes('chunkloaderror');
  };
  window.addEventListener('error', (e) => {
    const msg = e?.message || e?.error?.message || '';
    if (isChunkErr(msg) && !sessionStorage.getItem('global-chunk-reload')) {
      sessionStorage.setItem('global-chunk-reload', String(Date.now()));
      const url = new URL(window.location.href);
      url.searchParams.set('_r', String(Date.now()));
      window.location.replace(url.toString());
    }
  });
  window.addEventListener('unhandledrejection', (e) => {
    const msg = e?.reason?.message || String(e?.reason || '');
    if (isChunkErr(msg) && !sessionStorage.getItem('global-chunk-reload')) {
      sessionStorage.setItem('global-chunk-reload', String(Date.now()));
      const url = new URL(window.location.href);
      url.searchParams.set('_r', String(Date.now()));
      window.location.replace(url.toString());
    }
  });
  // clear flag after successful load (5s)
  setTimeout(() => sessionStorage.removeItem('global-chunk-reload'), 5000);
  setTimeout(() => sessionStorage.removeItem('chunk-reload-done'), 5000);
}

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <BrowserRouter>
      <CartProvider>
        <App />
      </CartProvider>
    </BrowserRouter>
  </StrictMode>,
)
