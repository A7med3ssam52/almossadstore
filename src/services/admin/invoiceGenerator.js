/**
 * Invoice PDF Generator using jsPDF
 * T023 — Generates a printable Arabic-styled PDF invoice
 */
export const generateInvoicePDF = async (order, items = []) => {
    // Dynamic import to avoid loading jsPDF unless needed
    const { jsPDF } = await import('jspdf');

    const doc = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' });

    const pageW = doc.internal.pageSize.getWidth();
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
    doc.text('BILL TO', 14, 52);
    doc.setTextColor(50, 50, 50);
    doc.setFont('helvetica', 'normal');
    const customerName = order?.profiles?.full_name || order?.shipping_address?.name || 'Customer';
    const customerCity = order?.shipping_address?.city || '';
    const customerPhone = order?.shipping_address?.phone || '';
    doc.text(customerName, 14, 60);
    if (customerCity) doc.text(customerCity, 14, 66);
    if (customerPhone) doc.text(customerPhone, 14, 72);

    // ── Table header ──
    let y = 88;
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

    let subtotal = 0;
    (items || []).forEach((item, idx) => {
        if (idx % 2 === 0) {
            doc.setFillColor(250, 250, 250);
            doc.rect(14, y - 6, pageW - 28, 10, 'F');
        }
        const lineTotal = (item.price || 0) * (item.qty || 1);
        subtotal += lineTotal;
        // Truncate long names
        const name = item.name?.length > 40 ? item.name.slice(0, 38) + '...' : (item.name || 'Item');
        doc.text(name, 18, y);
        doc.text(String(item.qty || 1), 120, y, { align: 'center' });
        doc.text(`${(item.price || 0).toLocaleString()} EGP`, 150, y, { align: 'center' });
        doc.text(`${lineTotal.toLocaleString()} EGP`, pageW - 18, y, { align: 'right' });
        y += 12;
    });

    // ── Totals ──
    y += 4;
    doc.setDrawColor(220, 220, 220);
    doc.line(pageW - 80, y, pageW - 14, y);
    y += 8;

    doc.setFont('helvetica', 'normal');
    doc.setTextColor(100, 100, 100);
    doc.text('Subtotal:', pageW - 80, y);
    doc.setTextColor(50, 50, 50);
    doc.text(`${subtotal.toLocaleString()} EGP`, pageW - 18, y, { align: 'right' });
    y += 8;

    const tax = subtotal * 0.15;
    doc.setTextColor(100, 100, 100);
    doc.text('VAT (15%):', pageW - 80, y);
    doc.setTextColor(50, 50, 50);
    doc.text(`${tax.toFixed(2)} EGP`, pageW - 18, y, { align: 'right' });
    y += 10;

    // Total row highlight
    doc.setFillColor(31, 41, 51);
    doc.rect(pageW - 82, y - 7, 68, 12, 'F');
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(255, 255, 255);
    doc.text('TOTAL:', pageW - 80, y);
    const total = order?.total_amount ? Number(order.total_amount) : subtotal + tax;
    doc.text(`${total.toLocaleString()} EGP`, pageW - 18, y, { align: 'right' });

    // ── Footer ──
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(8);
    doc.setTextColor(80, 80, 80);
    doc.text('Thank you for your business!', pageW / 2, 280, { align: 'center' });
    doc.text('Al Mossad Store | Egypt', pageW / 2, 286, { align: 'center' });

    doc.save(`invoice-${orderId}.pdf`);
};
