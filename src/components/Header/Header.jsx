import React from 'react';
import './Header.css';

const Header = () => {
  return (
    <header className="site-header">
      <div className="top-bar">
        <div className="container flex-between">
          <div className="top-left flex">
            <span className="lang-switch">العربية <i className="icon-globe"></i></span>
            <div className="cart-widget flex">
              <span className="cart-count">0</span>
              <span className="cart-text">0 جنيه</span>
              <i className="icon-cart"></i>
            </div>
          </div>
          <div className="top-right flex">
            <div className="user-account flex">
              <i className="icon-user"></i>
              <span>تسجيل الدخول / الحساب</span>
            </div>
          </div>
        </div>
      </div>
      
      <div className="main-header">
        <div className="container flex-between">
          <div className="header-logo">
            <div className="logo-placeholder">
              <span className="logo-text">آل مسعود</span>
              <span className="logo-sub">للحدايد والبويات</span>
            </div>
          </div>
          
          <div className="header-search">
            <div className="search-box flex">
               <input type="text" placeholder="أنا أبحث عن..." />
               <button className="search-btn">بحث</button>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
};

export default Header;
