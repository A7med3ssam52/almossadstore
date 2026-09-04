import React, { createContext, useContext, useState, useEffect, useCallback, useRef } from 'react';
import { supabase } from '../supabaseClient';

const CartContext = createContext();

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
                setCartItems(prevLocal => {
                    const mergedMap = new Map();
                    if (remoteItems) {
                        remoteItems.forEach(item => {
                            const product = item.products;
                            const key = `${item.product_id}-${JSON.stringify(item.options)}`;
                            const remotePrice = product?.base_price != null ? (Number(product.base_price) * (1 - (Number(product.discount)||0)/100)) : (Number(product?.price)||0);
                            mergedMap.set(key, {
                                id: item.product_id,
                                name: product?.name || product?.name_ar || 'منتج',
                                price: remotePrice,
                                image_url: product?.image_url || product?.images?.[0] || null,
                                image: product?.image_url || product?.images?.[0] || null,
                                quantity: item.quantity,
                                options: item.options || {},
                                stock_quantity: product?.stock_quantity
                            });
                        });
                    }
                    prevLocal.forEach(localItem => {
                        const key = `${localItem.id}-${JSON.stringify(localItem.options)}`;
                        if (mergedMap.has(key)) {
                            mergedMap.get(key).quantity += localItem.quantity;
                        } else {
                            mergedMap.set(key, localItem);
                        }
                    });
                    return Array.from(mergedMap.values());
                });
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
            if (items.length === 0) {
                // remove all remote items when cart cleared
                await supabase.from('cart_items').delete().eq('user_id', user.id);
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
            if (syncError) console.error('Error syncing cart:', syncError);
            // cleanup: remove remote items not in local
            // (best effort) fetch remote ids and delete orphans
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
        // Check stock before adding
        const available = product.stock_quantity;
        if (available !== undefined && available !== null && quantity > available) {
            console.warn(`Requested quantity ${quantity} exceeds stock ${available}`);
        }
        setCartItems(prev => {
            const existingItemIndex = prev.findIndex(item => item.id === product.id && JSON.stringify(item.options) === JSON.stringify(options));
            if (existingItemIndex > -1) {
                const newItems = [...prev];
                const newQty = newItems[existingItemIndex].quantity + quantity;
                if (available !== undefined && newQty > available) {
                    // cap at available
                    newItems[existingItemIndex].quantity = available;
                } else {
                    newItems[existingItemIndex].quantity = newQty;
                }
                return newItems;
            } else {
                const resolvedPrice = product.sale_price != null ? Number(product.sale_price) : (product.base_price != null ? (Number(product.base_price) * (1 - (Number(product.discount)||0)/100)) : Number(product.price)||0);
                return [...prev, {
                    id: product.id,
                    name: product.name,
                    price: resolvedPrice,
                    image_url: product.image_url || product.images?.[0] || null,
                    image: product.image_url || product.images?.[0] || null,
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