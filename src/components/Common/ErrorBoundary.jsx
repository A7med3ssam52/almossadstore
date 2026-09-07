import React from 'react';
import { AlertTriangle, RefreshCw, Home } from 'lucide-react';

const isChunkLoadError = (error) => {
  const msg = (error?.message || error?.toString() || '').toLowerCase();
  return (
    msg.includes('failed to fetch dynamically imported module') ||
    msg.includes('loading chunk') ||
    msg.includes('chunkloaderror') ||
    msg.includes('importing a module script failed') ||
    msg.includes('coupons') // specific failing chunk from report
  );
};

class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null, errorInfo: null, isChunkError: false };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error, isChunkError: isChunkLoadError(error) };
  }

  componentDidCatch(error, errorInfo) {
    this.setState({
      error: error,
      errorInfo: errorInfo,
      isChunkError: isChunkLoadError(error)
    });
    console.error("Uncaught error:", error, errorInfo);

    // Auto-reload once for chunk errors (stale deployment cache)
    if (isChunkLoadError(error)) {
      const key = 'chunk-reload-done';
      const lastReload = sessionStorage.getItem(key);
      const now = Date.now();
      // reload only if not reloaded in last 10 seconds
      if (!lastReload || now - parseInt(lastReload, 10) > 10000) {
        sessionStorage.setItem(key, String(now));
        console.warn('[ErrorBoundary] Chunk load failed – forcing hard reload to fetch new assets');
        // add cache-bust param to bypass CDN / browser cache for index.html
        const url = new URL(window.location.href);
        url.searchParams.set('_r', String(now));
        window.location.replace(url.toString());
      }
    }
  }

  render() {
    if (this.state.hasError) {
      const chunkError = this.state.isChunkError || isChunkLoadError(this.state.error);
      if (chunkError) {
        return (
          <div style={{
            minHeight: '100vh',
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            background: '#f8fafc',
            padding: '2rem',
            fontFamily: 'Cairo, sans-serif'
          }} dir="rtl">
            <div style={{
              maxWidth: '520px',
              width: '100%',
              background: 'white',
              padding: '2.5rem',
              borderRadius: '24px',
              boxShadow: '0 20px 50px rgba(0,0,0,0.08)',
              textAlign: 'center',
              border: '1px solid #ffedd5'
            }}>
              <div style={{
                width: '64px',
                height: '64px',
                background: '#f97316',
                color: 'white',
                borderRadius: '20px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                margin: '0 auto 1.2rem'
              }}>
                <RefreshCw size={28} className="animate-spin" />
              </div>
              <h2 style={{ color: '#0f172a', marginBottom: '0.6rem', fontWeight: 900, fontSize: '20px' }}>جاري تحديث المتجر...</h2>
              <p style={{ color: '#64748b', marginBottom: '1.2rem', lineHeight: 1.7, fontSize: '14px', fontWeight: 600 }}>
                تم إصدار تحديث جديد لآل مسعد. جاري تحميل النسخة الأحدث تلقائياً.<br />
                <span style={{ fontSize: '12px', color: '#94a3b8' }}>إذا لم يتم التحديث، اضغط تحديث يدوياً.</span>
              </p>
              <div style={{ background: '#fff7ed', border: '1px solid #fed7aa', padding: '0.8rem', borderRadius: '12px', fontSize: '11px', color: '#9a3412', fontFamily: 'monospace', direction: 'ltr', marginBottom: '1.5rem', overflow: 'auto' }}>
                {this.state.error?.toString().slice(0, 220)}
              </div>
              <div style={{ display: 'flex', gap: '0.8rem', justifyContent: 'center' }}>
                <button
                  onClick={() => {
                    sessionStorage.setItem('chunk-reload-done', String(Date.now()));
                    const url = new URL(window.location.href);
                    url.searchParams.set('_r', String(Date.now()));
                    window.location.replace(url.toString());
                  }}
                  style={{
                    padding: '12px 22px',
                    background: '#0f172a',
                    color: 'white',
                    border: 'none',
                    borderRadius: '12px',
                    fontWeight: 800,
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '8px'
                  }}
                >
                  <RefreshCw size={16} /> تحديث الآن
                </button>
                <a
                  href="/"
                  style={{
                    padding: '12px 22px',
                    background: 'white',
                    color: '#0f172a',
                    border: '2px solid #e2e8f0',
                    borderRadius: '12px',
                    fontWeight: 800,
                    textDecoration: 'none',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '8px'
                  }}
                >
                  <Home size={16} /> الرئيسية
                </a>
              </div>
            </div>
          </div>
        );
      }
      // Generic fallback
      return (
        <div style={{
          minHeight: '100vh',
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center',
          background: '#f8fafc',
          padding: '2rem',
          fontFamily: 'Cairo, sans-serif'
        }} dir="rtl">
          <div style={{
            maxWidth: '500px',
            width: '100%',
            background: 'white',
            padding: '3rem',
            borderRadius: '24px',
            boxShadow: '0 20px 50px rgba(0,0,0,0.1)',
            textAlign: 'center',
            border: '1px solid #fee2e2'
          }}>
            <div style={{
              width: '64px',
              height: '64px',
              background: '#ef4444',
              color: 'white',
              borderRadius: '20px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              margin: '0 auto 1.5rem'
            }}>
              <AlertTriangle size={32} />
            </div>
            
            <h2 style={{ color: '#0f172a', marginBottom: '1rem', fontWeight: 900 }}>حدث خطأ غير متوقع</h2>
            <p style={{ color: '#64748b', marginBottom: '2rem', lineHeight: 1.6 }}>
              عذراً، واجه التطبيق مشكلة تقنية أثناء التحميل. يرجى محاولة تحديث الصفحة أو العودة للرئيسية.
            </p>

            {this.state.error && (
              <div style={{
                background: '#f1f5f9',
                padding: '1rem',
                borderRadius: '12px',
                fontSize: '0.8rem',
                color: '#ef4444',
                textAlign: 'left',
                marginBottom: '2rem',
                maxHeight: '150px',
                overflow: 'auto',
                fontFamily: 'monospace',
                direction: 'ltr'
              }}>
                <strong>Error:</strong> {this.state.error.toString()}
              </div>
            )}

            <div style={{ display: 'flex', gap: '1rem', justifyContent: 'center' }}>
              <button 
                onClick={() => window.location.reload()}
                style={{
                  padding: '12px 24px',
                  background: '#0f172a',
                  color: 'white',
                  border: 'none',
                  borderRadius: '12px',
                  fontWeight: 700,
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px'
                }}
              >
                <RefreshCw size={18} /> تحديث الصفحة
              </button>
              <a 
                href="/"
                style={{
                  padding: '12px 24px',
                  background: 'white',
                  color: '#0f172a',
                  border: '2px solid #0f172a',
                  borderRadius: '12px',
                  fontWeight: 700,
                  textDecoration: 'none',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px'
                }}
              >
                <Home size={18} /> الرئيسية
              </a>
            </div>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;
