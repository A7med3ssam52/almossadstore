import React from 'react';
import { NavLink } from 'react-router-dom';
import {
    LayoutDashboard,
    Package,
    Tag,
    ShoppingCart,
    Image as ImageIcon,
    History,
    Settings,
    Users,
    LogOut,
    X
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

const Sidebar = ({ isOpen, onClose }) => {
    const menuItems = [
        { name: 'لوحة المؤشرات', icon: <LayoutDashboard size={20} />, path: '/admin', end: true },
        { name: 'المنتجات', icon: <Package size={20} />, path: '/admin/products' },
        { name: 'الطلبات', icon: <ShoppingCart size={20} />, path: '/admin/orders' },
        { name: 'الكوبونات', icon: <History size={20} />, path: '/admin/marketing' },
        { name: 'الإعدادات', icon: <Settings size={20} />, path: '/admin/settings' },
    ];

    return (
        <>
            {/* Desktop & Mobile Sidebar */}
            <aside
                className={`
                    w-64 h-screen bg-white border-l border-slate-200 
                    flex flex-col py-8 shadow-xl shadow-slate-200/50 lg:shadow-none 
                    transition-all duration-500 ease-in-out shrink-0
                    ${isOpen ? 'fixed inset-y-0 right-0 z-50 translate-x-0' : 'fixed inset-y-0 right-0 z-50 translate-x-full lg:relative lg:translate-x-0'}
                `}
            >
                {/* Mobile Close Button */}
                <button
                    onClick={onClose}
                    className="lg:hidden absolute top-4 left-4 p-2 text-slate-400 hover:text-slate-900 hover:bg-slate-100 rounded-xl transition-all"
                >
                    <X size={20} />
                </button>

                {/* Brand Logo Section */}
                <div className="flex items-center gap-3 mb-10 px-8">
                    <div className="w-10 h-10 bg-[#1F2933] rounded-lg flex items-center justify-center shadow-lg shadow-[#1F2933]/20 shrink-0">
                        <span className="text-white font-bold text-2xl tracking-tighter font-sans">M</span>
                    </div>
                    <div className="flex flex-col min-w-0">
                        <h2 className="text-slate-900 font-black text-xl tracking-tight leading-none font-sans truncate uppercase">AL MOSSAD</h2>
                        <span className="text-[#3A3F45] text-[10px] uppercase font-bold tracking-[0.2em] mt-1 truncate">Admin Dashboard</span>
                    </div>
                </div>

                {/* Navigation Menu */}
                <nav className="flex-1 space-y-1 overflow-y-auto px-4 custom-scrollbar">
                    {menuItems.map((item) => (
                        <NavLink
                            key={item.path}
                            to={item.path}
                            end={item.end}
                            onClick={() => { 
                                if (window.innerWidth < 1024) onClose(); 
                                window.dispatchEvent(new CustomEvent('admin:scroll-to-top'));
                            }}
                             className={({ isActive }) => `
                                 flex items-center gap-4 px-4 py-3 rounded-2xl transition-all duration-300 
                                 group/item relative
                                 ${isActive
                                     ? 'bg-[#1F2933] text-white shadow-lg shadow-[#1F2933]/10'
                                     : 'text-slate-500 hover:text-slate-900 hover:bg-slate-100'}
                             `}
                        >
                            <span className="shrink-0">
                                {item.icon}
                            </span>
                            <span className="text-sm font-bold tracking-wide whitespace-nowrap">
                                {item.name}
                            </span>

                            {/* Hover Indicator for non-active */}
                            <div className="absolute right-0 w-1 bg-[#1F2933] rounded-full transition-all duration-300 opacity-0 group-hover/item:h-4 group-hover/item:opacity-100"></div>
                        </NavLink>
                    ))}
                </nav>

                {/* Footer / Logout */}
                <div className="mt-auto px-6 pt-6 border-t border-slate-100">
                    <button className="flex items-center gap-4 w-full px-4 py-3 text-red-600 hover:text-red-700 hover:bg-red-50 rounded-2xl transition-all font-bold group duration-300">
                        <LogOut size={20} />
                        <span className="text-sm">تسجيل الخروج</span>
                    </button>
                </div>
            </aside>
        </>
    );
};

export default Sidebar;

