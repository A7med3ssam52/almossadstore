/**
 * Al Mossad Store - Professional Arabic Invoice Generator
 * Premium design with Cairo font, RTL support, html2canvas + jsPDF
 * Features: براندد آل مسعد، خط Cairo، تصميم احترافي جداً، جاهز للطباعة
 */

const parseShippingAddress = (raw) => {
    if (!raw) return {};
    if (typeof raw === 'object' && raw !== null) return raw;
    try {
        const parsed = JSON.parse(raw);
        if (parsed && typeof parsed === 'object') return parsed;
    } catch {}
    const parts = String(raw).split(' - ');
    return { city: parts[0] || '', address: parts.slice(1).join(' - ') || String(raw), phone: '', name: '' };
};

const formatDateAr = (iso) => {
    try {
        const d = iso ? new Date(iso) : new Date();
        return d.toLocaleDateString('ar-EG', { year: 'numeric', month: 'long', day: 'numeric' });
    } catch { return new Date().toLocaleDateString('ar-EG'); }
};

const formatCurrency = (n) => `${Number(n || 0).toLocaleString('ar-EG')} ج.م`;

export const generateInvoicePDF = async (order, items = []) => {
    // Normalize items
    let normalizedItems = Array.isArray(items) ? items : [];
    if ((!normalizedItems || normalizedItems.length === 0) && Array.isArray(order?.items) && order.items.length > 0) {
        normalizedItems = order.items.map((it) => ({
            name: it.products?.name || it.product_name || it.name || String(it.product_id || 'منتج'),
            qty: it.quantity ?? it.qty ?? 1,
            price: Number(it.unit_price ?? it.price ?? 0),
            image: it.products?.images?.[0] || null,
        }));
    }

    const shipping = parseShippingAddress(order?.shipping_address);
    const customerName = order?.profiles?.full_name || order?.customer_name || shipping?.name || 'عميل';
    const customerPhone = shipping?.phone || order?.contact_phone || '—';
    const customerCity = shipping?.city || '—';
    const customerAddress = shipping?.address || shipping?.city || '—';
    const orderIdShort = order?.id ? order.id.slice(-8).toUpperCase() : 'N/A';
    const orderIdFull = order?.id || '—';
    const orderDate = formatDateAr(order?.created_at);
    const createdTime = order?.created_at ? new Date(order.created_at).toLocaleTimeString('ar-EG', { hour: '2-digit', minute: '2-digit' }) : '';

    // Totals logic (same as before, but Arabic display)
    const discountAmount = Number(order?.discount_amount || 0);
    const shippingCost = Number(order?.shipping_cost || 0);
    const hasOrderTotal = order?.total_amount != null && String(order.total_amount).trim() !== '';
    const orderTotal = hasOrderTotal ? Number(order.total_amount) : null;
    let itemsSubtotal = normalizedItems.reduce((acc, it) => acc + Number(it.price || 0) * Number(it.qty || 1), 0);
    let displaySubtotal;
    if (hasOrderTotal) {
        displaySubtotal = orderTotal + discountAmount - shippingCost;
        if (!isFinite(displaySubtotal) || displaySubtotal < 0) displaySubtotal = itemsSubtotal;
        if (displaySubtotal === 0 && itemsSubtotal > 0) displaySubtotal = itemsSubtotal;
    } else {
        displaySubtotal = itemsSubtotal;
    }
    if (!isFinite(displaySubtotal)) displaySubtotal = 0;
    const finalTotal = hasOrderTotal ? orderTotal : displaySubtotal - discountAmount + shippingCost;
    const safeFinal = isFinite(finalTotal) && finalTotal >= 0 ? finalTotal : displaySubtotal;

    const statusMap = {
        pending: { label: 'قيد الانتظار', color: '#f59e0b', bg: '#fef3c7' },
        processing: { label: 'قيد التجهيز', color: '#2563eb', bg: '#dbeafe' },
        completed: { label: 'مكتمل', color: '#059669', bg: '#d1fae5' },
        cancelled: { label: 'ملغي', color: '#dc2626', bg: '#fee2e2' },
    };
    const status = statusMap[order?.status] || statusMap.pending;
    const paymentMap = { paid: 'مدفوع', unpaid: 'غير مدفوع (عند الاستلام)', refunded: 'مسترجع' };
    const paymentLabel = paymentMap[order?.payment_status] || 'عند الاستلام';

    // Build HTML invoice (offscreen)
    const invoiceId = `invoice-${Date.now()}`;
    const container = document.createElement('div');
    container.id = invoiceId;
    container.dir = 'rtl';
    container.style.cssText = `
        position: fixed; left: -9999px; top: 0; width: 794px; background: white;
        font-family: 'Cairo', sans-serif; color: #0f172a; line-height: 1.6;
        -webkit-print-color-adjust: exact; print-color-adjust: exact;
    `;

    // Professional HTML – very premium
    container.innerHTML = `
        <div style="width:794px; background:white; padding:0; box-sizing:border-box; font-family:'Cairo',sans-serif;">
            <!-- Top accent bar -->
            <div style="height:6px; background: linear-gradient(90deg, #ea580c 0%, #f97316 50%, #fb923c 100%);"></div>

            <!-- Header – Branded Al Mossad -->
            <div style="background:#0f172a; color:white; padding:28px 36px 22px; display:flex; justify-content:space-between; align-items:flex-start; position:relative; overflow:hidden;">
                <div style="position:absolute; top:-30px; left:-30px; width:120px; height:120px; background:rgba(234,88,12,0.12); border-radius:50%;"></div>
                <div style="position:absolute; bottom:-20px; right:120px; width:80px; height:80px; background:rgba(255,255,255,0.04); border-radius:50%;"></div>

                <div style="display:flex; gap:16px; align-items:center; position:relative; z-index:1;">
                    <div style="width:56px; height:56px; background:white; color:#0f172a; border-radius:16px; display:flex; align-items:center; justify-content:center; font-weight:900; font-size:18px; letter-spacing:0.5px; box-shadow:0 8px 24px rgba(0,0,0,0.15);">آل</div>
                    <div>
                        <div style="font-weight:900; font-size:22px; line-height:1; letter-spacing:-0.5px;">آل مسعد</div>
                        <div style="font-weight:700; font-size:10px; letter-spacing:0.22em; color:#fdba74; margin-top:4px;">AL MOSSAD STORE</div>
                        <div style="font-weight:600; font-size:10px; color:#94a3b8; margin-top:2px;">لتـجارة الحدايد والبويات والعدد</div>
                    </div>
                </div>

                <div style="text-align:left; position:relative; z-index:1;">
                    <div style="font-weight:900; font-size:28px; letter-spacing:-0.5px; line-height:1;">فاتورة مبيعات</div>
                    <div style="font-weight:700; font-size:11px; letter-spacing:0.15em; color:#fdba74; margin-top:2px;">SALES INVOICE</div>
                    <div style="margin-top:10px; background:rgba(255,255,255,0.08); border:1px solid rgba(255,255,255,0.12); border-radius:12px; padding:8px 14px; backdrop-filter:blur(8px);">
                        <div style="font-size:11px; font-weight:800; color:white; display:flex; align-items:center; gap:8px;">
                            <span style="background:#ea580c; color:white; padding:2px 8px; border-radius:20px; font-size:10px;">رقم الفاتورة</span>
                            <span style="font-family:monospace; letter-spacing:1px;">#${orderIdShort}</span>
                        </div>
                        <div style="font-size:10px; color:#cbd5e1; margin-top:4px; font-weight:600;">${orderDate} • ${createdTime}</div>
                    </div>
                </div>
            </div>

            <!-- Sub-header: status + meta -->
            <div style="background:#fff7ed; border-bottom:1px solid #ffedd5; padding:12px 36px; display:flex; justify-content:space-between; align-items:center;">
                <div style="display:flex; gap:10px; align-items:center;">
                    <span style="font-size:11px; font-weight:800; color:#9a3412; background:white; border:1px solid #fed7aa; padding:6px 12px; border-radius:20px; display:inline-flex; align-items:center; gap:6px;">
                        <span style="width:8px; height:8px; background:${status.color}; border-radius:50%; display:inline-block;"></span>
                        ${status.label}
                    </span>
                    <span style="font-size:11px; font-weight:700; color:#475569; background:white; border:1px solid #e2e8f0; padding:6px 12px; border-radius:20px;">${paymentLabel}</span>
                    ${order?.coupon_code ? `<span style="font-size:11px; font-weight:800; color:#065f46; background:#ecfdf5; border:1px solid #a7f3d0; padding:6px 12px; border-radius:20px; font-family:monospace;">كوبون: ${order.coupon_code}</span>` : ''}
                </div>
                <div style="font-size:10px; font-weight:700; color:#64748b; display:flex; gap:6px; align-items:center;">
                    <span>الدفع:</span><span style="color:#0f172a; font-weight:900;">عند الاستلام (COD)</span>
                </div>
            </div>

            <!-- Customer + Store Info -->
            <div style="padding:22px 36px; display:grid; grid-template-columns:1fr 1fr; gap:20px;">
                <!-- Bill To -->
                <div style="background:#f8fafc; border:1px solid #e2e8f0; border-radius:20px; padding:18px 20px;">
                    <div style="font-size:10px; font-weight:900; letter-spacing:0.14em; color:#64748b; margin-bottom:10px; display:flex; align-items:center; gap:8px;">
                        <span style="width:22px; height:22px; background:#0f172a; color:white; border-radius:8px; display:flex; align-items:center; justify-content:center; font-size:11px;">◉</span>
                        فاتورة إلى / BILL TO
                    </div>
                    <div style="font-weight:900; font-size:15px; color:#0f172a; margin-bottom:6px;">${customerName}</div>
                    <div style="font-size:12px; font-weight:600; color:#334155; display:flex; align-items:center; gap:6px; margin-bottom:4px;">
                        <span style="color:#ea580c;">📍</span> ${customerCity} ${customerAddress && customerAddress !== customerCity ? `— ${customerAddress}` : ''}
                    </div>
                    <div style="font-size:12px; font-weight:700; color:#0f172a; font-family:monospace; background:white; border:1px solid #e2e8f0; border-radius:10px; padding:6px 10px; display:inline-flex; align-items:center; gap:6px; margin-top:6px;">
                        <span style="color:#64748b; font-family:'Cairo',sans-serif; font-size:11px;">📞</span> ${customerPhone}
                    </div>
                    ${order?.notes ? `<div style="margin-top:10px; background:white; border:1px dashed #cbd5e1; border-radius:12px; padding:10px 12px; font-size:11px; color:#475569; font-weight:600;"><span style="font-weight:900; color:#0f172a;">ملاحظات:</span> ${order.notes}</div>` : ''}
                </div>

                <!-- Store Info -->
                <div style="background:white; border:1px solid #e2e8f0; border-radius:20px; padding:18px 20px;">
                    <div style="font-size:10px; font-weight:900; letter-spacing:0.14em; color:#64748b; margin-bottom:10px;">من / FROM — آل مسعد</div>
                    <div style="font-weight:900; font-size:14px; color:#0f172a;">آل مسعد لتجارة الحدايد والبويات</div>
                    <div style="font-size:11px; font-weight:600; color:#475569; margin-top:6px; line-height:1.7;">
                        39 شارع ربيع الجيزي - الجيزة<br/>بجوار مستشفى أم المصريين
                    </div>
                    <div style="margin-top:10px; display:flex; flex-direction:column; gap:4px; font-size:11px; font-weight:700;">
                        <div style="display:flex; align-items:center; gap:8px; color:#0f172a;"><span style="width:20px; height:20px; background:#fff7ed; border:1px solid #fed7aa; border-radius:8px; display:flex; align-items:center; justify-content:center; font-size:10px;">☎</span> 01284858999</div>
                        <div style="display:flex; align-items:center; gap:8px; color:#334155;"><span style="width:20px; height:20px; background:#f1f5f9; border:1px solid #e2e8f0; border-radius:8px; display:flex; align-items:center; justify-content:center; font-size:10px;">✉</span> info@almossadstore.com</div>
                    </div>
                </div>
            </div>

            <!-- Items Table -->
            <div style="padding:0 36px;">
                <div style="border:1px solid #e2e8f0; border-radius:20px; overflow:hidden;">
                    <div style="background:#0f172a; color:white; display:grid; grid-template-columns: 1fr 90px 110px 110px; padding:14px 18px; font-size:11px; font-weight:900; letter-spacing:0.06em;">
                        <div>المنتج / ITEM</div>
                        <div style="text-align:center;">الكمية</div>
                        <div style="text-align:center;">سعر الوحدة</div>
                        <div style="text-align:left;">الإجمالي</div>
                    </div>
                    <div>
                        ${normalizedItems.length === 0 ? `
                            <div style="padding:36px; text-align:center; color:#94a3b8; font-weight:700; font-size:13px;">لا توجد منتجات في الفاتورة</div>
                        ` : normalizedItems.map((it, idx) => {
                            const qty = Number(it.qty ?? 1);
                            const price = Number(it.price || 0);
                            const total = qty * price;
                            const bg = idx % 2 === 0 ? '#ffffff' : '#f8fafc';
                            return `
                            <div style="display:grid; grid-template-columns: 1fr 90px 110px 110px; padding:14px 18px; background:${bg}; border-top:1px solid #f1f5f9; align-items:center;">
                                <div style="display:flex; gap:12px; align-items:center; min-width:0;">
                                    <div style="width:44px; height:44px; background:white; border:1px solid #e2e8f0; border-radius:12px; overflow:hidden; flex-shrink:0; display:flex; align-items:center; justify-content:center;">
                                        ${it.image ? `<img src="${it.image}" style="width:100%; height:100%; object-fit:cover;" onerror="this.style.display='none'"/>` : `<span style="font-size:16px; color:#cbd5e1;">📦</span>`}
                                    </div>
                                    <div style="min-width:0;">
                                        <div style="font-weight:800; font-size:13px; color:#0f172a; line-height:1.4; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; max-width:300px;">${String(it.name).replace(/</g,'&lt;')}</div>
                                        <div style="font-size:10px; font-weight:700; color:#64748b; margin-top:2px;">#${idx+1} • كود الصنف</div>
                                    </div>
                                </div>
                                <div style="text-align:center;"><span style="background:white; border:1px solid #e2e8f0; padding:6px 14px; border-radius:20px; font-weight:900; font-size:13px; color:#0f172a;">${qty}</span></div>
                                <div style="text-align:center; font-weight:700; font-size:12px; color:#334155; font-family:monospace;">${price.toLocaleString('ar-EG')} <span style="font-family:'Cairo',sans-serif; font-size:11px;">ج.م</span></div>
                                <div style="text-align:left; font-weight:900; font-size:13px; color:#0f172a; font-family:monospace;">${total.toLocaleString('ar-EG')} <span style="font-family:'Cairo',sans-serif; font-size:11px; font-weight:700;">ج.م</span></div>
                            </div>`;
                        }).join('')}
                    </div>
                </div>
            </div>

            <!-- Totals -->
            <div style="padding:18px 36px 0; display:grid; grid-template-columns: 1fr 340px; gap:20px; align-items:start;">
                <div style="background:#f8fafc; border:1px dashed #cbd5e1; border-radius:16px; padding:14px 16px;">
                    <div style="font-weight:900; font-size:11px; color:#0f172a; margin-bottom:6px;">📋 ملاحظات الفاتورة</div>
                    <div style="font-size:11px; font-weight:600; color:#475569; line-height:1.8;">
                        • الأسعار تشمل الضريبة حيثما ينطبق<br/>
                        • الدفع عند الاستلام - يرجى تجهيز المبلغ كاملاً<br/>
                        • للاستفسار: 01284858999 (واتساب / اتصال)<br/>
                        • سيتم التواصل لتأكيد الطلب خلال ساعات
                    </div>
                    <div style="margin-top:12px; background:white; border:1px solid #e2e8f0; border-radius:12px; padding:8px 10px; display:flex; justify-content:space-between; align-items:center;">
                        <span style="font-size:10px; font-weight:800; color:#64748b;">رقم الطلب الكامل</span>
                        <span style="font-family:monospace; font-size:10px; font-weight:700; color:#0f172a; letter-spacing:0.5px;">${orderIdFull}</span>
                    </div>
                </div>

                <div style="background:white; border:1px solid #e2e8f0; border-radius:20px; overflow:hidden;">
                    <div style="padding:14px 18px; display:flex; flex-direction:column; gap:10px;">
                        <div style="display:flex; justify-content:space-between; font-size:12px; font-weight:700;">
                            <span style="color:#64748b;">المجموع الفرعي</span>
                            <span style="color:#0f172a; font-family:monospace; font-weight:900;">${displaySubtotal.toLocaleString('ar-EG')} ج.م</span>
                        </div>
                        ${discountAmount > 0 ? `
                        <div style="display:flex; justify-content:space-between; font-size:12px; font-weight:800; background:#ecfdf5; border:1px solid #a7f3d0; border-radius:12px; padding:8px 12px; color:#065f46;">
                            <span>الخصم ${order?.coupon_code ? `(${order.coupon_code})` : ''}</span>
                            <span style="font-family:monospace;">-${discountAmount.toLocaleString('ar-EG')} ج.م</span>
                        </div>` : ''}
                        <div style="display:flex; justify-content:space-between; font-size:12px; font-weight:700;">
                            <span style="color:#64748b;">الشحن</span>
                            <span style="color:${shippingCost===0 ? '#059669' : '#0f172a'}; font-weight:900;">${shippingCost===0 ? 'مجاني 🎉' : shippingCost.toLocaleString('ar-EG')+' ج.م'}</span>
                        </div>
                        <div style="height:1px; background:#f1f5f9; margin:4px 0;"></div>
                        <div style="background:#0f172a; color:white; border-radius:14px; padding:14px 16px; display:flex; justify-content:space-between; align-items:center;">
                            <span style="font-weight:900; font-size:13px; letter-spacing:0.05em;">الإجمالي النهائي</span>
                            <span style="font-weight:900; font-size:18px; font-family:monospace; letter-spacing:0.5px;">${safeFinal.toLocaleString('ar-EG')} <span style="font-family:'Cairo',sans-serif; font-size:11px; font-weight:700;">ج.م</span></span>
                        </div>
                        <div style="text-align:center; font-size:10px; font-weight:700; color:#64748b;">شامل الضريبة حيثما ينطبق • الدفع عند الاستلام</div>
                    </div>
                </div>
            </div>

            <!-- Footer -->
            <div style="margin-top:22px; padding:18px 36px; background:#f8fafc; border-top:1px solid #e2e8f0; display:flex; justify-content:space-between; align-items:center;">
                <div style="display:flex; gap:16px; align-items:center;">
                    <div style="font-size:11px; font-weight:800; color:#0f172a; display:flex; align-items:center; gap:6px;">
                        <span style="width:18px; height:18px; background:#0f172a; color:white; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:10px;">✓</span>
                        شكراً لثقتك في آل مسعد
                    </div>
                    <span style="width:1px; height:16px; background:#e2e8f0;"></span>
                    <span style="font-size:10px; font-weight:700; color:#64748b;">نتطلع لخدمتك دائماً ❤️</span>
                </div>
                <div style="text-align:left; font-size:10px; font-weight:700; color:#64748b;">
                    <div>Al Mossad Store • Egypt</div>
                    <div style="font-family:monospace; letter-spacing:0.5px; margin-top:2px;">invoice • ${orderIdShort} • ${orderDate}</div>
                </div>
            </div>

            <!-- Bottom brand line -->
            <div style="height:4px; background: linear-gradient(90deg, #0f172a 0%, #334155 50%, #ea580c 100%);"></div>
        </div>
    `;

    document.body.appendChild(container);

    // Wait for fonts and images
    try {
        if (document.fonts && document.fonts.ready) await document.fonts.ready;
        // also wait a tick for images
        await new Promise(r => setTimeout(r, 400));
    } catch {}

    let canvas, pdf;
    try {
        const html2canvas = (await import('html2canvas')).default;
        const { jsPDF } = await import('jspdf');

        canvas = await html2canvas(container, {
            scale: 2,
            useCORS: true,
            allowTaint: true,
            backgroundColor: '#ffffff',
            logging: false,
            width: 794,
            windowWidth: 794,
        });

        const imgData = canvas.toDataURL('image/png');
        pdf = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' });
        const pageW = pdf.internal.pageSize.getWidth();
        const pageH = pdf.internal.pageSize.getHeight();

        const imgProps = pdf.getImageProperties(imgData);
        const pdfWidth = pageW;
        const pdfHeight = (imgProps.height * pdfWidth) / imgProps.width;

        let heightLeft = pdfHeight;
        let position = 0;

        pdf.addImage(imgData, 'PNG', 0, position, pdfWidth, pdfHeight);
        heightLeft -= pageH;

        while (heightLeft > 0) {
            position = heightLeft - pdfHeight;
            pdf.addPage();
            pdf.addImage(imgData, 'PNG', 0, position, pdfWidth, pdfHeight);
            heightLeft -= pageH;
        }

        pdf.save(`فاتورة-آل-مسعد-${orderIdShort}.pdf`);
    } catch (e) {
        console.error('Invoice html2canvas failed, fallback to jsPDF text', e);
        // Fallback: simple jsPDF with Cairo fallback (English + Arabic logical)
        try {
            const { jsPDF } = await import('jspdf');
            const doc = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' });
            const pageW = doc.internal.pageSize.getWidth();
            doc.setFillColor(15, 23, 42);
            doc.rect(0, 0, pageW, 26, 'F');
            doc.setFont('helvetica', 'bold');
            doc.setFontSize(16);
            doc.setTextColor(255,255,255);
            doc.text('AL MOSSAD - آل مسعد', 14, 16);
            doc.setFontSize(18);
            doc.setTextColor(15,23,42);
            doc.text(`Invoice #${orderIdShort}`, pageW - 14, 18, { align: 'right' });
            doc.setFontSize(11);
            doc.setTextColor(50,50,50);
            let y = 40;
            doc.text(`Customer: ${customerName}`, 14, y); y+=7;
            doc.text(`Phone: ${customerPhone}`, 14, y); y+=7;
            doc.text(`Total: ${safeFinal.toLocaleString()} EGP`, 14, y);
            doc.save(`فاتورة-آل-مسعد-${orderIdShort}.pdf`);
        } catch (fallbackErr) {
            console.error('Fallback also failed', fallbackErr);
            alert('تعذر إنشاء الفاتورة: ' + (e.message || 'خطأ غير معروف'));
        }
    } finally {
        container.remove();
    }
};
