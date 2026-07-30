import React, { useState, useEffect } from 'react';
import { User, ShoppingCart, Search, Globe, LogOut, ChevronDown, ShieldCheck, Package } from 'lucide-react';
import { Link, useNavigate } from 'react-router-dom';
import { supabase } from '../../supabaseClient';
import { checkIsAdmin } from '../../services/supabase/adminClient';
import { useCart } from '../../context/CartContext';
import './Header.css';
import './AccountDropdown.css';

const Header = () => {
  const navigate = useNavigate();
  const { totalItems, subtotal, openCart } = useCart();
  const [searchTerm, setSearchTerm] = useState('');
  const [showSuggestions, setShowSuggestions] = useState(false);
  const [user, setUser] = useState(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const [isMobileSearchOpen, setIsMobileSearchOpen] = useState(false);

  useEffect(() => {
    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
      if (session?.user) {
        checkIsAdmin().then(setIsAdmin);
      }
    });

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
      if (session?.user) {
        checkIsAdmin().then(setIsAdmin);
      } else {
        setIsAdmin(false);
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  const handleLogout = async () => {
    setIsDropdownOpen(false);
    await supabase.auth.signOut();
    navigate('/');
  };

  const suggestions = ['عدد يدوية', 'بويات جوتن', 'سباكة خلاطات', 'كهرباء كابلات', 'باب حديد'];

  return (
    <header className="site-header">
      <div className="container header-row">

        {/* RIGHT: Logo */}
        <Link to="/" className="header-logo">
          <div className="logo-grid-icon">
            <div /><div /><div /><div />
          </div>
          <div className="logo-text-block">
            <span className="logo-main">آل مسعد</span>
            <span className="logo-sub">للحدايد والبويات</span>
          </div>
        </Link>

        {/* Mobile Search Pill Bar */}
        <div 
          className="mobile-search-pill"
          onClick={() => setIsMobileSearchOpen(true)}
        >
          <Search size={18} strokeWidth={2.5} />
          <span>ابحث عن منتجاتك...</span>
        </div>

        {/* CENTER: Search bar (Desktop Only) */}
        <div className="header-search desktop-only">
          <div className="search-wrapper">
            <input
              type="text"
              className="search-input"
              placeholder="أنا أبحث عن..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              onFocus={() => setShowSuggestions(true)}
              onBlur={() => setTimeout(() => setShowSuggestions(false), 200)}
            />
            <button className="search-btn">
              <Search size={16} strokeWidth={2.5} />
              <span>بحث</span>
            </button>

            {showSuggestions && searchTerm.length > 0 && (
              <div className="search-suggestions animate-fade-in">
                {suggestions
                  .filter(s => s.includes(searchTerm))
                  .map((s, i) => (
                    <div
                      key={i}
                      className="suggestion-item"
                      onMouseDown={() => setSearchTerm(s)}
                    >
                      <Search size={14} />
                      <span>{s}</span>
                    </div>
                  ))}
              </div>
            )}
          </div>
        </div>

        {/* LEFT: Account → Cart → Globe */}
        <div className="header-actions">
          {/* Account & Dropdown */}
          <div className="account-dropdown-wrapper" onMouseLeave={() => setIsDropdownOpen(false)}>
            {user ? (
              <div 
                className={`account-menu-trigger action-item ${isDropdownOpen ? 'active' : ''}`}
                onClick={() => setIsDropdownOpen(!isDropdownOpen)}
                style={{ cursor: 'pointer' }}
              >
                <User size={20} strokeWidth={1.8} />
                <span className="action-label" style={{ textAlign: 'right' }}>
                  <span style={{ fontSize: '10px', opacity: 0.8 }}>مرحباً بك</span><br />
                  {user.user_metadata?.full_name?.split(' ')[0] || user.email?.split('@')[0] || 'المستخدم'}
                </span>
                <ChevronDown size={14} className="dropdown-chevron" />
                
                {isDropdownOpen && (
                  <div className="account-dropdown-menu animate-dropdown" dir="rtl">
                    <div className="menu-header">
                        <span className="user-email">{user?.email || ''}</span>
                        {isAdmin && <span className="user-role">مسؤول النظام</span>}
                    </div>
                    
                    {isAdmin && (
                        <Link to="/admin" className="menu-item admin-link" onClick={() => setIsDropdownOpen(false)}>
                            <ShieldCheck size={18} />
                            لوحة التحكم
                        </Link>
                    )}
                    
                    <Link to="/orders" className="menu-item" onClick={() => setIsDropdownOpen(false)}>
                        <Package size={18} />
                        طلباتي
                    </Link>
                    
                    <button className="menu-item logout-item" onClick={handleLogout}>
                        <LogOut size={18} />
                        تسجيل الخروج
                    </button>
                  </div>
                )}
              </div>
            ) : (
              <div 
                className="action-item cursor-pointer" 
                onClick={() => window.dispatchEvent(new CustomEvent('auth:open', { detail: { mode: 'login' } }))}
                style={{ cursor: 'pointer' }}
              >
                <User size={20} strokeWidth={1.8} />
                <span className="action-label">تسجيل الدخول<br />الحساب</span>
              </div>
            )}
          </div>

          {/* Cart + Price */}
          <div className="action-item cursor-pointer" onClick={openCart} style={{ cursor: 'pointer' }}>
            <div className="cart-wrapper">
              <ShoppingCart size={20} strokeWidth={1.8} />
              <span className="cart-badge">{totalItems}</span>
            </div>
            <span className="action-label">السلة<br />{subtotal.toLocaleString()} ج.م</span>
          </div>

          {/* Globe */}
          <div className="action-item action-globe" style={{ cursor: 'pointer' }}>
            <Globe size={20} strokeWidth={1.8} />
          </div>
        </div>

      </div>

      {/* Mobile Search Overlay */}
      {isMobileSearchOpen && (
        <div className="mobile-search-overlay animate-fade-in">
          <div className="overlay-backdrop" onClick={() => setIsMobileSearchOpen(false)}></div>
          <div className="overlay-content">
            <div className="overlay-search-wrapper">
              <input
                autoFocus
                type="text"
                className="overlay-input"
                placeholder="ابحث عن منتجك هنا..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
              <button 
                className="overlay-close-btn"
                onClick={() => setIsMobileSearchOpen(false)}
              >
                إغلاق
              </button>
            </div>
            
            {searchTerm.length > 0 && (
              <div className="overlay-suggestions animate-slide-up">
                {suggestions
                  .filter(s => s.includes(searchTerm))
                  .map((s, i) => (
                    <div
                      key={i}
                      className="overlay-suggestion-item"
                      onClick={() => {
                        setSearchTerm(s);
                        setIsMobileSearchOpen(false);
                      }}
                    >
                      <Search size={18} />
                      <span>{s}</span>
                    </div>
                  ))}
              </div>
            )}
          </div>
        </div>
      )}
    </header>
  );
};

export default Header;
