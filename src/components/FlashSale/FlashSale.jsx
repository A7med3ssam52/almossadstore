import React, { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { getProducts } from '@/services/supabase/inventoryService';
import { formatPrice, getDiscountedPrice, getOriginalPrice, hasDiscount as hasProductDiscount, getProductImage } from '@/utils/formatters';
import { Star, ShoppingBag, Eye } from 'lucide-react';
import './FlashSale.css';

const PLACEHOLDER_IMAGE = 'https://placehold.co/600x600/f1f5f9/94a3b8?text=%D8%A2%D9%84+%D9%85%D8%B3%D8%B9%D8%AF';

export const ProductCard = ({ product }) => {
    const [hovered, setHovered] = useState(false);
    const mainImage = getProductImage(product) || PLACEHOLDER_IMAGE;

    const isOutOfStock = product.stock_quantity === 0;
    const hasDiscount = hasProductDiscount(product);
    const discountedPrice = getDiscountedPrice(product);
    const originalPrice = getOriginalPrice(product);

    return (
        <Link
            to={`/product/${product.id}`}
            className="pc-card"
            onMouseEnter={() => setHovered(true)}
            onMouseLeave={() => setHovered(false)}
            style={{ textDecoration: 'none' }}
        >
            {/* Image Area */}
            <div className="pc-img-wrap">
                <img
                    src={mainImage}
                    alt={product.name}
                    className={`pc-img ${hovered ? 'pc-img-zoom' : ''}`}
                />

                {/* Gradient Overlay on hover */}
                <div className={`pc-overlay ${hovered ? 'pc-overlay-visible' : ''}`} />

                {/* Badges top-right */}
                <div className="pc-badges-right">
                    {hasDiscount && (
                        <span className="pc-badge pc-badge-discount">-{product.discount}%</span>
                    )}
                    {product.is_featured && (
                        <span className="pc-badge pc-badge-featured">
                            <Star size={12} fill="currentColor" strokeWidth={0} />
                            مميز
                        </span>
                    )}
                </div>

                {/* Category badge top-left */}
                {product.categories?.name && (
                    <span className="pc-cat-badge">{product.categories.name}</span>
                )}

                {/* Out of stock */}
                {isOutOfStock && (
                    <div className="pc-oos">
                        <span>نفد من المخزون</span>
                    </div>
                )}

                {/* Hover CTA bar */}
                <div className={`pc-cta-bar ${hovered && !isOutOfStock ? 'pc-cta-visible' : ''}`}>
                    <span className="pc-cta-inner">
                        <ShoppingBag size={15} />
                        أضف للسلة
                    </span>
                    <span className="pc-cta-divider" />
                    <span className="pc-cta-inner">
                        <Eye size={15} />
                        عرض
                    </span>
                </div>
            </div>

            {/* Info Area */}
            <div className="pc-info" dir="rtl">
                <p className="pc-cat-name">{product.categories?.name || 'آل مسعد'}</p>
                <h3 className="pc-name">{product.name}</h3>
                <div className="pc-price-row">
                    {discountedPrice > 0 || originalPrice > 0 ? (
                        <>
                            <span className="pc-price">
                                {formatPrice(discountedPrice)}
                            </span>
                            {hasDiscount && originalPrice > discountedPrice && (
                                <span className="pc-old-price">{formatPrice(originalPrice)}</span>
                            )}
                        </>
                    ) : (
                        <span className="pc-contact-price">تواصل لمعرفة السعر</span>
                    )}
                </div>
            </div>
        </Link>
    );
};

const FlashSale = () => {
    const [products, setProducts] = useState([]);
    const [loading, setLoading] = useState(true);
    const [isInView, setIsInView] = useState(false);
    const sectionRef = useRef(null);

    useEffect(() => {
        const loadProducts = async () => {
            const { data } = await getProducts();
            if (data) setProducts(data.slice(0, 8));
            setLoading(false);
        };
        loadProducts();

        const observer = new IntersectionObserver(
            ([entry]) => {
                if (entry.isIntersecting) {
                    setIsInView(true);
                    observer.unobserve(entry.target);
                }
            },
            { threshold: 0.1 }
        );

        if (sectionRef.current) observer.observe(sectionRef.current);
        return () => { if (sectionRef.current) observer.unobserve(sectionRef.current); };
    }, []);

    return (
        <section className="flash-sale-section" ref={sectionRef}>
            <div className="container">
                <div className="section-header">
                    <h2>عروض فلاش سيل</h2>
                    <p>أفضل وأقوى عروض فلاش سيل من آل مسعد على الموقع الألكتروني</p>
                </div>

                {loading ? (
                    <div style={{ display: 'flex', justifyContent: 'center', padding: '60px 0' }}>
                        <div className="pc-spinner" />
                    </div>
                ) : (
                    <div className={`products-grid ${isInView ? 'trigger-hint' : ''}`}>
                        {products.length > 0 ? (
                            products.map((p) => <ProductCard key={p.id} product={p} />)
                        ) : (
                            <p style={{ gridColumn: '1/-1', textAlign: 'center', padding: '48px 0', color: '#94a3b8', fontWeight: 700 }}>
                                لا توجد منتجات حالياً
                            </p>
                        )}
                    </div>
                )}
            </div>
        </section>
    );
};

export default FlashSale;
