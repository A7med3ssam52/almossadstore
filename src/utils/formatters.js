/**
 * Utility formatters for Al Mossad Store
 * Handles Arabic currency formatting and other presentation helpers.
 */

/**
 * Format a number as Arabic currency (SAR / Egyptian Pound)
 * @param {number|string} amount - The numeric value
 * @param {string} currency - 'SAR' (ر.س) or 'EGP' (ج.م), defaults to 'EGP'
 * @returns {string} - Formatted string e.g. "١٨٥٫٠٠ ج.م"
 */
export const formatPrice = (amount, currency = 'EGP') => {
    const num = Number(amount);
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
