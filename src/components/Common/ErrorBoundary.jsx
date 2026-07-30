import React from 'react';
import { AlertTriangle, RefreshCw, Home } from 'lucide-react';

class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null, errorInfo: null };
  }

  static getDerivedStateFromError(error) {
    // Update state so the next render will show the fallback UI.
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    // Catch errors in any components below and re-render with error message
    this.setState({
      error: error,
      errorInfo: errorInfo
    });
    console.error("Uncaught error:", error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      // You can render any custom fallback UI
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
            
            <h2 style={{ color: '#0f172a', marginBottom: '1rem', fontBold: 900 }}>حدث خطأ غير متوقع</h2>
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
