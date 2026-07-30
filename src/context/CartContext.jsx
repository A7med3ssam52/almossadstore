import React, { createContext, useContext, useState, useEffect, useCallback, useRef } from 'react';
import { supabase } from '../supabaseClient';

const CartContext = createContext();

export const CartProvider = ({ children }) => {
    // Initialize state from localStorage, or empty array if none exists
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

    // Initial auth check and listener
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

    // Merge & Fetch Logic when user changes
    useEffect(() => {
        const syncOnLogin = async () => {
            if (!user) return;
            setIsSyncing(true);
            try {
                // 1. Fetch remote items with product details
                const { data: remoteItems, error } = await supabase
                    .from('cart_items')
                    .select(`
                        id, 
                        product_id, 
                        quantity, 
                        options,
                        products (
                            name_ar,
                            price,
                            image_url
                        )
                    `)
                    .eq('user_id', user.id);

                if (error) {
                    console.error("❌ CartContext [Sync]: Error fetching synced cart:", error);
                    throw error;
                }

                setCartItems(prevLocal => {
                    const mergedMap = new Map();
                    
                    // Add remote items
                    if (remoteItems) {
                        remoteItems.forEach(item => {
                            const product = item.products;
                            const key = `${item.product_id}-${JSON.stringify(item.options)}`;
                            mergedMap.set(key, {
                                id: item.product_id,
                                name: product?.name_ar || 'منتج غير متوفر',
                                price: product?.price || 0,
                                image_url: product?.image_url || null,
                                quantity: item.quantity,
                                options: item.options || {}
                            });
                        });
                    }

                    // Merge local items
                    prevLocal.forEach(localItem => {
                        const key = `${localItem.id}-${JSON.stringify(localItem.options)}`;
                        if (mergedMap.has(key)) {
                            mergedMap.get(key).quantity += localItem.quantity;
                        } else {
                            mergedMap.set(key, localItem);
                        }
                    });

                    const finalResult = Array.from(mergedMap.values());
                    console.log("✅ CartContext [Sync]: Merged into", finalResult.length, "items");
                    return finalResult;
                });
            } catch (error) {
                console.error("❌ CartContext [Sync]: Critical failure:", error.message);
            } finally {
                setIsSyncing(false);
            }
        };

        syncOnLogin();
    }, [user]);

    // Push changes to Supabase (Debounced)
    const syncToSupabase = useCallback(async (items) => {
        if (!user) return;

        if (syncTimeoutRef.current) clearTimeout(syncTimeoutRef.current);

        syncTimeoutRef.current = setTimeout(async () => {
            // Upsert items logic
            const syncPayload = items.map(item => ({
                user_id: user.id,
                product_id: item.id,
                quantity: item.quantity,
                options: item.options || {}
            }));

            // Use upsert with onConflict to handle updates and inserts in one go
            // Note: Requires a unique index on (user_id, product_id, options::text)
            const { error: syncError } = await supabase
                .from('cart_items')
                .upsert(syncPayload, { 
                    onConflict: 'user_id, product_id, options' 
                });

            if (syncError) {
                console.error('Error syncing cart to Supabase:', syncError);
            }
        }, 300);
    }, [user]);

    // Save to localStorage AND Sync to Supabase whenever cartItems change
    useEffect(() => {
        try {
            localStorage.setItem('mosad_cart', JSON.stringify(cartItems));
            syncToSupabase(cartItems);
        } catch (error) {
            console.error('Failed to save cart:', error);
        }
    }, [cartItems, syncToSupabase]);

    // Derived state
    const totalItems = cartItems.reduce((acc, item) => acc + item.quantity, 0);
    const subtotal = cartItems.reduce((acc, item) => acc + (item.price * item.quantity), 0);

    // Actions
    const addToCart = useCallback((product, quantity = 1, options = null) => {
        setCartItems(prev => {
            const existingItemIndex = prev.findIndex(item => item.id === product.id && JSON.stringify(item.options) === JSON.stringify(options));
            
            if (existingItemIndex > -1) {
                // Update quantity if already exists
                const newItems = [...prev];
                newItems[existingItemIndex].quantity += quantity;
                return newItems;
            } else {
                // Add new item
                return [...prev, {
                    id: product.id,
                    name: product.name,
                    price: product.sale_price || product.price,
                    image_url: product.image_url,
                    quantity,
                    options,
                    slug: product.slug
                }];
            }
        });
        setIsCartOpen(true); // Open drawer on add
    }, []);

    const removeFromCart = useCallback((productId, options = null) => {
        setCartItems(prev => prev.filter(item => !(item.id === productId && JSON.stringify(item.options) === JSON.stringify(options))));
    }, []);

    const updateQuantity = useCallback((productId, amount, options = null) => {
        setCartItems(prev => {
            return prev.map(item => {
                if (item.id === productId && JSON.stringify(item.options) === JSON.stringify(options)) {
                    const newQuantity = Math.max(1, item.quantity + amount);
                    return { ...item, quantity: newQuantity };
                }
                return item;
            });
        });
    }, []);

    const clearCart = useCallback(() => {
        setCartItems([]);
    }, []);

    const openCart = () => {
        console.log("🔓 CartDrawer: Opening...");
        setIsCartOpen(true);
    };
    const closeCart = () => {
        console.log("🔒 CartDrawer: Closing...");
        setIsCartOpen(false);
    };

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
    if (!context) {
        throw new Error('useCart must be used within a CartProvider');
    }
    return context;
};
