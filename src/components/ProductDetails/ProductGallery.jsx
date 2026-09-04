import React, { useState, useCallback, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ChevronLeft, ChevronRight, Expand, X } from 'lucide-react';

const ProductGallery = ({ images = [] }) => {
    const [activeIndex, setActiveIndex] = useState(0);
    const [isZoomed, setIsZoomed] = useState(false);
    const [touchStartX, setTouchStartX] = useState(null);
    const placeholder = 'https://placehold.co/600x600/f1f5f9/94a3b8?text=%D8%A2%D9%84+%D9%85%D8%B3%D8%B9%D8%AF';
    const displayImages = images && images.length > 0 ? images.filter(Boolean) : [placeholder];
    const hasMultiple = displayImages.length > 1;

    const goPrev = useCallback(() => {
        setActiveIndex(prev => (prev === 0 ? displayImages.length - 1 : prev - 1));
    }, [displayImages.length]);

    const goNext = useCallback(() => {
        setActiveIndex(prev => (prev === displayImages.length - 1 ? 0 : prev + 1));
    }, [displayImages.length]);

    // Keyboard navigation
    useEffect(() => {
        const handleKey = (e) => {
            if (e.key === 'ArrowLeft') goNext(); // RTL: left = next
            if (e.key === 'ArrowRight') goPrev();
            if (e.key === 'Escape') setIsZoomed(false);
        };
        window.addEventListener('keydown', handleKey);
        return () => window.removeEventListener('keydown', handleKey);
    }, [goPrev, goNext]);

    const handleTouchStart = (e) => setTouchStartX(e.touches[0].clientX);
    const handleTouchEnd = (e) => {
        if (touchStartX === null) return;
        const diff = e.changedTouches[0].clientX - touchStartX;
        if (Math.abs(diff) > 50) {
            if (diff > 0) goPrev();
            else goNext();
        }
        setTouchStartX(null);
    };

    const handleImageError = (e) => {
        e.target.src = placeholder;
    };

    return (
        <div className="flex flex-col gap-3 md:gap-4 w-full max-w-[360px] sm:max-w-[420px] md:max-w-none mx-auto">
            {/* Main Image */}
            <div
                className="relative aspect-square bg-white rounded-3xl md:rounded-[2.5rem] overflow-hidden border border-slate-100 shadow-sm group select-none"
                onTouchStart={handleTouchStart}
                onTouchEnd={handleTouchEnd}
            >
                <AnimatePresence mode="wait">
                    <motion.img
                        key={activeIndex}
                        initial={{ opacity: 0, scale: 0.98 }}
                        animate={{ opacity: 1, scale: 1 }}
                        exit={{ opacity: 0, scale: 1.02 }}
                        transition={{ duration: 0.35, ease: [0.22, 1, 0.36, 1] }}
                        src={displayImages[activeIndex]}
                        alt={`صورة ${activeIndex + 1}`}
                        onError={handleImageError}
                        className="w-full h-full object-contain p-3 md:p-6 bg-slate-50/50"
                        draggable={false}
                    />
                </AnimatePresence>

                {/* Gradient overlay */}
                <div className="absolute inset-0 bg-gradient-to-t from-black/[0.04] to-transparent opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none" />

                {/* Arrows - visible on hover and always on mobile if multiple */}
                {hasMultiple && (
                    <>
                        <button
                            onClick={goPrev}
                            aria-label="السابق"
                            className="absolute right-3 md:right-4 top-1/2 -translate-y-1/2 w-9 h-9 md:w-10 md:h-10 bg-white/90 backdrop-blur-md border border-slate-200 rounded-full flex items-center justify-center text-slate-700 hover:bg-white hover:text-slate-900 hover:scale-105 shadow-lg shadow-slate-900/10 transition-all duration-200 opacity-0 group-hover:opacity-100 md:opacity-0 md:group-hover:opacity-100 opacity-100 md:opacity-90"
                        >
                            <ChevronRight size={18} className="md:w-5 md:h-5" />
                        </button>
                        <button
                            onClick={goNext}
                            aria-label="التالي"
                            className="absolute left-3 md:left-4 top-1/2 -translate-y-1/2 w-9 h-9 md:w-10 md:h-10 bg-white/90 backdrop-blur-md border border-slate-200 rounded-full flex items-center justify-center text-slate-700 hover:bg-white hover:text-slate-900 hover:scale-105 shadow-lg shadow-slate-900/10 transition-all duration-200 opacity-0 group-hover:opacity-100 md:opacity-0 md:group-hover:opacity-100 opacity-100 md:opacity-90"
                        >
                            <ChevronLeft size={18} className="md:w-5 md:h-5" />
                        </button>

                        {/* Counter */}
                        <div className="absolute bottom-3 right-1/2 translate-x-1/2 md:right-4 md:translate-x-0 bg-slate-900/80 backdrop-blur-md text-white text-[11px] font-black px-3 py-1 rounded-full tracking-wider">
                            {activeIndex + 1} / {displayImages.length}
                        </div>

                        {/* Expand */}
                        <button
                            onClick={() => setIsZoomed(true)}
                            aria-label="تكبير"
                            className="absolute top-3 left-3 w-8 h-8 bg-white/90 backdrop-blur-md border border-slate-200 rounded-full hidden md:flex items-center justify-center text-slate-500 hover:text-slate-900 transition-colors opacity-0 group-hover:opacity-100"
                        >
                            <Expand size={14} />
                        </button>

                        {/* Dots for mobile */}
                        <div className="absolute bottom-12 left-1/2 -translate-x-1/2 flex gap-1.5 md:hidden">
                            {displayImages.map((_, i) => (
                                <div key={i} className={`w-1.5 h-1.5 rounded-full transition-all duration-300 ${i === activeIndex ? 'bg-slate-900 w-5' : 'bg-slate-300'}`} />
                            ))}
                        </div>
                    </>
                )}
            </div>

            {/* Thumbnails */}
            {hasMultiple && (
                <div className="flex items-center gap-2 md:gap-3 px-1 md:px-2 overflow-x-auto no-scrollbar py-2 scroll-smooth" style={{ scrollbarWidth: 'none' }}>
                    {displayImages.map((img, i) => (
                        <button
                            key={i}
                            onClick={() => setActiveIndex(i)}
                            aria-label={`صورة ${i + 1}`}
                            className={`relative w-14 h-14 sm:w-16 sm:h-16 md:w-20 md:h-20 rounded-xl md:rounded-2xl overflow-hidden shrink-0 transition-all duration-300
                                ${i === activeIndex
                                    ? 'ring-2 ring-orange-600 ring-offset-2 scale-[0.97] shadow-md'
                                    : 'opacity-70 hover:opacity-100 hover:scale-[1.03] border border-slate-200'}`}
                        >
                            <img src={img} alt="" onError={handleImageError} className="w-full h-full object-cover" />
                            {i === activeIndex && (
                                <motion.div layoutId="active-thumb" className="absolute inset-0 bg-orange-600/10 pointer-events-none" />
                            )}
                        </button>
                    ))}
                </div>
            )}

            {/* Zoom Modal */}
            <AnimatePresence>
                {isZoomed && (
                    <motion.div
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        className="fixed inset-0 bg-slate-900/90 backdrop-blur-md z-[99999] flex items-center justify-center p-4 md:p-8"
                        onClick={() => setIsZoomed(false)}
                    >
                        <button onClick={() => setIsZoomed(false)} className="absolute top-4 right-4 md:top-6 md:right-6 w-10 h-10 bg-white/10 hover:bg-white/20 rounded-full flex items-center justify-center text-white transition-colors">
                            <X size={20} />
                        </button>
                        <motion.img
                            initial={{ scale: 0.9, opacity: 0 }}
                            animate={{ scale: 1, opacity: 1 }}
                            exit={{ scale: 0.9, opacity: 0 }}
                            src={displayImages[activeIndex]}
                            alt=""
                            className="max-w-full max-h-[85vh] object-contain rounded-2xl shadow-2xl"
                            onClick={(e) => e.stopPropagation()}
                        />
                        {hasMultiple && (
                            <>
                                <button onClick={(e) => { e.stopPropagation(); goPrev(); }} className="absolute right-4 md:right-8 top-1/2 -translate-y-1/2 w-12 h-12 bg-white rounded-full flex items-center justify-center text-slate-900 shadow-xl hover:scale-105 transition-transform">
                                    <ChevronRight size={22} />
                                </button>
                                <button onClick={(e) => { e.stopPropagation(); goNext(); }} className="absolute left-4 md:left-8 top-1/2 -translate-y-1/2 w-12 h-12 bg-white rounded-full flex items-center justify-center text-slate-900 shadow-xl hover:scale-105 transition-transform">
                                    <ChevronLeft size={22} />
                                </button>
                            </>
                        )}
                    </motion.div>
                )}
            </AnimatePresence>
            <style>{`.no-scrollbar::-webkit-scrollbar{display:none}.no-scrollbar{-ms-overflow-style:none;scrollbar-width:none}`}</style>
        </div>
    );
};

export default ProductGallery;