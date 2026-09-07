import React from 'react';
import { Outlet, useLocation } from 'react-router-dom';
import Sidebar from '@/components/Admin/Sidebar/Sidebar';
import Header from '@/components/Admin/Layout/Header';
import { motion, AnimatePresence } from 'framer-motion';
import '@/styles/admin.css';

/**
 * AdminLayout
 * Robust Flexbox-based layout for Admin Dashboard.
 */
const AdminLayout = () => {
  const [isSidebarOpen, setIsSidebarOpen] = React.useState(false);
  const { pathname } = useLocation();
  const mainRef = React.useRef(null);

  React.useEffect(() => {
    const handleScroll = () => {
      if (mainRef.current) mainRef.current.scrollTo(0, 0);
    };
    window.addEventListener('admin:scroll-to-top', handleScroll);
    return () => window.removeEventListener('admin:scroll-to-top', handleScroll);
  }, []);

  React.useEffect(() => {
    if (mainRef.current) {
      mainRef.current.scrollTo(0, 0);
    }
  }, [pathname]);

  return (
    <div className="flex items-stretch min-h-screen w-screen bg-[#f8fafc] text-slate-950 font-sans" dir="rtl">

      {/* Sidebar - static on lg, fixed on mobile */}
      <Sidebar isOpen={isSidebarOpen} onClose={() => setIsSidebarOpen(false)} />

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0 lg:ml-0 relative">

        {/* Header at top */}
        <Header onMenuClick={() => setIsSidebarOpen(true)} className="shrink-0" />

        {/* Scrollable Content */}
        <main ref={mainRef} className="flex-1 overflow-y-auto bg-radial-dot relative custom-scrollbar-main min-h-0">
          <div className="p-4 md:p-8 lg:p-12 max-w-[1600px] mx-auto w-full">
            <Outlet />
          </div>

          {/* Global Abstract Background Decorations */}
          <div className="fixed -bottom-24 -left-24 w-96 h-96 bg-[#1F2933]/5 rounded-full blur-[100px] pointer-events-none -z-10"></div>
          <div className="fixed -top-24 -right-24 w-96 h-96 bg-[#1F2933]/5 rounded-full blur-[100px] pointer-events-none -z-10"></div>
        </main>
      </div>

      {/* Mobile Overlay */}
      <AnimatePresence>
        {isSidebarOpen && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setIsSidebarOpen(false)}
            className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-40 lg:hidden cursor-pointer"
          />
        )}
      </AnimatePresence>
    </div>
  );
};

export default AdminLayout;

