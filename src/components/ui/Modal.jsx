import React, { useEffect } from 'react';
import { createPortal } from 'react-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { X } from 'lucide-react';

/**
 * Premium Modal Component
 * Features: React Portal, Glassmorphism, Responsive Scaling, Smooth Animations.
 */
const Modal = ({ 
    isOpen, 
    onClose, 
    children, 
    title, 
    description,
    size = 'md', // sm, md, lg, xl, full
    showClose = true
}) => {
    // Prevent scrolling when modal is open
    useEffect(() => {
        if (isOpen) {
            document.body.style.overflow = 'hidden';
        } else {
            document.body.style.overflow = 'unset';
        }
        return () => { document.body.style.overflow = 'unset'; };
    }, [isOpen]);

    const sizeClasses = {
        sm: 'max-w-md',
        md: 'max-w-lg',
        lg: 'max-w-2xl',
        xl: 'max-w-4xl',
        full: 'max-w-[95vw]'
    };

    return createPortal(
        <AnimatePresence>
            {isOpen && (
                <div className="fixed inset-0 z-[99999] flex items-center justify-center p-2 sm:p-4 bg-slate-900/60 backdrop-blur-[8px] transition-all duration-500 overflow-y-auto no-scrollbar" dir="rtl">
                    {/* Backdrop tap to close */}
                    <div className="absolute inset-0 z-0" onClick={onClose} />

                    <motion.div
                        initial={{ scale: 0.9, opacity: 0, y: 20 }}
                        animate={{ scale: 1, opacity: 1, y: 0 }}
                        exit={{ scale: 0.9, opacity: 0, y: 20 }}
                        className={`bg-white/95 border border-white/20 rounded-[1.5rem] sm:rounded-[2.5rem] p-5 sm:p-8 w-full ${sizeClasses[size] || sizeClasses.md} shadow-[0_32px_128px_-16px_rgba(0,0,0,0.5)] relative my-auto z-10 overflow-visible`}
                    >
                        {(title || showClose) && (
                            <div className="flex items-center justify-between mb-6 sm:mb-8 relative">
                                <div>
                                    {title && (
                                        <h2 className="text-2xl sm:text-3xl font-black text-slate-900 tracking-tight mb-1">
                                            {title}
                                        </h2>
                                    )}
                                    {description && (
                                        <p className="text-slate-500 text-xs sm:text-sm font-medium">{description}</p>
                                    )}
                                </div>
                                
                                {showClose && (
                                    <motion.button 
                                        whileHover={{ rotate: 90, scale: 1.1 }}
                                        whileTap={{ scale: 0.9 }}
                                        onClick={onClose} 
                                        className="p-2 sm:p-3 text-slate-400 hover:text-slate-900 bg-slate-50 hover:bg-slate-100 rounded-xl sm:rounded-2xl transition-all"
                                    >
                                        <X size={20} />
                                    </motion.button>
                                )}
                            </div>
                        )}

                        <div className="relative">
                            {children}
                        </div>
                    </motion.div>
                </div>
            )}
        </AnimatePresence>,
        document.body
    );
};

export default Modal;
