import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Check, XCircle, Info } from 'lucide-react';

export const showAdminToast = (msg, type = 'success') => {
    window.dispatchEvent(new CustomEvent('admin:toast', { detail: { msg, type } }));
};

const AdminToast = () => {
    const [toast, setToast] = useState(null);

    useEffect(() => {
        let timeout;
        const handleToast = (e) => {
            setToast(e.detail);
            clearTimeout(timeout);
            timeout = setTimeout(() => setToast(null), 3000);
        };
        window.addEventListener('admin:toast', handleToast);
        return () => {
            window.removeEventListener('admin:toast', handleToast);
            clearTimeout(timeout);
        };
    }, []);

    const icons = {
        success: <Check size={16} className="text-green-600" />,
        error: <XCircle size={16} className="text-red-600" />,
        info: <Info size={16} className="text-blue-600" />
    };

    const colors = {
        success: 'border-green-100 text-green-700',
        error: 'border-red-100 text-red-700',
        info: 'border-blue-100 text-blue-700'
    };

    return (
        <AnimatePresence>
            {toast && (
                <motion.div 
                    initial={{ opacity: 0, y: 30 }} 
                    animate={{ opacity: 1, y: 0 }} 
                    exit={{ opacity: 0, y: 30 }}
                    className={`fixed bottom-6 left-6 z-[100000] flex items-center gap-3 px-5 py-3 rounded-2xl shadow-2xl border backdrop-blur-xl bg-white ${colors[toast.type] || colors.success}`}
                >
                    {icons[toast.type] || icons.success}
                    <span className="text-sm font-bold">{toast.msg}</span>
                </motion.div>
            )}
        </AnimatePresence>
    );
};

export default AdminToast;
