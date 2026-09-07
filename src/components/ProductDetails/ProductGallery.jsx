import React, { useState, useCallback, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ChevronLeft, ChevronRight, Expand, X } from 'lucide-react';

const PLACEHOLDER = 'https://placehold.co/600x600/f1f5f9/94a3b8?text=%D8%A2%D9%84+%D9%85%D8%B3%D8%B9%D8%AF';

const normalizeImages = (images) => {
    if (!images) return [];
    if (typeof images === 'string') {
        try {
            const parsed = JSON.parse(images);
            if (Array.isArray(parsed)) return parsed.filter(Boolean);
            if (typeof parsed === 'string' && parsed) return [parsed];
        } catch {
            // string is direct URL
            return images.trim() ? [images.trim()] : [];
        }
        return images.trim() ? [images.trim()] : [];
    }
    if (Array.isArray(images)) {
        // flatten in case array contains JSON strings
        const flat = [];
        for (const item of images) {
            if (!item) continue;
            if (typeof item === 'string' && item.startsWith('[')) {
                try {
                    const p = JSON.parse(item);
                    if (Array.isArray(p)) flat.push(...p.filter(Boolean));
                    else flat.push(item);
                } catch { flat.push(item); }
            } else flat.push(item);
        }
        return flat.filter(Boolean);
    }
    return [];
};

const ProductGallery = ({ images = [] }) => {
    const raw = normalizeImages(images);
    const displayImages = raw.length > 0 ? raw : [PLACEHOLDER];
    const hasMultiple = displayImages.length > 1;
    const [activeIndex, setActiveIndex] = useState(0);
    const [isZoomed, setIsZoomed] = useState(false);
    const [touchStartX, setTouchStartX] = useState(null);
    const thumbsRef = useRef(null);
    const thumbRefs = useRef([]);

    // clamp activeIndex when images change
    useEffect(() => {
        if (activeIndex >= displayImages.length) setActiveIndex(0);
    }, [displayImages.length, activeIndex]);

    // scroll thumb into view when active changes
    useEffect(() => {
        const el = thumbRefs.current[activeIndex];
        if (el && thumbsRef.current) {
            el.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' });
        }
    }, [activeIndex]);

    const goPrev = useCallback(() => {
        setActiveIndex((prev) => (prev === 0 ? displayImages.length - 1 : prev - 1));
    }, [displayImages.length]);

    const goNext = useCallback(() => {
        setActiveIndex((prev) => (prev === displayImages.length - 1 ? 0 : prev + 1));
    }, [displayImages.length]);

    useEffect(() => {
        const onKey = (e) => {
            if (!hasMultiple) return;
            if (e.key === 'ArrowLeft') goNext(); // RTL
            if (e.key === 'ArrowRight') goPrev();
            if (e.key === 'Escape') setIsZoomed(false);
        };
        window.addEventListener('keydown', onKey);
        return () => window.removeEventListener('keydown', onKey);
    }, [goPrev, goNext, hasMultiple]);

    const onTouchStart = (e) => setTouchStartX(e.touches[0].clientX);
    const onTouchEnd = (e) => {
        if (touchStartX === null) return;
        const diff = e.changedTouches[0].clientX - touchStartX;
        if (Math.abs(diff) > 50) {
            if (diff > 0) goPrev();
            else goNext();
        }
        setTouchStartX(null);
    };

    const onError = (e) => { e.currentTarget.src = PLACEHOLDER; };

    return (
        <div className="w-full flex flex-col gap-3">
            {/* ── Layout: desktop → thumbs vertical left + main right, mobile → main top + thumbs bottom ── */}
            <div className="flex flex-col lg:flex-row-reverse gap-3 lg:gap-4">
                {/* Main Image */}
                <div
                    className="flex-1 relative aspect-square bg-white rounded-2xl lg:rounded-[24px] overflow-hidden border border-slate-200 shadow-sm group select-none"
                    onTouchStart={hasMultiple ? onTouchStart : undefined}
                    onTouchEnd={hasMultiple ? onTouchEnd : undefined}
                >
                    <AnimatePresence mode="wait">
                        <motion.img
                            key={activeIndex}
                            initial={{ opacity: 0, scale: 0.985 }}
                            animate={{ opacity: 1, scale: 1 }}
                            exit={{ opacity: 0, scale: 1.015 }}
                            transition={{ duration: 0.32, ease: [0.22, 1, 0.36, 1] }}
                            src={displayImages[activeIndex]}
                            alt={`صورة المنتج ${activeIndex + 1}`}
                            onError={onError}
                            className="w-full h-full object-contain p-4 lg:p-6 bg-[#fcfcfc]"
                            draggable={false}
                        />
                    </AnimatePresence>

                    {/* subtle top gradient */}
                    <div className="pointer-events-none absolute inset-0 bg-gradient-to-t from-black/[0.04] via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />

                    {hasMultiple && (
                        <>
                            {/* Arrows */}
                            <button
                                onClick={goPrev}
                                aria-label="الصورة السابقة"
                                className="absolute right-3 top-1/2 -translate-y-1/2 w-9 h-9 lg:w-10 lg:h-10 bg-white/95 backdrop-blur border border-slate-200 rounded-full flex items-center justify-center text-slate-700 hover:bg-white hover:text-slate-900 shadow-md hover:scale-105 transition-all"
                            >
                                <ChevronRight size={18} />
                            </button>
                            <button
                                onClick={goNext}
                                aria-label="الصورة التالية"
                                className="absolute left-3 top-1/2 -translate-y-1/2 w-9 h-9 lg:w-10 lg:h-10 bg-white/95 backdrop-blur border border-slate-200 rounded-full flex items-center justify-center text-slate-700 hover:bg-white hover:text-slate-900 shadow-md hover:scale-105 transition-all"
                            >
                                <ChevronLeft size={18} />
                            </button>

                            {/* Counter */}
                            <div className="absolute bottom-3 left-1/2 -translate-x-1/2 lg:left-auto lg:right-3 lg:translate-x-0 bg-slate-900/80 backdrop-blur text-white text-[11px] font-black px-2.5 py-1 rounded-full">
                                {activeIndex + 1} / {displayImages.length}
                            </div>

                            {/* Expand (desktop) */}
                            <button
                                onClick={() => setIsZoomed(true)}
                                aria-label="تكبير الصورة"
                                className="hidden lg:flex absolute top-3 left-3 w-8 h-8 bg-white/90 backdrop-blur border border-slate-200 rounded-full items-center justify-center text-slate-600 hover:text-slate-900 opacity-0 group-hover:opacity-100 transition-opacity"
                            >
                                <Expand size={14} />
                            </button>

                            {/* Dots (mobile) */}
                            <div className="absolute bottom-10 left-1/2 -translate-x-1/2 flex gap-1.5 lg:hidden">
                                {displayImages.map((_, i) => (
                                    <span
                                        key={i}
                                        className={`h-1.5 rounded-full transition-all duration-300 ${i === activeIndex ? 'w-5 bg-slate-900' : 'w-1.5 bg-slate-300'}`}
                                    />
                                ))}
                            </div>
                        </>
                    )}
                </div>

                {/* Thumbnails */}
                {hasMultiple && (
                    <div
                        ref={thumbsRef}
                        className="flex lg:flex-col gap-2 overflow-x-auto lg:overflow-y-auto lg:overflow-x-hidden lg:w-[84px] shrink-0 snap-x snap-mandatory lg:snap-none py-1 px-1 lg:px-0 lg:py-0 scroll-smooth"
                        style={{ scrollbarWidth: 'none' }}
                    >
                        {displayImages.map((img, i) => (
                            <button
                                key={`${img}-${i}`}
                                ref={(el) => (thumbRefs.current[i] = el)}
                                onClick={() => setActiveIndex(i)}
                                aria-label={`عرض صورة ${i + 1}`}
                                aria-current={i === activeIndex}
                                className={`relative shrink-0 snap-center w-[72px] h-[72px] lg:w-[84px] lg:h-[84px] rounded-xl lg:rounded-2xl overflow-hidden border-2 bg-white transition-all duration-200
                                    ${i === activeIndex
                                        ? 'border-orange-500 shadow-md scale-[0.98] ring-2 ring-orange-500/20'
                                        : 'border-slate-200 hover:border-slate-300 opacity-80 hover:opacity-100'}`}
                            >
                                <img
                                    src={img}
                                    alt=""
                                    onError={onError}
                                    className="w-full h-full object-cover"
                                    loading="lazy"
                                />
                                {i === activeIndex && (
                                    <motion.div layoutId="pg-active" className="absolute inset-0 bg-orange-500/10 pointer-events-none" />
                                )}
                            </button>
                        ))}
                    </div>
                )}
            </div>

            {/* Zoom / Lightbox */}
            <AnimatePresence>
                {isZoomed && (
                    <motion.div
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        className="fixed inset-0 z-[99999] bg-slate-900/90 backdrop-blur-md flex items-center justify-center p-4 lg:p-8"
                        onClick={() => setIsZoomed(false)}
                    >
                        <button
                            onClick={() => setIsZoomed(false)}
                            aria-label="إغلاق"
                            className="absolute top-4 right-4 lg:top-6 lg:right-6 w-10 h-10 bg-white/10 hover:bg-white/20 rounded-full flex items-center justify-center text-white transition-colors"
                        >
                            <X size={20} />
                        </button>

                        <motion.img
                            initial={{ scale: 0.92, opacity: 0 }}
                            animate={{ scale: 1, opacity: 1 }}
                            exit={{ scale: 0.92, opacity: 0 }}
                            transition={{ type: 'spring', damping: 24, stiffness: 260 }}
                            src={displayImages[activeIndex]}
                            alt=""
                            className="max-w-full max-h-[85vh] object-contain rounded-2xl shadow-2xl bg-white"
                            onClick={(e) => e.stopPropagation()}
                        />

                        {hasMultiple && (
                            <>
                                <button
                                    onClick={(e) => { e.stopPropagation(); goPrev(); }}
                                    className="absolute right-4 lg:right-8 top-1/2 -translate-y-1/2 w-11 h-11 lg:w-12 lg:h-12 bg-white rounded-full flex items-center justify-center text-slate-900 shadow-xl hover:scale-105 transition-transform"
                                >
                                    <ChevronRight size={22} />
                                </button>
                                <button
                                    onClick={(e) => { e.stopPropagation(); goNext(); }}
                                    className="absolute left-4 lg:left-8 top-1/2 -translate-y-1/2 w-11 h-11 lg:w-12 lg:h-12 bg-white rounded-full flex items-center justify-center text-slate-900 shadow-xl hover:scale-105 transition-transform"
                                >
                                    <ChevronLeft size={22} />
                                </button>
                                <div className="absolute bottom-6 left-1/2 -translate-x-1/2 bg-white/95 backdrop-blur px-3 py-1.5 rounded-full text-xs font-black text-slate-700 border border-slate-200">
                                    {activeIndex + 1} / {displayImages.length}
                                </div>
                            </>
                        )}
                    </motion.div>
                )}
            </AnimatePresence>

            <style>{`.snap-x::-webkit-scrollbar{display:none}.snap-x{-ms-overflow-style:none;scrollbar-width:none}`}</style>
        </div>
    );
};

export default ProductGallery;
