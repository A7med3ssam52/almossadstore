import React from 'react';
import { Link } from 'react-router-dom';
import { ChevronDown, Menu } from 'lucide-react';
import './Navbar.css';

const Navbar = () => {
    const categories = [
        { name: 'جميع الأقسام', primary: true, icon: <Menu size={18} />, hasDropdown: true, route: '/categories' },
        { name: 'المتجر', route: '/catalog', highlight: true },
        { name: 'بويات', route: '/category/paints' },
        { name: 'حدايد', route: '/category/hardware' },
        { name: 'ديكور', route: '/category/decor' },
        { name: 'مواد لاصقة', route: '/category/adhesives' },
        { name: 'عدد يدوية', route: '/category/daily-tools' },
        { name: 'عروض وخصومات', route: '/offers', highlight: true },
    ];

    return (
        <nav className="site-navbar">
            <div className="container">
                <ul className="nav-list">
                    {categories.map((cat, index) => (
                        <li
                            key={index}
                            className={[
                                'nav-item',
                                cat.primary ? 'nav-primary' : '',
                                cat.highlight ? 'nav-highlight' : '',
                                index === 0 ? 'nav-first' : '',
                            ].filter(Boolean).join(' ')}
                        >
                            <Link 
                                to={cat.route} 
                                className="nav-link"
                                onClick={() => window.scrollTo(0, 0)}
                            >
                                {cat.icon && <span className="nav-icon">{cat.icon}</span>}
                                <span>{cat.name}</span>
                                {cat.hasDropdown && <ChevronDown size={14} strokeWidth={2} />}
                            </Link>
                            {cat.badge && (
                                <span className="nav-badge">{cat.badge}</span>
                            )}
                            {/* Vertical divider after "جميع الأقسام" */}
                            {index === 0 && <span className="nav-divider">|</span>}
                        </li>
                    ))}
                </ul>
            </div>
        </nav>
    );
};

export default Navbar;
