/**
 * Utility formatters for Al Mossad Store
 * Handles Arabic currency formatting and other presentation helpers.
 * Unified pricing logic: base_price + discount% → sale_price → price fallback
 */

/**
 * Get the effective discounted price for a product.
 * Priority: sale_price (explicit) > base_price with discount% > legacy price
 * Discount is clamped to 0-100 and safely parsed.
 * @param {object|null} product
 * @returns {number}
 */
export const getDiscountedPrice = (product) => {
    if (!product || typeof product !== 'object') return 0;

    // 1. Explicit sale_price has highest priority
    if (product.sale_price != null && product.sale_price !== '') {
        const sp = Number(product.sale_price);
        if (!isNaN(sp)) return sp;
    }

    // 2. base_price with discount%
    if (product.base_price != null && product.base_price !== '') {
        const base = Number(product.base_price);
        if (!isNaN(base)) {
            const rawDiscount = Number(product.discount);
            const discount = isNaN(rawDiscount) ? 0 : Math.min(100, Math.max(0, rawDiscount));
            if (discount > 0) return base * (1 - discount / 100);
            return base;
        }
    }

    // 3. Legacy price fallback
    if (product.price != null && product.price !== '') {
        const p = Number(product.price);
        if (!isNaN(p)) return p;
    }

    return 0;
};

/**
 * Get the original (non-discounted) price for display as strikethrough.
 * Prefers base_price, then price, then sale_price.
 * @param {object|null} product
 * @returns {number}
 */
export const getOriginalPrice = (product) => {
    if (!product || typeof product !== 'object') return 0;

    if (product.base_price != null && product.base_price !== '') {
        const base = Number(product.base_price);
        if (!isNaN(base) && base > 0) return base;
    }

    if (product.price != null && product.price !== '') {
        const p = Number(product.price);
        if (!isNaN(p) && p > 0) return p;
    }

    if (product.sale_price != null && product.sale_price !== '') {
        const sp = Number(product.sale_price);
        if (!isNaN(sp)) return sp;
    }

    return getDiscountedPrice(product);
};

/**
 * Determine whether a product has an active discount.
 * @param {object|null} product
 * @returns {boolean}
 */
export const hasDiscount = (product) => {
    if (!product || typeof product !== 'object') return false;

    const discounted = getDiscountedPrice(product);
    const original = getOriginalPrice(product);

    if (original > 0 && discounted < original) return true;

    const discountVal = Number(product.discount);
    if (!isNaN(discountVal) && discountVal > 0 && discountVal <= 100) {
        // Ensure base_price exists to apply discount
        if (product.base_price != null && product.base_price !== '') {
            const base = Number(product.base_price);
            if (!isNaN(base) && base > 0) return true;
        }
    }

    return false;
};

/**
 * Resolve product image with consistent fallback: image_url || images[0] || image
 * @param {object|null} product
 * @returns {string|null}
 */
export const getProductImage = (product) => {
    if (!product || typeof product !== 'object') return null;
    return product.image_url || product.images?.[0] || product.image || null;
};

/**
 * Format a number as Arabic currency (SAR / Egyptian Pound)
 * Also accepts a product object — will compute discounted price automatically.
 * @param {number|string|object} amount - The numeric value or product object
 * @param {string} currency - 'SAR' (ر.س) or 'EGP' (ج.م), defaults to 'EGP'
 * @returns {string} - Formatted string e.g. "١٨٥٫٠٠ ج.م"
 */
export const formatPrice = (amount, currency = 'EGP') => {
    let num;
    if (amount && typeof amount === 'object' && ('base_price' in amount || 'price' in amount || 'sale_price' in amount)) {
        num = getDiscountedPrice(amount);
    } else {
        num = Number(amount);
    }
    if (isNaN(num)) return '—';

    const symbols = {
        SAR: 'ر.س',
        EGP: 'ج.م',
    };

    const formatted = num.toLocaleString('ar-EG', {
        minimumFractionDigits: 0,
        maximumFractionDigits: 2,
    });

    return `${formatted} ${symbols[currency] || currency}`;
};

/**
 * Format a number as a plain localized Arabic number string
 * @param {number|string} amount 
 * @returns {string}
 */
export const formatNumber = (amount) => {
    const num = Number(amount);
    if (isNaN(num)) return '—';
    return num.toLocaleString('ar-EG');
};

/**
 * Truncate a string to a max length, adding ellipsis
 * @param {string} str 
 * @param {number} maxLen 
 * @returns {string}
 */
export const truncate = (str, maxLen = 60) => {
    if (!str) return '';
    return str.length > maxLen ? str.slice(0, maxLen) + '...' : str;
};
