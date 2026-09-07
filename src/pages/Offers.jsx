import React, { useState, useEffect } from 'react';
import { Tag, Timer, AlertCircle } from 'lucide-react';
import { getProducts } from '@/services/supabase/inventoryService';
import { ProductCard } from '../components/FlashSale/FlashSale';

const Offers = () => {
    const [products, setProducts] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const loadProducts = async () => {
            const { data } = await getProducts();
            // Filter products that have a discount (e.g., price < compare_at_price) or just show some for now
            if (data) {
                // Show some "offers" for demonstration
                setProducts(data.slice(0, 4));
            }
            setLoading(false);
        };
        loadProducts();
    }, []);

    return (
        <div style={{ paddingBottom: '100px' }}>
            {/* Header section with countdown/promo style */}
            <div style={{ background: 'var(--accent)', padding: '60px 20px', textAlign: 'center' }}>
                <div className="container">
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '15px' }}>
                        <Tag size={48} strokeWidth={2.5} style={{ color: 'var(--primary-dark)' }} />
                        <h1 style={{ fontSize: '42px', fontWeight: '900', color: 'var(--primary-dark)' }}>عروض حصرية لفترة محدودة</h1>
                    </div>
                </div>
            </div>

            <div className="container" style={{ marginTop: '-40px' }}>
                <div style={{ 
                    background: 'white', 
                    borderRadius: '24px', 
                    padding: '40px', 
                    boxShadow: 'var(--shadow-lg)',
                    textAlign: 'center'
                }}>
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '20px' }}>
                        {[
                            { label: 'كاش باك', val: '10%', desc: 'على جميع الدهانات' },
                            { label: 'ضمان الجودة', val: 'ممتاز', desc: 'منتجات أصلية 100%' },
                            { label: 'ضمان أصلي', val: '100%', desc: 'منتجات معتمدة' },
                            { label: 'دعم فني', val: '24/7', desc: 'استشارات مجانية' }
                        ].map((o, i) => (
                            <div key={i} style={{ padding: '20px', borderRight: i !== 0 ? '1px solid #efefef' : 'none' }}>
                                <h4 style={{ fontSize: '14px', color: 'var(--text-muted)', marginBottom: '10px' }}>{o.label}</h4>
                                <h3 style={{ fontSize: '32px', fontWeight: '900', color: 'var(--primary)' }}>{o.val}</h3>
                                <p style={{ fontSize: '12px', opacity: '0.7' }}>{o.desc}</p>
                            </div>
                        ))}
                    </div>
                </div>

                <div style={{ padding: '80px 0' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '15px', marginBottom: '40px' }}>
                        <div style={{ height: '30px', width: '5px', background: 'var(--secondary)', borderRadius: '10px' }} />
                        <h2 style={{ fontSize: '28px', fontWeight: '800' }}>مختارات من العروض الحالية</h2>
                    </div>

                    {loading ? (
                        <div style={{ display: 'flex', justifyContent: 'center', padding: '100px 0' }}>
                            <div className="spinner" style={{ width: '40px', height: '40px', border: '4px solid #f3f3f3', borderTop: '4px solid var(--secondary)', borderRadius: '50%', animation: 'spin 1s linear infinite' }} />
                        </div>
                    ) : (
                        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '30px' }}>
                            {products.map(p => (
                                <ProductCard key={p.id} product={p} />
                            ))}
                        </div>
                    )}

                    {products.length === 0 && !loading && (
                        <div style={{ textAlign: 'center', padding: '60px', background: '#f8fafc', borderRadius: '30px' }}>
                            <AlertCircle size={48} style={{ color: 'var(--text-muted)', marginBottom: '20px' }} />
                            <h3 style={{ fontSize: '20px', fontWeight: '700', color: 'var(--text-muted)' }}>لا توجد عروض نشطة حالياً، تابعنا لمزيد من الخصومات!</h3>
                        </div>
                    )}
                </div>

                {/* Banner Section */}
                <div style={{ 
                    background: 'linear-gradient(135deg, #FF6B6B 0%, #FF8E53 100%)', 
                    borderRadius: '40px', 
                    padding: '80px', 
                    color: 'white',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    overflow: 'hidden',
                    position: 'relative'
                }}>
                    <div style={{ position: 'relative', zIndex: '1' }}>
                        <h2 style={{ fontSize: '48px', fontWeight: '900', marginBottom: '20px' }}>عرض خاص بمناسبة الافتتاح</h2>
                        <ul style={{ listStyle: 'none', padding: '0', display: 'flex', flexDirection: 'column', gap: '15px', fontSize: '18px' }}>
                            <li>✓ خصم 15% على أول طلب بحد أدنى 500 ج</li>
                            <li>✓ هدية مجانية مع كل عملية شراء فوق 2000 ج</li>
                            <li>✓ تقسيط بدون فوائد حتى 6 شهور</li>
                        </ul>
                        <button style={{ 
                            background: 'white', 
                            color: '#FF6B6B', 
                            padding: '18px 45px', 
                            borderRadius: '16px', 
                            fontSize: '18px', 
                            fontWeight: '900', 
                            marginTop: '30px', 
                            transition: 'transform 0.3s'
                        }} className="hover-lift">تسوق الآن</button>
                    </div>
                    <div style={{ position: 'absolute', right: '-10%', top: '50%', transform: 'translateY(-50%)', opacity: '0.2' }}>
                        <Tag size={400} />
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Offers;
