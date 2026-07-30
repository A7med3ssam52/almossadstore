import React, { Suspense, lazy } from 'react';
import { Routes, Route, useLocation } from 'react-router-dom';
import Header from './components/Header/Header';
import Navbar from './components/Navbar/Navbar';
import Home from './pages/Home';
import ProductView from './pages/ProductView';
import CategoryView from './pages/CategoryView';
import StorySignup from './components/Auth/StorySignup';
import StoryLogin from './components/Auth/StoryLogin';
import WhatsAppWidget from './components/WhatsAppWidget/WhatsAppWidget';
import Footer from './components/Footer/Footer';
import MobileNav from './components/MobileNav/MobileNav';
import ScrollToTop from './components/ScrollToTop';
import FeaturesBar from './components/Features/FeaturesBar';
import { motion, AnimatePresence } from 'framer-motion';
import { X } from 'lucide-react';
import StoreToast from './components/Common/StoreToast';

// Storefront Pages
import About from './pages/About';
import CategoriesPage from './pages/CategoriesPage';
import Catalog from './pages/Catalog';
import CartDrawer from './components/Cart/CartDrawer';
import Checkout from './pages/Checkout/Checkout';
import OrderSuccess from './pages/Checkout/OrderSuccess';
import Offers from './pages/Offers';
import Privacy from './pages/Privacy';
import Terms from './pages/Terms';

// Admin — Lazy loaded for isolation
const AdminRoute = lazy(() => import('./components/Admin/AdminRoute'));
const AdminLayout = lazy(() => import('./components/Admin/Layout/AdminLayout'));
const AdminDashboard = lazy(() => import('./pages/Admin/Dashboard'));
const AdminProducts = lazy(() => import('./pages/Admin/Catalog/Products'));
const AdminCategories = lazy(() => import('./pages/Admin/Catalog/Categories'));
const AdminOrderList = lazy(() => import('./pages/Admin/Orders/OrderList'));
const AdminOrderDetail = lazy(() => import('./pages/Admin/Orders/OrderDetail'));
const AdminBanners = lazy(() => import('./pages/Admin/Editor/Banners'));
const AdminAnnouncement = lazy(() => import('./pages/Admin/Editor/Announcement'));
const AdminHomeLayout = lazy(() => import('./pages/Admin/Editor/HomeLayout'));
const AdminCoupons = lazy(() => import('./pages/Admin/Marketing/Coupons'));
const AdminSettings = lazy(() => import('./pages/Admin/Settings/GeneralSettings'));
const AdminStaff = lazy(() => import('./pages/Admin/Settings/Staff'));

import NotFound from './pages/NotFound/NotFound';
import CreateAccount from './pages/Admin/CreateAccount/CreateAccount';
import ErrorBoundary from './components/Common/ErrorBoundary';
import { checkIsAdmin } from './services/supabase/adminClient';

const StorefrontWrapper = ({ children }) => {
  const [authMode, setAuthMode] = React.useState(null);

  const location = useLocation();
  const searchParams = new URLSearchParams(location.search);




  React.useEffect(() => {
    // Check if auth redirect from admin
    if (searchParams.get('auth') === 'login') {
      setAuthMode('login');
      window.history.replaceState({}, '', location.pathname);
    }

    const handleOpen = (e) => setAuthMode(e.detail.mode);
    const handleClose = () => setAuthMode(null);
    window.addEventListener('auth:open', handleOpen);
    window.addEventListener('auth:close', handleClose);
    return () => {
      window.removeEventListener('auth:open', handleOpen);
      window.removeEventListener('auth:close', handleClose);
    };
  }, [location.search]);

  return (
    <>
      <div className="header-navbar-wrapper">
        <Header />
        <Navbar />
      </div>
      {children}
      <FeaturesBar />
      <Footer />
      <MobileNav />
      <WhatsAppWidget />

      <AnimatePresence>
        {authMode && (
          <motion.div 
            className="story-auth-overlay"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            <div className="story-auth-modal-wrapper">
              <button className="auth-close-btn" onClick={() => setAuthMode(null)}>
                <X size={24} />
              </button>
              {authMode === 'login' ? <StoryLogin /> : <StorySignup />}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
      <StoreToast />
    </>
  );
};

const LoadingScreen = () => (
    <div style={{ height: '300px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <div className="spinner" style={{ border: '3px solid #f3f3f3', borderTop: '3px solid #0f172a', borderRadius: '50%', width: '30px', height: '30px', animation: 'spin 1s linear infinite' }} />
        <style>{`@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }`}</style>
    </div>
);

function App() {
  return (
    <div className="app">
      <ScrollToTop />
      <ErrorBoundary>
        <Suspense fallback={<LoadingScreen />}>
          <CartDrawer />
          <Routes>
            {/* ── Admin (Protected) ── */}
            <Route element={<AdminRoute />}>
              <Route element={<AdminLayout />}>
                <Route path="/admin" element={<AdminDashboard />} />
                <Route path="/admin/products" element={<AdminProducts />} />
                <Route path="/admin/categories" element={<AdminCategories />} />
                <Route path="/admin/orders" element={<AdminOrderList />} />
                <Route path="/admin/orders/:id" element={<AdminOrderDetail />} />
                <Route path="/admin/editor" element={<AdminBanners />} />
                <Route path="/admin/editor/announcement" element={<AdminAnnouncement />} />
                <Route path="/admin/editor/layout" element={<AdminHomeLayout />} />
                <Route path="/admin/marketing" element={<AdminCoupons />} />
                <Route path="/admin/settings" element={<AdminSettings />} />
                <Route path="/admin/settings/staff" element={<AdminStaff />} />
              </Route>
            </Route>

            {/* ── Storefront ── */}
            <Route path="/" element={<StorefrontWrapper><Home /></StorefrontWrapper>} />
            <Route path="/catalog" element={<StorefrontWrapper><Catalog /></StorefrontWrapper>} />
            <Route path="/product/:id" element={<StorefrontWrapper><ProductView /></StorefrontWrapper>} />
            <Route path="/category/:slug" element={<StorefrontWrapper><CategoryView /></StorefrontWrapper>} />
            
            {/* Checkout Flow */}
            <Route path="/checkout" element={<StorefrontWrapper><Checkout /></StorefrontWrapper>} />
            <Route path="/checkout/success" element={<StorefrontWrapper><OrderSuccess /></StorefrontWrapper>} />
            
            {/* Info Pages */}
            <Route path="/about" element={<StorefrontWrapper><About /></StorefrontWrapper>} />
            <Route path="/categories" element={<StorefrontWrapper><CategoriesPage /></StorefrontWrapper>} />
            <Route path="/offers" element={<StorefrontWrapper><Offers /></StorefrontWrapper>} />
            <Route path="/privacy" element={<StorefrontWrapper><Privacy /></StorefrontWrapper>} />
            <Route path="/terms" element={<StorefrontWrapper><Terms /></StorefrontWrapper>} />

            {/* Protected Creation Tool */}
            <Route path="/create" element={<CreateAccount />} />

            {/* 404 Catch-all */}
            <Route path="*" element={<StorefrontWrapper><NotFound /></StorefrontWrapper>} />
          </Routes>
        </Suspense>
      </ErrorBoundary>
    </div>
  );
}

export default App;
