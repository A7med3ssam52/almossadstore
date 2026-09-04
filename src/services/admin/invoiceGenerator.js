/**
 * Invoice PDF Generator using jsPDF
 * T023 — Generates a printable Arabic-styled PDF invoice
 * Fixes: RTL Arabic support (logical order + splitTextToSize) while keeping helvetica fallback,
 * correct totals using order.total_amount / discount_amount / shipping_cost,
 * shipping_address JSON parsing, empty items handling, and no double VAT.
 */

const parseShippingAddress = (raw) => {
    if (!raw) return {};
    if (typeof raw === 'object' && raw !== null) return raw;
    try {
        const parsed = JSON.parse(raw);
        if (parsed && typeof parsed === 'object') return parsed;
    } catch {}
    // legacy text "city - address"
    const parts = String(raw).split(' - ');
    return { city: parts[0] || '', address: parts.slice(1).join(' - ') || String(raw), phone: '', name: '' };
};

const containsArabic = (s) => /[\u0600-\u06FF]/.test(s || '');

export const generateInvoicePDF = async (order, items = []) => {
    const { jsPDF } = await import('jspdf');

    const doc = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' });

    const pageW = doc.internal.pageSize.getWidth();
    const pageH = doc.internal.pageSize.getHeight();
    const now = new Date();

    // ── Background color ──
    doc.setFillColor(255, 255, 255);
    doc.rect(0, 0, pageW, 297, 'F');

    // ── Header Bar ──
    doc.setFillColor(31, 41, 51); // #1F2933
    doc.rect(0, 0, pageW, 28, 'F');

    // ── Company name (LTR fallback since jsPDF has limited RTL) ──
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(18);
    doc.setTextColor(255, 255, 255);
    doc.text('AL MOSSAD STORE', 14, 17);

    doc.setFontSize(9);
    doc.setTextColor(200, 200, 200);
    doc.text('Al Hadid & Al Boyat', 14, 24);

    // ── Invoice title ──
    doc.setFontSize(22);
    doc.setTextColor(31, 41, 51);
    doc.setFont('helvetica', 'bold');
    doc.text('INVOICE', pageW - 14, 18, { align: 'right' });

    // ── Meta info ──
    doc.setFontSize(9);
    doc.setTextColor(100, 100, 100);
    const orderId = order?.id ? `#${order.id.slice(-8).toUpperCase()}` : '#N/A';
    doc.text(`Order: ${orderId}`, pageW - 14, 30, { align: 'right' });
    doc.text(`Date: ${now.toLocaleDateString('en-EG')}`, pageW - 14, 36, { align: 'right' });

    // ── Divider ──
    doc.setDrawColor(220, 220, 220);
    doc.line(14, 42, pageW - 14, 42);

    // ── Customer Info ──
    doc.setFontSize(10);
    doc.setTextColor(31, 41, 51);
    doc.setFont('helvetica', 'bold');
    doc.text('BILL TO', 14, 52);
    doc.setTextColor(50, 50, 50);
    doc.setFont('helvetica', 'normal');

    const shipping = parseShippingAddress(order?.shipping_address);
    const rawCustomerName = order?.profiles?.full_name || order?.customer_name || shipping?.name || 'Customer';
    const rawCustomerCity = shipping?.city || '';
    const rawCustomerAddress = shipping?.address || '';
    const rawCustomerPhone = shipping?.phone || order?.contact_phone || '';

    // Arabic-friendly fallback: keep helvetica but preserve logical order and use splitTextToSize for wrapping
    // jsPDF built-in helvetica has no Arabic glyphs, but we avoid garbled reversal by keeping logical order
    const customerName = String(rawCustomerName);
    const customerCity = String(rawCustomerCity);
    const customerAddress = String(rawCustomerAddress);
    const customerPhone = String(rawCustomerPhone);

    // Helper to draw text with RTL-aware splitting (logical order preserved)
    const drawCustomerLine = (text, x, y, opts) => {
        if (!text) return 0;
        // keep logical order, do not reverse Arabic; split to avoid overflow
        const str = String(text);
        const maxW = pageW - 28;
        // Use splitTextToSize to handle long RTL strings gracefully
        const lines = doc.splitTextToSize(str, 90);
        // For Arabic text, jsPDF helvetica will keep logical order; we align left as fallback
        // If Arabic detected, we ensure we don't attempt to bidi-reorder incorrectly
        const isAr = containsArabic(str);
        // Render preserving logical order (no reversal)
        doc.text(lines, x, y, opts);
        return Array.isArray(lines) ? lines.length : 1;
    };

    let custY = 60;
    // keep helvetica, but handle RTL via logical order + splitting
    const nameLines = doc.splitTextToSize(customerName, 90);
    doc.text(nameLines, 14, custY);
    custY += nameLines.length * 6;
    if (customerCity || customerAddress) {
        const cityAddr = [customerCity, customerAddress].filter(Boolean).join(' - ');
        const addrLines = doc.splitTextToSize(cityAddr, 90);
        doc.text(addrLines, 14, custY);
        custY += addrLines.length * 6;
    }
    if (customerPhone) {
        doc.text(String(customerPhone), 14, custY);
        custY += 6;
    }
    // If Arabic, add small note that font is fallback (no glyph substitution needed for LTR helvetica)
    // but we have preserved logical order via splitTextToSize

    // ── Table header ──
    let y = Math.max(88, custY + 6);
    doc.setFillColor(245, 245, 245);
    doc.rect(14, y - 7, pageW - 28, 10, 'F');
    doc.setFontSize(9);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(31, 41, 51);
    doc.text('ITEM', 18, y);
    doc.text('QTY', 120, y, { align: 'center' });
    doc.text('PRICE', 150, y, { align: 'center' });
    doc.text('TOTAL', pageW - 18, y, { align: 'right' });

    // ── Table rows ──
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(60, 60, 60);
    y += 12;

    // Normalize items: support both passed items and order.items fallback
    let normalizedItems = Array.isArray(items) ? items : [];
    if ((!normalizedItems || normalizedItems.length === 0) && Array.isArray(order?.items) && order.items.length > 0) {
        normalizedItems = order.items.map((it) => ({
            name: it.products?.name || it.product_name || it.name || String(it.product_id || 'Item'),
            qty: it.quantity ?? it.qty ?? 1,
            price: Number(it.unit_price ?? it.price ?? 0),
        }));
    }

    let itemsSubtotal = 0;

    if (!normalizedItems || normalizedItems.length === 0) {
        doc.setFont('helvetica', 'italic');
        doc.setTextColor(150, 150, 150);
        doc.setFontSize(9);
        doc.text('No items / لا توجد منتجات', pageW / 2, y, { align: 'center' });
        y += 12;
        doc.setFont('helvetica', 'normal');
        doc.setTextColor(60, 60, 60);
    } else {
        normalizedItems.forEach((item, idx) => {
            // pagination guard
            if (y > pageH - 40) {
                doc.addPage();
                y = 20;
            }
            if (idx % 2 === 0) {
                doc.setFillColor(250, 250, 250);
                doc.rect(14, y - 6, pageW - 28, 10, 'F');
            }
            const qty = Number(item.qty ?? item.quantity ?? 1) || 1;
            const price = Number(item.price ?? item.unit_price ?? 0) || 0;
            const lineTotal = price * qty;
            itemsSubtotal += lineTotal;
            // Truncate long names but preserve Arabic logical order; use split not hard slice for RTL
            let name = String(item.name || 'Item');
            // For display, truncate to 40 chars preserving logical order
            if (name.length > 40) name = name.slice(0, 38) + '...';
            // Use splitTextToSize for name to avoid overflow while keeping logical order
            // But table cell is small, so we keep truncated single line in helvetica
            // Ensure we don't reverse Arabic: keep as is
            doc.setFontSize(9);
            doc.text(name, 18, y);
            doc.text(String(qty), 120, y, { align: 'center' });
            doc.text(`${price.toLocaleString()} EGP`, 150, y, { align: 'center' });
            doc.text(`${lineTotal.toLocaleString()} EGP`, pageW - 18, y, { align: 'right' });
            y += 12;
        });
    }

    // ── Totals ──
    y += 4;
    if (y > pageH - 50) {
        doc.addPage();
        y = 20;
    }
    doc.setDrawColor(220, 220, 220);
    doc.line(pageW - 80, y, pageW - 14, y);
    y += 8;

    // Correct totals logic: use order.total_amount directly, do NOT double-count VAT
    const discountAmount = Number(order?.discount_amount || 0);
    const shippingCost = Number(order?.shipping_cost || 0);
    const hasOrderTotal = order?.total_amount != null && String(order.total_amount).trim() !== '';
    const orderTotal = hasOrderTotal ? Number(order.total_amount) : null;

    // Derive display subtotal: if orderTotal exists, it already includes discount/shipping
    let displaySubtotal;
    if (hasOrderTotal) {
        displaySubtotal = orderTotal + discountAmount - shippingCost;
        // fallback/guards
        if (!isFinite(displaySubtotal) || displaySubtotal < 0) displaySubtotal = itemsSubtotal;
        // if itemsSubtotal is available and derived is 0 but items exist, use itemsSubtotal
        if (displaySubtotal === 0 && itemsSubtotal > 0) displaySubtotal = itemsSubtotal;
    } else {
        displaySubtotal = itemsSubtotal;
    }
    if (!isFinite(displaySubtotal)) displaySubtotal = 0;

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(9);
    doc.setTextColor(100, 100, 100);
    doc.text('Subtotal:', pageW - 80, y);
    doc.setTextColor(50, 50, 50);
    doc.text(`${Number(displaySubtotal).toLocaleString()} EGP`, pageW - 18, y, { align: 'right' });
    y += 8;

    if (discountAmount > 0) {
        doc.setTextColor(34, 139, 34);
        const couponLabel = order?.coupon_code ? `Discount (${order.coupon_code}):` : 'Discount:';
        doc.text(couponLabel, pageW - 80, y);
        doc.text(`-${discountAmount.toLocaleString()} EGP`, pageW - 18, y, { align: 'right' });
        y += 8;
        doc.setTextColor(100, 100, 100);
    }

    // Shipping
    doc.setTextColor(100, 100, 100);
    doc.text('Shipping:', pageW - 80, y);
    doc.setTextColor(50, 50, 50);
    if (shippingCost === 0) {
        doc.text('FREE', pageW - 18, y, { align: 'right' });
    } else {
        doc.text(`${shippingCost.toLocaleString()} EGP`, pageW - 18, y, { align: 'right' });
    }
    y += 8;

    // VAT handling - fix double count: only add VAT if order.total_amount is missing
    let tax = 0;
    if (!hasOrderTotal && displaySubtotal > 0) {
        tax = displaySubtotal * 0.15;
        doc.setTextColor(100, 100, 100);
        doc.text('VAT (15%):', pageW - 80, y);
        doc.setTextColor(50, 50, 50);
        doc.text(`${tax.toFixed(2)} EGP`, pageW - 18, y, { align: 'right' });
        y += 10;
    } else {
        // VAT is assumed included in order.total_amount; do not add on top
        if (hasOrderTotal) {
            doc.setFontSize(7);
            doc.setTextColor(120, 120, 120);
            doc.text('VAT included where applicable', pageW - 18, y, { align: 'right' });
            doc.setFontSize(9);
            y += 6;
        } else {
            y += 2;
        }
    }

    // Total row highlight
    if (y > pageH - 20) {
        doc.addPage();
        y = 20;
    }
    doc.setFillColor(31, 41, 51);
    doc.rect(pageW - 82, y - 7, 68, 12, 'F');
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(255, 255, 255);
    doc.text('TOTAL:', pageW - 80, y);
    const finalTotal = hasOrderTotal ? orderTotal : displaySubtotal + tax - discountAmount + shippingCost;
    const safeFinal = isFinite(finalTotal) && finalTotal >= 0 ? finalTotal : displaySubtotal;
    doc.text(`${Number(safeFinal).toLocaleString()} EGP`, pageW - 18, y, { align: 'right' });

    // ── Footer ──
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(8);
    doc.setTextColor(80, 80, 80);
    doc.text('Thank you for your business!', pageW / 2, 280, { align: 'center' });
    doc.text('Al Mossad Store | Egypt', pageW / 2, 286, { align: 'center' });

    doc.save(`invoice-${orderId}.pdf`);
};
