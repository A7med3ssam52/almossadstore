import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Home, Menu, Heart, ShoppingCart, X, Phone } from 'lucide-react';
import { useCart } from '../../context/CartContext';
import './MobileNav.css';

const MobileNav = () => {
    const [isSidebarOpen, setIsSidebarOpen] = useState(false);
    const navigate = useNavigate();
    const { openCart, totalItems } = useCart();

    const toggleSidebar = () => setIsSidebarOpen(!isSidebarOpen);

    const handleNav = (path) => {
        navigate(path);
        window.scrollTo(0, 0);
        setIsSidebarOpen(false);
    };

    return (
        <>
            <nav className="mobile-bottom-nav glass-effect animate-fade-in">
                <div 
                    className="mobile-nav-item active"
                    onClick={() => { handleNav('/'); }}
                >
                    <Home size={22} />
                    <span>الرئيسية</span>
                </div>

                <div className="mobile-nav-item" onClick={toggleSidebar}>
                    <Menu size={22} />
                    <span>القائمة</span>
                </div>

                <div className="mobile-nav-item" onClick={() => handleNav('/favorites')}>
                    <div className="nav-badge-wrapper">
                        <Heart size={22} />
                        <span className="nav-badge">0</span>
                    </div>
                    <span>المفضلة</span>
                </div>

                <div className="mobile-nav-item" onClick={openCart}>
                    <div className="nav-badge-wrapper">
                        <ShoppingCart size={22} />
                        {totalItems > 0 && <span className="nav-badge">{totalItems}</span>}
                    </div>
                    <span>السلة</span>
                </div>
            </nav>

            {/* Sidebar Drawer */}
            <div className={`sidebar-drawer ${isSidebarOpen ? 'open' : ''}`}>
                <div className="sidebar-overlay" onClick={toggleSidebar}></div>
                <div className="sidebar-content">
                    <div className="sidebar-header">
                        <h3>القائمة</h3>
                        <button onClick={toggleSidebar} className="close-btn">
                            <X size={24} />
                        </button>
                    </div>
                    <ul className="sidebar-links">
                        <li onClick={() => handleNav('/')}><Home size={18} /> الرئيسية</li>
                        <li onClick={() => handleNav('/catalog')}>المتجر</li>
                        <li onClick={() => handleNav('/categories')}>جميع الأقسام</li>
                        <li onClick={() => handleNav('/offers')}>العروض اليومية</li>
                        <li style={{ cursor: 'pointer' }} onClick={() => { window.dispatchEvent(new CustomEvent('auth:open', { detail: { mode: 'login' } })); setIsSidebarOpen(false); window.scrollTo(0, 0); }}><span>حسابي</span></li>
                        <li onClick={() => handleNav('/orders')}>طلباتي</li>
                        <li onClick={() => handleNav('/about')}>من نحن</li>
                        <li onClick={() => handleNav('/privacy')}>سياسة الخصوصية</li>
                        <li onClick={() => handleNav('/terms')}>الشروط والأحكام</li>
                    </ul>
                </div>
            </div>
        </>
    );
};

export default MobileNav;
