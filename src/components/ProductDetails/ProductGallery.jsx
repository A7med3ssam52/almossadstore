import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

const ProductGallery = ({ images = [] }) => {
    const [activeIndex, setActiveIndex] = useState(0);
    const placeholder = 'https://via.placeholder.com/600x600.png?text=Al+Mossad+Store';

    const displayImages = images.length > 0 ? images : [placeholder];

    return (
        <div className="flex flex-col gap-3 md:gap-4 w-full max-w-[360px] sm:max-w-[420px] md:max-w-none mx-auto">
            {/* Main Image */}
            <div className="relative aspect-square bg-slate-50 rounded-3xl md:rounded-[2.5rem] overflow-hidden border border-slate-100 shadow-inner group">
                <AnimatePresence mode="wait">
                    <motion.img
                        key={activeIndex}
                        initial={{ opacity: 0, scale: 1.1 }}
                        animate={{ opacity: 1, scale: 1 }}
                        exit={{ opacity: 0, scale: 0.9 }}
                        transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
                        src={displayImages[activeIndex]}
                        alt=""
                        className="w-full h-full object-contain md:object-cover p-2 md:p-0"
                    />
                </AnimatePresence>

                {/* Overlay Hint */}
                <div className="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none" />
            </div>

            {/* Thumbnails */}
            {displayImages.length > 1 && (
                <div className="flex items-center justify-center md:justify-start gap-2 md:gap-3 px-1 md:px-2 overflow-x-auto no-scrollbar py-2">
                    {displayImages.map((img, i) => (
                        <button
                            key={i}
                            onClick={() => setActiveIndex(i)}
                            className={`relative w-16 h-16 md:w-20 md:h-20 rounded-xl md:rounded-2xl overflow-hidden shrink-0 transition-all duration-300 transform
                                ${i === activeIndex
                                    ? 'ring-2 ring-orange-600 ring-offset-2 md:ring-offset-4 scale-95 shadow-lg'
                                    : 'opacity-60 hover:opacity-100 hover:scale-105 border border-slate-200 shadow-sm'}`}
                        >
                            <img src={img} alt="" className="w-full h-full object-cover" />
                            {i === activeIndex && (
                                <motion.div
                                    layoutId="active-thumb"
                                    className="absolute inset-0 bg-orange-600/10 pointer-events-none"
                                />
                            )}
                        </button>
                    ))}
                </div>
            )}
        </div>
    );
};

export default ProductGallery;
