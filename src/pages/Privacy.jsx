import React from 'react';
import { Shield, Lock, Eye, Bell } from 'lucide-react';

const Privacy = () => {
    return (
        <div style={{ padding: '100px 20px', background: '#f8fafc' }}>
            <div className="container" style={{ maxWidth: '900px', margin: '0 auto', background: 'white', padding: '60px', borderRadius: '40px', boxShadow: 'var(--shadow-md)' }}>
                <div style={{ textAlign: 'center', marginBottom: '60px' }}>
                    <div style={{ background: '#e0f2f1', color: 'var(--secondary)', width: '80px', height: '80px', borderRadius: '24px', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 20px' }}>
                        <Shield size={40} />
                    </div>
                    <h1 style={{ fontSize: '36px', fontWeight: '900', color: 'var(--primary)' }}>سياسة الخصوصية</h1>
                    <p style={{ color: 'var(--text-muted)', fontSize: '18px', marginTop: '10px' }}>كيف نحافظ على أمان بياناتك</p>
                </div>

                <div style={{ display: 'grid', gap: '40px' }}>
                    {[
                        { icon: <Eye size={24} />, title: 'جمع المعلومات', content: 'نقوم بجمع بعض المعلومات البسيطة لتسهيل عملية الشراء، مثل الاسم، رقم الهاتف، وعنوان الشحن لكي نتمكن من الوصول إليك وتوصيل طلباتك.' },
                        { icon: <Lock size={24} />, title: 'حماية البيانات', content: 'نحن نستخدم تقنيات حديثة لحماية بياناتك الشخصية من الوصول غير المصرح به، ونؤكد لك أن جميع بياناتك يتم تداولها فقط داخل طاقم عمل "آل مسعد" من أجل خدمتك.' },
                        { icon: <Bell size={24} />, title: 'التواصل معك', content: 'قد نرسل لك رسائل عبر واتساب أو بريدك الإلكتروني لتعريفك بحالة طلبك أو لإخبارك بأحدث العروض والخصومات، ويمكنك دائماً إلغاء الاشتراك في هذه الرسائل.' }
                    ].map((item, i) => (
                        <div key={i} style={{ borderBottom: i !== 2 ? '1px solid #efefef' : 'none', paddingBottom: '30px' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '15px', marginBottom: '15px' }}>
                                <div style={{ color: 'var(--secondary)' }}>{item.icon}</div>
                                <h3 style={{ fontSize: '22px', fontWeight: '800', margin: '0' }}>{item.title}</h3>
                            </div>
                            <p style={{ color: 'var(--text-muted)', lineHeight: '1.8', fontSize: '16px' }}>{item.content}</p>
                        </div>
                    ))}
                </div>

                <div style={{ marginTop: '60px', padding: '30px', background: '#e1f5fe', borderRadius: '20px', display: 'flex', gap: '20px', alignItems: 'flex-start' }}>
                    <div style={{ color: '#039be5' }}><Lock size={32} /></div>
                    <div>
                        <h4 style={{ fontSize: '18px', fontWeight: '800', color: '#01579b', marginBottom: '8px' }}>نحن لا نبيع بياناتك لأي جهة خارجية</h4>
                        <p style={{ fontSize: '14px', color: '#0277bd', margin: '0', opacity: '0.8' }}>
                            نحن نقدر خصوصيتك تماماً، ولن يتم أبداً مشاركة أو بيع أي من تفاصيل بياناتك لأغراض التسويق الخارجي.
                        </p>
                    </div>
                </div>

                <div style={{ marginTop: '50px', paddingTop: '30px', borderTop: '1px solid #efefef', textAlign: 'center' }}>
                    <p style={{ color: 'var(--text-muted)', fontSize: '14px' }}>آخر تحديث: مارس 2026</p>
                </div>
            </div>
        </div>
    );
};

export default Privacy;
