import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { CheckCircle2, XCircle, Info } from 'lucide-react';
import './StoreToast.css';

export const showToast = (msg, type = 'success') => {
    window.dispatchEvent(new CustomEvent('store:toast', { detail: { msg, type } }));
};

const StoreToast = () => {
    const [toast, setToast] = useState(null);

    useEffect(() => {
        let timeout;
        const handleToast = (e) => {
            setToast({ ...e.detail, id: Date.now() });
            clearTimeout(timeout);
            timeout = setTimeout(() => setToast(null), 4000);
        };
        window.addEventListener('store:toast', handleToast);
        return () => {
            window.removeEventListener('store:toast', handleToast);
            clearTimeout(timeout);
        };
    }, []);

    const icons = {
        success: <CheckCircle2 size={22} className="toast-icon success" />,
        error: <XCircle size={22} className="toast-icon error" />,
        info: <Info size={22} className="toast-icon info" />
    };

    return (
        <AnimatePresence>
            {toast && (
                <motion.div
                    key={toast.id}
                    initial={{ opacity: 0, y: -50, scale: 0.9 }}
                    animate={{ opacity: 1, y: 0, scale: 1 }}
                    exit={{ opacity: 0, y: -20, scale: 0.95 }}
                    transition={{ type: 'spring', stiffness: 400, damping: 25 }}
                    className={`store-toast toast-${toast.type || 'success'}`}
                >
                    <div className="toast-icon-wrapper">
                        {icons[toast.type] || icons.success}
                    </div>
                    <span className="toast-message">{toast.msg}</span>
                    <button className="toast-close" onClick={() => setToast(null)}>
                        <XCircle size={16} />
                    </button>
                </motion.div>
            )}
        </AnimatePresence>
    );
};

export default StoreToast;
