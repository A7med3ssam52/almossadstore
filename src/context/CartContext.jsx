import React, { createContext, useContext, useState, useEffect, useCallback, useRef } from 'react';
import { supabase } from '../supabaseClient';
import { getDiscountedPrice, getProductImage } from '@/utils/formatters';

const CartContext = createContext();

const CART_DELETED_KEY = 'mosad_cart_deleted';
const CART_CLEARED_KEY = 'mosad_cart_cleared';

const makeKey = (id, options) => `${id}-${JSON.stringify(options || {})}`;

const getDeletedSet = () => {
    try {
        const raw = localStorage.getItem(CART_DELETED_KEY);
        return new Set(raw ? JSON.parse(raw) : []);
    } catch {
        return new Set();
    }
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
            const localData = localStorage.getItem('mosad_cart');
            return localData ? JSON.parse(localData) : [];
        } catch (error) {
            console.error('Failed to parse cart data from localStorage:', error);
            return [];
        }
    });

    const [isCartOpen, setIsCartOpen] = useState(false);
    const [isSyncing, setIsSyncing] = useState(false);
    const [user, setUser] = useState(null);
    const syncTimeoutRef = useRef(null);

    useEffect(() => {
        const getSession = async () => {
            const { data: { session } } = await supabase.auth.getSession();
            setUser(session?.user || null);
        };
        getSession();
        const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
            setUser(session?.user || null);
        });
        return () => subscription.unsubscribe();
    }, []);

    useEffect(() => {
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
                            stock_quantity,
                            images,
                            image_url
                        )
                    `)
                    .eq('user_id', user.id);
                if (error) throw error;

                // Check if cart was cleared locally while logged out
                const wasCleared = (() => {
                    try { return localStorage.getItem(CART_CLEARED_KEY) === '1'; } catch { return false; }
                })();
                const deletedSet = getDeletedSet();

                setCartItems(prevLocal => {
                    // If local was cleared while logged out, remote orphans should not reappear
                    // Best effort: if prevLocal is empty and wasCleared, return empty and let syncToSupabase delete remote
                    if (prevLocal.length === 0 && wasCleared) {
                        return [];
                    }

                    const mergedMap = new Map();
                    if (remoteItems) {
                        remoteItems.forEach(item => {
                            const product = item.products;
                            const key = `${item.product_id}-${JSON.stringify(item.options || {})}`;
                            // Skip remote items that were deleted locally (orphans)
                            if (deletedSet.has(key)) return;
                            const remotePrice = getDiscountedPrice(product);
                            const resolvedImage = getProductImage(product);
                            mergedMap.set(key, {
                                id: item.product_id,
                                name: product?.name || product?.name_ar || 'منتج',
                                price: remotePrice,
                                image_url: resolvedImage,
                                image: resolvedImage,
                                quantity: item.quantity,
                                options: item.options || {},
                                stock_quantity: product?.stock_quantity
                            });
                        });
                    }
                    prevLocal.forEach(localItem => {
                        const key = `${localItem.id}-${JSON.stringify(localItem.options || {})}`;
                        if (mergedMap.has(key)) {
                            mergedMap.get(key).quantity += localItem.quantity;
                        } else {
                            mergedMap.set(key, localItem);
                        }
                    });
                    return Array.from(mergedMap.values());
                });

                // After merge, if wasCleared and local was empty, ensure remote is cleared via direct delete (handled also by syncToSupabase)
                if (wasCleared) {
                    const localRaw = (() => { try { return JSON.parse(localStorage.getItem('mosad_cart')||'[]'); } catch { return []; } })();
                    if (Array.isArray(localRaw) && localRaw.length === 0) {
                        await supabase.from('cart_items').delete().eq('user_id', user.id);
                        try { localStorage.removeItem(CART_CLEARED_KEY); localStorage.removeItem(CART_DELETED_KEY); } catch {}
                    }
                }
            } catch (error) {
                console.error("CartContext Sync failure:", error.message);
            } finally {
                setIsSyncing(false);
            }
        };
        syncOnLogin();
    }, [user]);

    const syncToSupabase = useCallback(async (items) => {
        if (!user) return;
        if (syncTimeoutRef.current) clearTimeout(syncTimeoutRef.current);
        syncTimeoutRef.current = setTimeout(async () => {
            try {
                if (items.length === 0) {
                    // remove all remote items when cart cleared
                    const { error: delErr } = await supabase.from('cart_items').delete().eq('user_id', user.id);
                    if (delErr) console.error('Error clearing remote cart:', delErr);
                    try { localStorage.removeItem(CART_CLEARED_KEY); localStorage.removeItem(CART_DELETED_KEY); } catch {}
                    return;
                }
                const syncPayload = items.map(item => ({
                    user_id: user.id,
                    product_id: item.id,
                    quantity: item.quantity,
                    options: item.options || {}
                }));
                const { error: syncError } = await supabase
                    .from('cart_items')
                    .upsert(syncPayload, { onConflict: 'user_id, product_id, options' });
                if (syncError) {
                    console.error('Error syncing cart:', syncError);
                    return;
                }
                // cleanup: remove remote items not in local (orphans)
                try {
                    const { data: currentRemote, error: fetchErr } = await supabase
                        .from('cart_items')
                        .select('id, product_id, options')
                        .eq('user_id', user.id);
                    if (fetchErr) throw fetchErr;
                    if (currentRemote && currentRemote.length > 0) {
                        const localKeys = new Set(items.map(i => makeKey(i.id, i.options)));
                        const orphans = currentRemote.filter(r => !localKeys.has(makeKey(r.product_id, r.options)));
                        if (orphans.length > 0) {
                            const orphanIds = orphans.map(r => r.id);
                            const { error: delOrphanErr } = await supabase.from('cart_items').delete().in('id', orphanIds);
                            if (delOrphanErr) console.error('orphan cleanup failed', delOrphanErr);
                        }
                        // Clean deleted set entries that are no longer orphan (now synced or removed)
                        try {
                            const deletedSet = getDeletedSet();
                            let changed = false;
                            // Remove keys that are now present locally (re-added) or that were orphan and now deleted
                            const orphanKeys = new Set(orphans.map(r => makeKey(r.product_id, r.options)));
                            for (const k of [...deletedSet]) {
                                if (localKeys.has(k) || orphanKeys.has(k)) {
                                    // If orphan was deleted, we can forget it; if re-added locally, forget tombstone
                                    // For orphan case, we already deleted remote, so clear tombstone
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
                console.error('syncToSupabase unexpected error', e);
            }
        }, 300);
    }, [user]);

    useEffect(() => {
        try {
            localStorage.setItem('mosad_cart', JSON.stringify(cartItems));
            syncToSupabase(cartItems);
        } catch (error) {
            console.error('Failed to save cart:', error);
        }
    }, [cartItems, syncToSupabase]);

    const totalItems = cartItems.reduce((acc, item) => acc + item.quantity, 0);
    const subtotal = cartItems.reduce((acc, item) => acc + (Number(item.price) * item.quantity), 0);

    const addToCart = useCallback((product, quantity = 1, options = null) => {
        const available = product.stock_quantity;
        if (available !== undefined && available !== null && quantity > available) {
            console.warn(`Requested quantity ${quantity} exceeds stock ${available}`);
        }
        const key = makeKey(product.id, options);
        // If re-adding a previously deleted item, clear its tombstone
        removeDeletedKey(key);
        try { localStorage.removeItem(CART_CLEARED_KEY); } catch {}
        setCartItems(prev => {
            const existingItemIndex = prev.findIndex(item => item.id === product.id && JSON.stringify(item.options) === JSON.stringify(options));
            if (existingItemIndex > -1) {
                const newItems = [...prev];
                const newQty = newItems[existingItemIndex].quantity + quantity;
                if (available !== undefined && newQty > available) {
                    newItems[existingItemIndex].quantity = available;
                } else {
                    newItems[existingItemIndex].quantity = newQty;
                }
                return newItems;
            } else {
                const resolvedPrice = getDiscountedPrice(product);
                const resolvedImage = getProductImage(product);
                return [...prev, {
                    id: product.id,
                    name: product.name,
                    price: resolvedPrice,
                    image_url: resolvedImage,
                    image: resolvedImage,
                    quantity: Math.min(quantity, available||quantity),
                    options,
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
        setCartItems(prev => prev.filter(item => !(item.id === productId && JSON.stringify(item.options) === JSON.stringify(options))));
    }, []);

    const updateQuantity = useCallback((productId, amount, options = null) => {
        setCartItems(prev => {
            return prev.map(item => {
                if (item.id === productId && JSON.stringify(item.options) === JSON.stringify(options)) {
                    let newQuantity = item.quantity + amount;
                    if (newQuantity < 1) newQuantity = 1;
                    if (item.stock_quantity !== undefined && newQuantity > item.stock_quantity) newQuantity = item.stock_quantity;
                    return { ...item, quantity: newQuantity };
                }
                return item;
            });
        });
    }, []);

    const clearCart = useCallback(() => {
        try {
            localStorage.setItem(CART_CLEARED_KEY, '1');
            localStorage.removeItem(CART_DELETED_KEY);
        } catch {}
        setCartItems([]);
    }, []);

    const openCart = () => setIsCartOpen(true);
    const closeCart = () => setIsCartOpen(false);

    return (
        <CartContext.Provider 
            value={{ 
                cartItems, 
                totalItems, 
                subtotal, 
                isCartOpen,
                addToCart, 
                removeFromCart, 
                updateQuantity, 
                clearCart,
                openCart,
                closeCart
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
