import React from 'react';
import { Link } from 'react-router-dom';
import { Home, Search, ArrowRight } from 'lucide-react';
import './NotFound.css';

const NotFound = () => {
    return (
        <div className="not-found-container animate-fade-in" dir="rtl">
            <div className="not-found-content">
                <div className="error-code-wrapper">
                    <h1 className="error-code">404</h1>
                    <div className="error-decoration">
                        <div className="blob blob-1"></div>
                        <div className="blob blob-2"></div>
                    </div>
                </div>
                
                <h2 className="not-found-title">عذراً، لم نجد الصفحة المطلوبة</h2>
                <p className="not-found-text">
                    يبدو أن الرابط الذي اتبعته غير صحيح أو أن الصفحة قد تم نقلها أو حذفها. 
                    لا تقلق، يمكنك دائماً العودة إلى الصفحة الرئيسية أو استكشاف منتجاتنا.
                </p>
                
                <div className="not-found-actions">
                    <Link to="/" className="btn-primary-home">
                        <Home size={20} />
                        العودة للرئيسية
                    </Link>
                    <Link to="/catalog" className="btn-outline-catalog">
                        <Search size={20} />
                        تصفح المنتجات
                    </Link>
                </div>

                <div className="quick-help">
                    <span>هل تحتاج مساعدة؟</span>
                    <Link to="/contact" className="contact-link">
                        تواصل معنا <ArrowRight size={16} />
                    </Link>
                </div>
            </div>

            <div className="not-found-background">
                <div className="grid-pattern"></div>
                <div className="floating-icons">
                    {/* Add some hardware-themed decorative elements if needed */}
                    <div className="float-icon gear">⚙️</div>
                    <div className="float-icon wrench">🔧</div>
                    <div className="float-icon paint">🎨</div>
                </div>
            </div>
        </div>
    );
};

export default NotFound;
