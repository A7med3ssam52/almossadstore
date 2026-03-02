import React from 'react';
import './Navbar.css';

const Navbar = () => {
    const categories = [
        { name: 'جميع الأقسام', icon: 'bars' },
        { name: 'المدني', icon: 'chevron-down' },
        { name: 'الخلاطات وأنظمة الشاور', icon: null },
        { name: 'سيراميك وبورسلين', icon: null },
        { name: 'الأجهزة المنزلية', icon: null },
        { name: 'الكهرباء', icon: null },
        { name: 'أبواب ونوافذ', icon: null },
        { name: 'عروض وخصومات', icon: 'tag-label', highlight: true },
    ];

    return (
        <nav className="site-navbar">
            <div className="container">
                <ul className="nav-list flex">
                    {categories.map((cat, index) => (
                        <li key={index} className={`nav-item ${cat.highlight ? 'highlight' : ''}`}>
                            {cat.name} {cat.icon && <i className={`icon-${cat.icon}`}></i>}
                            {cat.highlight && <span className="hot-badge">مميز</span>}
                        </li>
                    ))}
                </ul>
            </div>
        </nav>
    );
};

export default Navbar;
