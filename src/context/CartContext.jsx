import React, { createContext, useContext, useState, useEffect, useCallback, useRef, useMemo } from 'react';
import { supabase } from '../supabaseClient';
import { getDiscountedPrice, getProductImage } from '@/utils/formatters';
import { validateCoupon, calculateDiscount } from '@/services/supabase/couponService';

const CartContext = createContext();

const CART_DELETED_KEY = 'mosad_cart_deleted';
const CART_CLEARED_KEY = 'mosad_cart_cleared';
const CART_STORAGE_KEY = 'mosad_cart';

// ── Canonical helpers: ترتيب مفاتيح options لضمان مفتاح ثابت ──
const canonicalStringify = (obj) => {
    if (!obj || typeof obj !== 'object' || Array.isArray(obj)) {
        try { return JSON.stringify(obj || {}); } catch { return '{}'; }
    }
    const sorted = {};
    Object.keys(obj).sort().forEach(k => { sorted[k] = obj[k]; });
    try { return JSON.stringify(sorted); } catch { return '{}'; }
};
const makeKey = (id, options) => `${id}-${canonicalStringify(options || {})}`;

const getDeletedSet = () => {
    try {
        const raw = localStorage.getItem(CART_DELETED_KEY);
        return new Set(raw ? JSON.parse(raw) : []);
    } catch { return new Set(); }
};
const addDeletedKey = (key) => {
    try {
        const set = getDeletedSet();
        set.add(key);
        localStorage.setItem(CART_DELETED_KEY, JSON.stringify([...set]));
    } catch {}
};
const removeDeletedKey = (key) => {
    try {
        const set = getDeletedSet();
        set.delete(key);
        localStorage.setItem(CART_DELETED_KEY, JSON.stringify([...set]));
    } catch {}
};

export const CartProvider = ({ children }) => {
    const [cartItems, setCartItems] = useState(() => {
        try {
            const localData = localStorage.getItem(CART_STORAGE_KEY);
            const parsed = localData ? JSON.parse(localData) : [];
            // تنظيف قديم: إزالة عناصر تالفة
            return Array.isArray(parsed) ? parsed.filter(i => i && i.id && typeof i.quantity === 'number') : [];
        } catch (error) {
            console.error('Failed to parse cart data from localStorage:', error);
            return [];
        }
    });

    const [isCartOpen, setIsCartOpen] = useState(false);
    const [isSyncing, setIsSyncing] = useState(false);
    const [isHydrated, setIsHydrated] = useState(false);
    const [user, setUser] = useState(null);
    const syncTimeoutRef = useRef(null);
    const isInitialMountRef = useRef(true);
    const latestCartRef = useRef([]);
    const pendingSyncRef = useRef(null);

    // ── Coupon State (Professional Cart: shared between Drawer & Checkout) ──
    const [coupon, setCoupon] = useState(null);
    const [couponCode, setCouponCode] = useState('');
    const [couponError, setCouponError] = useState('');
    const [couponLoading, setCouponLoading] = useState(false);

    // ── Auth listener ──
    useEffect(() => {
        const getSession = async () => {
            try {
                const { data: { session } } = await supabase.auth.getSession();
                setUser(session?.user || null);
            } catch { setUser(null); }
            finally { setTimeout(() => setIsHydrated(true), 0); }
        };
        getSession();
        const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
            setUser(session?.user || null);
        });
        return () => subscription.unsubscribe();
    }, []);

    // ── Merge guest cart with user cart on login (حل نهائي للاندماج) ──
    useEffect(() => {
        if (!isHydrated) return;
        const syncOnLogin = async () => {
            if (!user) return;
            setIsSyncing(true);
            try {
                const { data: remoteItems, error } = await supabase
                    .from('cart_items')
                    .select(`
                        id,
                        product_id,
                        quantity,
                        options,
                        products (
                            name,
                            name_ar,
                            base_price,
                            discount,
                            price,
                            sale_price,
                            stock_quantity,
                            images,
                            image_url
                        )
                    `)
                    .eq('user_id', user.id);
                if (error) throw error;

                const wasCleared = (() => {
                    try { return localStorage.getItem(CART_CLEARED_KEY) === '1'; } catch { return false; }
                })();
                const deletedSet = getDeletedSet();

                setCartItems(prevLocal => {
                    // إذا تم مسح السلة وهي فارغة وهناك علامة مسح، لا تعيد عناصر محذوفة
                    if (prevLocal.length === 0 && wasCleared) return [];

                    const mergedMap = new Map();
                    if (remoteItems) {
                        remoteItems.forEach(item => {
                            const product = item.products;
                            const key = makeKey(item.product_id, item.options);
                            if (deletedSet.has(key)) return; // تجاهل عنصر محذوف محلياً
                            const remotePrice = getDiscountedPrice(product);
                            const resolvedImage = getProductImage(product) || product?.image_url || null;
                            mergedMap.set(key, {
                                id: item.product_id,
                                name: product?.name || product?.name_ar || 'منتج',
                                price: remotePrice,
                                image_url: resolvedImage,
                                image: resolvedImage,
                                quantity: Number(item.quantity) || 1,
                                options: item.options || {},
                                stock_quantity: product?.stock_quantity,
                                slug: product?.slug
                            });
                        });
                    }
                    prevLocal.forEach(localItem => {
                        const key = makeKey(localItem.id, localItem.options);
                        if (mergedMap.has(key)) {
                            const existing = mergedMap.get(key);
                            let sum = existing.quantity + (Number(localItem.quantity) || 1);
                            const cap = existing.stock_quantity ?? localItem.stock_quantity;
                            if (cap != null && sum > cap) sum = cap;
                            existing.quantity = sum;
                        } else {
                            mergedMap.set(key, localItem);
                        }
                    });
                    return Array.from(mergedMap.values());
                });

                // إذا تم مسح السلة محلياً وهي فارغة، امسح السحابة أيضاً مباشرة
                if (wasCleared) {
                    const localRaw = (() => { try { return JSON.parse(localStorage.getItem(CART_STORAGE_KEY) || '[]'); } catch { return []; } })();
                    if (Array.isArray(localRaw) && localRaw.length === 0) {
                        await supabase.from('cart_items').delete().eq('user_id', user.id);
                        try { localStorage.removeItem(CART_CLEARED_KEY); localStorage.removeItem(CART_DELETED_KEY); } catch {}
                    }
                }
            } catch (error) {
                console.error('CartContext Sync failure:', error?.message || error);
            } finally {
                setIsSyncing(false);
            }
        };
        syncOnLogin();
    }, [user, isHydrated]);

    // keep latestCartRef updated for orphan cleanup safety (C-CART-04)
    useEffect(() => { latestCartRef.current = cartItems; }, [cartItems]);

    // ── مزامنة للسحابة مع debounce 600ms + تجنب wipe غير ضروري (C-CART-02) ──
    const syncToSupabase = useCallback(async (items) => {
        if (!user) return;
        // Coalesce rapid calls: keep latest payload in pendingRef
        pendingSyncRef.current = items;
        if (syncTimeoutRef.current) clearTimeout(syncTimeoutRef.current);
        syncTimeoutRef.current = setTimeout(async () => {
            const payloadItems = pendingSyncRef.current;
            pendingSyncRef.current = null;
            if (!payloadItems) return;
            try {
                // حالة السلة الفارغة: احذف كل السحابة - لكن تحقق من أحدث state لتجنب race (C-CART-03)
                const latestLen = latestCartRef.current?.length ?? payloadItems.length;
                const effectiveItems = latestLen === 0 ? [] : payloadItems;
                // إذا تغيرت السلة أثناء debounce, استخدم أحدث snapshot إذا كان أحدث
                const itemsToSync = latestLen !== payloadItems.length ? latestCartRef.current : effectiveItems;
                if (!itemsToSync || itemsToSync.length === 0) {
                    // تأكد أن السلة فعلاً فارغة في أحدث state قبل المسح (تجنب wipe غير ضروري)
                    if (latestCartRef.current.length !== 0) return;
                    const { error: delErr } = await supabase.from('cart_items').delete().eq('user_id', user.id);
                    if (delErr) console.error('Error clearing remote cart:', delErr);
                    try { localStorage.removeItem(CART_CLEARED_KEY); localStorage.removeItem(CART_DELETED_KEY); } catch {}
                    return;
                }

                const syncPayload = itemsToSync.map(item => ({
                    user_id: user.id,
                    product_id: item.id,
                    quantity: Number(item.quantity) || 1,
                    options: item.options && typeof item.options === 'object' ? item.options : {}
                }));

                // محاولة أولى: upsert جماعي
                const { error: syncError } = await supabase
                    .from('cart_items')
                    .upsert(syncPayload, { onConflict: 'user_id,product_id,options' });

                if (syncError) {
                    const msg = (syncError.message || '').toLowerCase();
                    const isConflictErr = syncError.code === '42P10' || syncError.code === '23505' || msg.includes('conflict') || msg.includes('unique') || msg.includes('duplicate');
                    if (isConflictErr) {
                        console.warn('Cart upsert fallback: wipe+reinsert due to', syncError.message);
                        // C-CART-02: تجنب wipe إذا كان هناك تغيير جديد أثناء الانتظار
                        if (latestCartRef.current.length !== itemsToSync.length) {
                            // هناك تغييرات جديدة, أعد الجدولة بدل المسح
                            pendingSyncRef.current = latestCartRef.current;
                            if (syncTimeoutRef.current) clearTimeout(syncTimeoutRef.current);
                            syncTimeoutRef.current = setTimeout(() => syncToSupabase(latestCartRef.current), 400);
                            return;
                        }
                        const { error: wipeErr } = await supabase.from('cart_items').delete().eq('user_id', user.id);
                        if (wipeErr) throw wipeErr;
                        const { error: insertErr } = await supabase.from('cart_items').insert(syncPayload);
                        if (insertErr) throw insertErr;
                    } else {
                        throw syncError;
                    }
                }

                // C-CART-04: orphan cleanup باستخدام أحدث state (latestCartRef) وليس items snapshot القديم
                try {
                    const { data: currentRemote, error: fetchErr } = await supabase
                        .from('cart_items')
                        .select('id, product_id, options')
                        .eq('user_id', user.id);
                    if (fetchErr) throw fetchErr;
                    if (currentRemote && currentRemote.length > 0) {
                        const latestKeys = new Set(latestCartRef.current.map(i => makeKey(i.id, i.options)));
                        const orphans = currentRemote.filter(r => !latestKeys.has(makeKey(r.product_id, r.options)));
                        if (orphans.length > 0) {
                            // تأكد مرة أخرى أن العنصر فعلاً محذوف وليس Race: انتظر 300ms لو هناك pending
                            if (pendingSyncRef.current) {
                                console.warn('skip orphan cleanup due to pending sync');
                            } else {
                                const orphanIds = orphans.map(r => r.id);
                                const { error: delOrphanErr } = await supabase.from('cart_items').delete().in('id', orphanIds);
                                if (delOrphanErr) console.error('orphan cleanup failed', delOrphanErr);
                            }
                        }
                        try {
                            const deletedSet = getDeletedSet();
                            let changed = false;
                            const orphanKeys = new Set((currentRemote.filter(r => !latestKeys.has(makeKey(r.product_id, r.options)))).map(r => makeKey(r.product_id, r.options)));
                            for (const k of [...deletedSet]) {
                                if (latestKeys.has(k) || orphanKeys.has(k)) {
                                    deletedSet.delete(k);
                                    changed = true;
                                }
                            }
                            if (changed) localStorage.setItem(CART_DELETED_KEY, JSON.stringify([...deletedSet]));
                        } catch {}
                    }
                    try { localStorage.removeItem(CART_CLEARED_KEY); } catch {}
                } catch (cleanupErr) {
                    console.warn('orphan cleanup best-effort failed', cleanupErr?.message || cleanupErr);
                }
            } catch (e) {
                console.error('syncToSupabase unexpected error', e?.message || e);
            }
        }, 600);
    }, [user]);

    // ── حفظ محلي + مزامنة (مع حماية من الكتابة أثناء التحميل الأول) ──
    useEffect(() => {
        if (isInitialMountRef.current) {
            isInitialMountRef.current = false;
            return;
        }
        try {
            localStorage.setItem(CART_STORAGE_KEY, JSON.stringify(cartItems));
            syncToSupabase(cartItems);
        } catch (error) {
            console.error('Failed to save cart:', error);
        }
    }, [cartItems, syncToSupabase]);

    // في البداية أيضاً احفظ مرة لضمان التزامن؟ لا داعي، isInitialMount يمنع الكتابة المكررة
    // لكن نحتاج ضمان أن localStorage محدث عند كل تغيير لاحق (الـ effect أعلاه يكفي)

    // useMemo to avoid recompute each render (perf)
    const totalItems = useMemo(() => cartItems.reduce((acc, item) => acc + (Number(item.quantity) || 0), 0), [cartItems]);
    const subtotal = useMemo(() => cartItems.reduce((acc, item) => acc + (Number(item.price) || 0) * (Number(item.quantity) || 0), 0), [cartItems]);

    // ── Coupon computed values ──
    const discountAmount = useMemo(() => (coupon ? calculateDiscount(subtotal, coupon) : 0), [coupon, subtotal]);
    const totalAmount = useMemo(() => Math.max(0, subtotal - discountAmount), [subtotal, discountAmount]);
    // Free shipping threshold (configurable)
    const FREE_SHIPPING_THRESHOLD = 500;
    const shippingProgress = useMemo(() => {
        if (subtotal >= FREE_SHIPPING_THRESHOLD) return 100;
        return Math.min(100, Math.round((subtotal / FREE_SHIPPING_THRESHOLD) * 100));
    }, [subtotal]);
    const freeShippingRemaining = useMemo(() => Math.max(0, FREE_SHIPPING_THRESHOLD - subtotal), [subtotal]);

    const addToCart = useCallback((product, quantity = 1, options = null) => {
        if (!product || !product.id) {
            console.error('addToCart: product missing id', product);
            return;
        }
        const available = product.stock_quantity;
        if (available != null && quantity > available) {
            console.warn(`Requested quantity ${quantity} exceeds stock ${available}`);
        }
        const key = makeKey(product.id, options);
        removeDeletedKey(key);
        try { localStorage.removeItem(CART_CLEARED_KEY); } catch {}
        setCartItems(prev => {
            const existingIndex = prev.findIndex(item => item.id === product.id && canonicalStringify(item.options) === canonicalStringify(options));
            if (existingIndex > -1) {
                const newItems = [...prev];
                const current = newItems[existingIndex];
                let newQty = (Number(current.quantity) || 0) + (Number(quantity) || 1);
                if (available != null && newQty > available) newQty = available;
                if (current.stock_quantity != null && newQty > current.stock_quantity) newQty = current.stock_quantity;
                newItems[existingIndex] = { ...current, quantity: newQty };
                return newItems;
            } else {
                const resolvedPrice = getDiscountedPrice(product);
                const resolvedImage = getProductImage(product);
                const qtyCapped = available != null ? Math.min(Number(quantity) || 1, available) : (Number(quantity) || 1);
                return [...prev, {
                    id: product.id,
                    name: product.name || product.name_ar || 'منتج',
                    price: resolvedPrice,
                    image_url: resolvedImage,
                    image: resolvedImage,
                    quantity: qtyCapped,
                    options: options || {},
                    slug: product.slug,
                    stock_quantity: product.stock_quantity
                }];
            }
        });
        setIsCartOpen(true);
    }, []);

    const removeFromCart = useCallback((productId, options = null) => {
        const key = makeKey(productId, options);
        addDeletedKey(key);
        setCartItems(prev => prev.filter(item => !(item.id === productId && canonicalStringify(item.options) === canonicalStringify(options))));
    }, []);

    const updateQuantity = useCallback((productId, amount, options = null) => {
        setCartItems(prev => {
            return prev.map(item => {
                if (item.id === productId && canonicalStringify(item.options) === canonicalStringify(options)) {
                    let newQuantity = (Number(item.quantity) || 0) + Number(amount);
                    if (newQuantity < 1) newQuantity = 1;
                    if (item.stock_quantity != null && newQuantity > item.stock_quantity) newQuantity = item.stock_quantity;
                    return { ...item, quantity: newQuantity };
                }
                return item;
            });
        });
    }, []);

    const setQuantity = useCallback((productId, quantity, options = null) => {
        const q = Math.max(1, Number(quantity) || 1);
        setCartItems(prev => prev.map(item => {
            if (item.id === productId && canonicalStringify(item.options) === canonicalStringify(options)) {
                const capped = item.stock_quantity != null ? Math.min(q, item.stock_quantity) : q;
                return { ...item, quantity: capped };
            }
            return item;
        }));
    }, []);

    const clearCart = useCallback(() => {
        try {
            localStorage.setItem(CART_CLEARED_KEY, '1');
            localStorage.removeItem(CART_DELETED_KEY);
        } catch {}
        setCartItems([]);
    }, []);

    const openCart = useCallback(() => setIsCartOpen(true), []);
    const closeCart = useCallback(() => setIsCartOpen(false), []);

    // ── Coupon Actions ──
    const applyCoupon = useCallback(async (code) => {
        const raw = (code ?? couponCode).trim();
        if (!raw) { setCouponError('أدخل كود الكوبون'); return { valid: false, error: 'أدخل كود الكوبون' }; }
        if (coupon) { setCouponError('تم تطبيق كوبون بالفعل، احذفه أولاً'); return { valid: false, error: 'تم تطبيق كوبون بالفعل' }; }
        setCouponLoading(true);
        setCouponError('');
        const res = await validateCoupon(raw);
        if (res.valid) {
            setCoupon(res.coupon);
            setCouponCode(raw.toUpperCase());
            setCouponError('');
        } else {
            setCoupon(null);
            setCouponError(res.error);
        }
        setCouponLoading(false);
        return res;
    }, [coupon, couponCode]);

    const removeCoupon = useCallback(() => {
        setCoupon(null);
        setCouponCode('');
        setCouponError('');
    }, []);

    // Clear coupon when cart becomes empty
    useEffect(() => {
        if (cartItems.length === 0 && coupon) {
            setCoupon(null);
            setCouponCode('');
            setCouponError('');
        }
    }, [cartItems.length, coupon]);

    // Re-validate coupon when subtotal changes to ensure discount cap stays correct (no net needed, computed)
    // Keep couponCode in sync for Checkout prefill

    // cross-tab sync (storage event) - S-02 enhancement, keep local cart consistent across tabs
    useEffect(() => {
        const onStorage = (e) => {
            if (e.key === CART_STORAGE_KEY && e.newValue) {
                try {
                    const parsed = JSON.parse(e.newValue);
                    if (Array.isArray(parsed)) setCartItems(parsed.filter(i => i && i.id && typeof i.quantity === 'number'));
                } catch {}
            }
            if (e.key === CART_CLEARED_KEY && e.newValue === '1') {
                setCartItems([]);
            }
        };
        window.addEventListener('storage', onStorage);
        return () => window.removeEventListener('storage', onStorage);
    }, []);

    // تنظيف timeout عند إلغاء المكون
    useEffect(() => () => { if (syncTimeoutRef.current) clearTimeout(syncTimeoutRef.current); }, []);

    return (
        <CartContext.Provider
            value={{
                cartItems,
                totalItems,
                subtotal,
                discountAmount,
                totalAmount,
                FREE_SHIPPING_THRESHOLD,
                shippingProgress,
                freeShippingRemaining,
                isCartOpen,
                isSyncing,
                isHydrated,
                addToCart,
                removeFromCart,
                updateQuantity,
                setQuantity,
                clearCart,
                openCart,
                closeCart,
                // coupon
                coupon,
                couponCode,
                setCouponCode,
                couponError,
                setCouponError,
                couponLoading,
                applyCoupon,
                removeCoupon,
                setCoupon,
            }}
        >
            {children}
        </CartContext.Provider>
    );
};

export const useCart = () => {
    const context = useContext(CartContext);
    if (!context) throw new Error('useCart must be used within a CartProvider');
    return context;
};
