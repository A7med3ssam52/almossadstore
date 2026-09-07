import React from 'react';
import { FileText, ClipboardList, Package, CreditCard, HelpCircle } from 'lucide-react';

const Terms = () => {
    return (
        <div style={{ padding: '100px 20px', background: '#f8fafc' }}>
            <div className="container" style={{ maxWidth: '900px', margin: '0 auto', background: 'white', padding: '60px', borderRadius: '40px', boxShadow: 'var(--shadow-md)' }}>
                <div style={{ textAlign: 'center', marginBottom: '60px' }}>
                    <div style={{ background: '#fff9c4', color: '#fbc02d', width: '80px', height: '80px', borderRadius: '24px', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 20px' }}>
                        <FileText size={40} />
                    </div>
                    <h1 style={{ fontSize: '36px', fontWeight: '900', color: 'var(--primary)' }}>الشروط والأحكام</h1>
                    <p style={{ color: 'var(--text-muted)', fontSize: '18px', marginTop: '10px' }}>يرجى قراءة هذه الشروط قبل البدء في استخدام متجرنا</p>
                </div>

                <div style={{ display: 'grid', gap: '40px' }}>
                    {[
                        { 
                            icon: <ClipboardList size={24} />, 
                            title: 'الاستخدام المسؤول للموقع', 
                            content: 'باستخدامك لموقعنا، فإنك توافق على تزويدنا بمعلومات شراء دقيقة وصحيحة، مع ضمان أنك صاحب البيانات المستخدمة في إتمام الطلب.' 
                        },
                        { 
                            icon: <Package size={24} />, 
                            title: 'سياسة التوصيل والاستلام', 
                            content: 'نحن نبذل أقصى جهدنا لتسليم طلباتك في الوقت المحدد وخلال ساعات العمل المعتادة، ونقوم بتوصيل المنتجات إلى الموقع المذكور بوضوح في الطلب.' 
                        },
                        { 
                            icon: <CreditCard size={24} />, 
                            title: 'الدفع والأسعار', 
                            content: 'جميع الأسعار المذكورة في المتجر هي بالجنيه المصري، ونحن نقبل الدفع نقداً عند الاستلام أو عبر بوابات الدفع الإلكترونية المتاحة في المتجر.' 
                        },
                        { 
                            icon: <HelpCircle size={24} />, 
                            title: 'سياسة الاستبدال والاسترجاع', 
                            content: 'يمكن استبدال أو استرجاع المنتج في حال وجود عيوب في التصنيع أو إذا كان المنتج تالفاً، وذلك خلال يومين وبشرط أن يكون المنتج في حالته الأصلية.' 
                        }
                    ].map((item, i) => (
                        <div key={i} style={{ borderBottom: i !== 3 ? '1px solid #efefef' : 'none', paddingBottom: '30px' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '15px', marginBottom: '15px' }}>
                                <div style={{ color: 'var(--secondary)' }}>{item.icon}</div>
                                <h3 style={{ fontSize: '22px', fontWeight: '800', margin: '0' }}>{item.title}</h3>
                            </div>
                            <p style={{ color: 'var(--text-muted)', lineHeight: '1.8', fontSize: '16px' }}>{item.content}</p>
                        </div>
                    ))}
                </div>

                <div style={{ marginTop: '50px', paddingTop: '30px', borderTop: '1px solid #efefef', textAlign: 'center' }}>
                    <p style={{ color: 'var(--text-muted)', fontSize: '14px' }}>آخر تحديث: مارس 2026</p>
                </div>
            </div>
        </div>
    );
};

export default Terms;
