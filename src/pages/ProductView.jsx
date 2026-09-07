import React, { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import {
    Package, ChevronRight, ShoppingCart, MessageCircle,
    ShieldCheck, Truck, RefreshCw, Loader2, ArrowRight,
    Star, Tag, Minus, Plus, Heart, Share2, CheckCircle,
    AlertTriangle
} from 'lucide-react';
import { getProductById } from '@/services/supabase/inventoryService';
import ProductGallery from '@/components/ProductDetails/ProductGallery';
import { useCart } from '../context/CartContext';
import { formatPrice, getDiscountedPrice, getOriginalPrice, hasDiscount as hasProductDiscount, getProductImage } from '@/utils/formatters';

const PLACEHOLDER_IMAGE = 'https://placehold.co/600x600/f1f5f9/94a3b8?text=%D8%A2%D9%84+%D9%85%D8%B3%D8%B9%D8%AF';

const GuaranteeBadge = ({ icon: Icon, title, subtitle, color }) => (
    <div style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: '8px',
        padding: '16px 12px',
        background: '#f8fafc',
        borderRadius: '16px',
        border: '1px solid #f1f5f9',
        textAlign: 'center',
        flex: 1
    }}>
        <div style={{ width: '40px', height: '40px', background: color + '15', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Icon size={20} color={color} />
        </div>
        <p style={{ fontSize: '11px', fontWeight: 800, color: '#0f172a', margin: 0 }}>{title}</p>
        {subtitle && <p style={{ fontSize: '10px', color: '#94a3b8', fontWeight: 500, margin: 0 }}>{subtitle}</p>}
    </div>
);

const ProductView = () => {
    const { id } = useParams();
    const { addToCart } = useCart();
    const [product, setProduct] = useState(null);
    const [loading, setLoading] = useState(true);
    const [qty, setQty] = useState(1);
    const [addedToCart, setAddedToCart] = useState(false);
    const [selectedVariant, setSelectedVariant] = useState(null);
    const [variantError, setVariantError] = useState('');

    useEffect(() => {
        const load = async () => {
            const { data } = await getProductById(id);
            setProduct(data);
            // auto-select first variant if exists
            if (data?.product_variants?.length > 0) setSelectedVariant(data.product_variants[0]);
            setLoading(false);
        };
        load();
        window.scrollTo(0, 0);
    }, [id]);

    const handleAddToCart = () => {
        // منع إضافة سعر 0 (P? + C-CART-01)
        const effectivePrice = selectedVariant?.price != null ? Number(selectedVariant.price) : getDiscountedPrice(product);
        if (!effectivePrice || effectivePrice <= 0) {
            setVariantError('هذا المنتج غير مسعر، تواصل معنا');
            return;
        }
        if (product.product_variants?.length > 0 && !selectedVariant) {
            setVariantError('اختر النوع أولاً');
            return;
        }
        setVariantError('');
        const options = selectedVariant ? { variant_id: selectedVariant.id, variant_name: selectedVariant.name || selectedVariant.title || selectedVariant.sku || '' } : null;
        // إذا كان variant له سعر خاص، مرر product معدل السعر
        const productForCart = selectedVariant?.price != null ? { ...product, base_price: selectedVariant.price, sale_price: null, discount: 0, stock_quantity: selectedVariant.stock_quantity ?? product.stock_quantity } : product;
        addToCart(productForCart, qty, options);
        setAddedToCart(true);
        setTimeout(() => setAddedToCart(false), 2500);
    };

    if (loading) return (
        <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#f8fafc' }}>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '16px' }}>
                <div style={{ width: '44px', height: '44px', border: '4px solid #f1f5f9', borderTop: '4px solid #ea580c', borderRadius: '50%', animation: 'pv-spin 0.75s linear infinite' }} />
                <style>{`@keyframes pv-spin { to { transform: rotate(360deg); } }`}</style>
                <p style={{ color: '#94a3b8', fontWeight: 700 }}>جارٍ تحميل المنتج...</p>
            </div>
        </div>
    );

    if (!product) return (
        <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#f8fafc', textAlign: 'center', padding: '20px' }} dir="rtl">
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '20px', maxWidth: '360px' }}>
                <div style={{ width: '80px', height: '80px', background: '#f1f5f9', borderRadius: '24px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <Package size={40} color="#cbd5e1" />
                </div>
                <h2 style={{ fontSize: '22px', fontWeight: 900, color: '#0f172a', margin: 0 }}>هذا المنتج غير موجود</h2>
                <p style={{ color: '#64748b', fontWeight: 500, margin: 0 }}>ربما تم حذفه أو تغيير رابطه.</p>
                <Link to="/" style={{
                    display: 'inline-flex', alignItems: 'center', gap: '8px',
                    padding: '12px 28px', background: '#ea580c', color: '#fff',
                    borderRadius: '14px', fontWeight: 700, textDecoration: 'none',
                    boxShadow: '0 8px 20px rgba(234,88,12,0.25)'
                }}>
                    <ArrowRight size={16} />العودة للمتجر
                </Link>
            </div>
        </div>
    );

    const isOutOfStock = (selectedVariant?.stock_quantity ?? product.stock_quantity) === 0;
    const hasDiscount = hasProductDiscount(product);
    const basePrice = selectedVariant?.price != null ? Number(selectedVariant.price) : getOriginalPrice(product);
    const discountedPrice = selectedVariant?.price != null ? Number(selectedVariant.price) : getDiscountedPrice(product);
    const mainImage = getProductImage(product) || PLACEHOLDER_IMAGE;
    const isContactPrice = discountedPrice === 0 && basePrice === 0;
    const variants = product.product_variants || [];

    return (
        <div style={{ minHeight: '100vh', background: '#f8fafc', paddingBottom: '80px' }} dir="rtl">
            {/* Breadcrumb */}
            <div style={{ background: '#fff', borderBottom: '1px solid #f1f5f9', padding: '14px 0' }}>
                <div className="container">
                    <nav style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '12px', fontWeight: 600, color: '#94a3b8', overflowX: 'auto', whiteSpace: 'nowrap' }}>
                        <Link to="/" style={{ color: '#64748b', textDecoration: 'none', transition: 'color 0.2s' }}
                            onMouseEnter={e => e.target.style.color = '#ea580c'}
                            onMouseLeave={e => e.target.style.color = '#64748b'}>الرئيسية</Link>
                        <ChevronRight size={12} style={{ opacity: 0.4 }} />
                        <span style={{ color: '#64748b' }}>{product.categories?.name || 'المنتجات'}</span>
                        <ChevronRight size={12} style={{ opacity: 0.4 }} />
                        <span style={{ color: '#0f172a', fontWeight: 700, overflow: 'hidden', textOverflow: 'ellipsis', maxWidth: '200px' }}>{product.name}</span>
                    </nav>
                </div>
            </div>

            <div className="container" style={{ paddingTop: '32px' }}>
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 lg:gap-12 items-start">

                    {/* LEFT: Gallery */}
                    <div className="lg:sticky lg:top-6 min-w-0">
                        <ProductGallery images={product.images && product.images.length > 0 ? product.images : (mainImage ? [mainImage] : [])} />
                        {product.is_featured && (
                            <div style={{
                                display: 'inline-flex', alignItems: 'center', gap: '6px',
                                marginTop: '16px', padding: '6px 14px',
                                background: 'linear-gradient(135deg, #fbbf24, #f59e0b)',
                                borderRadius: '999px', color: '#fff', fontWeight: 800, fontSize: '12px'
                            }}>
                                <Star size={13} fill="currentColor" strokeWidth={0} />
                                منتج مميز
                            </div>
                        )}
                    </div>

                    {/* RIGHT: Details */}
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>

                        {/* Category + Title */}
                        <div>
                            {product.categories?.name && (
                                <div style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', padding: '5px 14px', background: '#fff7ed', border: '1px solid #fed7aa', borderRadius: '999px', marginBottom: '12px' }}>
                                    <Tag size={11} color="#ea580c" />
                                    <span style={{ fontSize: '11px', fontWeight: 800, color: '#ea580c', textTransform: 'uppercase', letterSpacing: '0.08em' }}>
                                        {product.categories.name}
                                    </span>
                                </div>
                            )}
                            <h1 style={{ fontSize: '30px', fontWeight: 900, color: '#0f172a', lineHeight: 1.25, margin: '0 0 12px', letterSpacing: '-0.02em' }}>
                                {product.name}
                            </h1>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', padding: '4px 12px', background: isOutOfStock ? '#fef2f2' : '#f0fdf4', borderRadius: '8px' }}>
                                    <div style={{ width: '7px', height: '7px', borderRadius: '50%', background: isOutOfStock ? '#ef4444' : '#22c55e' }} />
                                    <span style={{ fontSize: '12px', fontWeight: 700, color: isOutOfStock ? '#dc2626' : '#16a34a' }}>
                                        {isOutOfStock ? 'غير متوفر' : 'متوفر في المخزون'}
                                    </span>
                                </div>
                                <span style={{ fontSize: '11px', color: '#94a3b8', fontWeight: 600 }}>
                                    SKU: AM-{product.id?.split('-')[0]?.toUpperCase()}
                                </span>
                            </div>
                        </div>

                        {/* Price Block */}
                        <div style={{
                            background: '#fff', border: '1.5px solid #f1f5f9', borderRadius: '24px',
                            padding: '28px', boxShadow: '0 4px 20px rgba(0,0,0,0.05)'
                        }}>
                            {/* Variant selector */}
                            {variants.length > 0 && (
                                <div style={{ marginBottom: '16px' }}>
                                    <p style={{ fontSize: '12px', fontWeight: 800, color: '#334155', marginBottom: '8px' }}>اختر النوع:</p>
                                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
                                        {variants.map(v => (
                                            <button
                                                key={v.id}
                                                type="button"
                                                onClick={() => { setSelectedVariant(v); setVariantError(''); }}
                                                style={{
                                                    padding: '8px 14px',
                                                    borderRadius: '10px',
                                                    border: selectedVariant?.id === v.id ? '2px solid #ea580c' : '1.5px solid #e2e8f0',
                                                    background: selectedVariant?.id === v.id ? '#fff7ed' : '#fff',
                                                    color: selectedVariant?.id === v.id ? '#ea580c' : '#475569',
                                                    fontWeight: 800,
                                                    fontSize: '12px',
                                                    cursor: 'pointer'
                                                }}
                                            >
                                                {v.name || v.title || v.sku || `نوع ${v.id.slice(0,4)}`} {v.price ? `- ${Number(v.price).toLocaleString()} ج.م` : ''}
                                            </button>
                                        ))}
                                    </div>
                                    {variantError && <p style={{ color: '#dc2626', fontSize: '11px', fontWeight: 700, marginTop: '6px' }}>{variantError}</p>}
                                </div>
                            )}
                            {!isContactPrice ? (
                                <>
                                    <div style={{ display: 'flex', alignItems: 'baseline', gap: '12px', marginBottom: '4px' }}>
                                        <span style={{ fontSize: '42px', fontWeight: 900, color: '#0f172a', fontFamily: 'sans-serif', letterSpacing: '-0.03em' }}>
                                            {Number(discountedPrice).toLocaleString()}
                                        </span>
                                        <span style={{ fontSize: '16px', fontWeight: 700, color: '#94a3b8', marginBottom: '6px' }}>ج.م</span>
                                        {hasDiscount && basePrice > discountedPrice && (
                                            <span style={{ fontSize: '18px', color: '#cbd5e1', textDecoration: 'line-through', fontFamily: 'sans-serif' }}>
                                                {Number(basePrice).toLocaleString()}
                                            </span>
                                        )}
                                    </div>
                                    {hasDiscount && !selectedVariant && (
                                        <div style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', padding: '3px 10px', background: '#fef2f2', borderRadius: '6px', marginBottom: '20px' }}>
                                            <span style={{ fontSize: '12px', fontWeight: 800, color: '#ef4444' }}>وفّر {product.discount}% 🎉</span>
                                        </div>
                                    )}

                                    {/* Quantity + Add to Cart */}
                                    <div style={{ display: 'flex', gap: '12px', alignItems: 'center', marginTop: hasDiscount ? '8px' : '20px' }}>
                                        {/* Qty Selector */}
                                        <div style={{
                                            display: 'flex', alignItems: 'center',
                                            background: '#f8fafc', borderRadius: '14px',
                                            border: '1.5px solid #e2e8f0', padding: '4px',
                                            gap: '2px', flexShrink: 0
                                        }}>
                                            <button
                                                onClick={() => setQty(Math.max(1, qty - 1))}
                                                style={{ width: '40px', height: '40px', display: 'flex', alignItems: 'center', justifyContent: 'center', border: 'none', background: 'transparent', cursor: 'pointer', borderRadius: '10px', color: '#64748b', transition: 'all 0.2s' }}
                                                onMouseEnter={e => { e.currentTarget.style.background = '#e2e8f0'; e.currentTarget.style.color = '#0f172a'; }}
                                                onMouseLeave={e => { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.color = '#64748b'; }}
                                            ><Minus size={16} /></button>
                                            <span style={{ width: '36px', textAlign: 'center', fontWeight: 900, fontSize: '16px', color: '#0f172a', fontFamily: 'sans-serif' }}>{qty}</span>
                                            <button
                                                onClick={() => setQty(prev => product.stock_quantity ? Math.min(product.stock_quantity, prev + 1) : prev + 1)}
                                                style={{ width: '40px', height: '40px', display: 'flex', alignItems: 'center', justifyContent: 'center', border: 'none', background: 'transparent', cursor: 'pointer', borderRadius: '10px', color: '#64748b', transition: 'all 0.2s' }}
                                                onMouseEnter={e => { e.currentTarget.style.background = '#e2e8f0'; e.currentTarget.style.color = '#0f172a'; }}
                                                onMouseLeave={e => { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.color = '#64748b'; }}
                                            ><Plus size={16} /></button>
                                        </div>

                                        {/* Add to Cart Button */}
                                        <button
                                            onClick={handleAddToCart}
                                            disabled={isOutOfStock || isContactPrice}
                                            title={isContactPrice ? 'تواصل لمعرفة السعر' : ''}
                                            style={{
                                                flex: 1, padding: '13px 20px', border: 'none', cursor: (isOutOfStock || isContactPrice) ? 'not-allowed' : 'pointer',
                                                background: addedToCart ? '#22c55e' : (isOutOfStock || isContactPrice) ? '#cbd5e1' : 'linear-gradient(135deg, #ea580c, #f97316)',
                                                color: '#fff', borderRadius: '14px', fontWeight: 800, fontSize: '14px',
                                                display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px',
                                                boxShadow: (isOutOfStock || isContactPrice) ? 'none' : addedToCart ? '0 8px 20px rgba(34,197,94,0.3)' : '0 8px 20px rgba(234,88,12,0.3)',
                                                transition: 'all 0.3s',
                                                transform: 'scale(1)',
                                            }}
                                            onMouseEnter={e => { if (!(isOutOfStock || isContactPrice) && !addedToCart) e.currentTarget.style.transform = 'scale(1.02)'; }}
                                            onMouseLeave={e => { e.currentTarget.style.transform = 'scale(1)'; }}
                                        >
                                            {addedToCart
                                                ? <><CheckCircle size={18} />تمت الإضافة!</>
                                                : isContactPrice ? <>تواصل لمعرفة السعر</> : <><ShoppingCart size={18} />أضف للسلة</>
                                            }
                                        </button>
                                    </div>
                                </>
                            ) : (
                                <div style={{ textAlign: 'center', padding: '8px 0' }}>
                                    <p style={{ fontSize: '22px', fontWeight: 900, color: '#ea580c', margin: '0 0 8px' }}>تواصل لمعرفة السعر</p>
                                    <p style={{ fontSize: '13px', color: '#94a3b8', fontWeight: 500, margin: 0 }}>
                                        هذا المنتج غير مسعر حالياً، تواصل معنا للتفاصيل
                                    </p>
                                </div>
                            )}

                            {/* WhatsApp */}
                            <a
                                href="https://wa.me/+201000000000"
                                target="_blank"
                                rel="noreferrer"
                                style={{
                                    display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px',
                                    width: '100%', marginTop: '12px', padding: '12px',
                                    background: '#f0fdf4', border: '1.5px solid #bbf7d0',
                                    borderRadius: '14px', color: '#16a34a', fontWeight: 700, fontSize: '13px',
                                    textDecoration: 'none', transition: 'all 0.2s'
                                }}
                                onMouseEnter={e => { e.currentTarget.style.background = '#dcfce7'; }}
                                onMouseLeave={e => { e.currentTarget.style.background = '#f0fdf4'; }}
                            >
                                <MessageCircle size={18} />
                                استفسر عبر واتساب
                            </a>
                        </div>

                        {product.stock_quantity !== null && product.stock_quantity <= 5 && product.stock_quantity > 0 && (
                            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '10px 14px', background: '#fffbeb', border: '1px solid #fde68a', borderRadius: '12px', color: '#92400e', fontSize: '12px', fontWeight: 700 }}>
                                <AlertTriangle size={14} /> متبقي {product.stock_quantity} فقط في المخزون
                            </div>
                        )}
                        {/* Description */}
                        {product.description && (
                            <div style={{ background: '#fff', border: '1.5px solid #f1f5f9', borderRadius: '20px', padding: '24px' }}>
                                <h3 style={{ fontSize: '14px', fontWeight: 900, color: '#0f172a', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: '12px' }}>
                                    تفاصيل المنتج
                                </h3>
                                <p style={{ color: '#475569', lineHeight: 1.8, fontWeight: 500, margin: 0, fontSize: '14px' }}>
                                    {product.description}
                                </p>
                            </div>
                        )}

                        {/* Guarantees */}
                        <div className="pv-guarantee-row" style={{ display: 'flex', gap: '10px' }}>
                            <GuaranteeBadge icon={Truck} title="توصيل سريع" subtitle="لجميع المناطق" color="#3b82f6" />
                            <GuaranteeBadge icon={ShieldCheck} title="منتج أصلي" subtitle="ضمان الجودة" color="#22c55e" />
                            <GuaranteeBadge icon={RefreshCw} title="إرجاع سهل" subtitle="خلال 14 يوم" color="#f59e0b" />
                        </div>
                    </div>
                </div>
            </div>

            {/* Responsive: guarantee row wraps on mobile */}
            <style>{`
                @media (max-width: 768px) {
                    .pv-guarantee-row { flex-wrap: wrap !important; }
                    .pv-guarantee-row > div { flex: 1 1 calc(33% - 8px) !important; min-width: 90px !important; }
                }
            `}</style>
        </div>
    );
};

export default ProductView;
