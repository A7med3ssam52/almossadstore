import React from 'react';
import { Target, Users, ShieldCheck, History } from 'lucide-react';
import './About.css';

const About = () => {
    return (
        <div className="about-page">
            {/* Hero Header */}
            <header className="about-hero animate-fade-in">
                <div className="container">
                    <h1>آل مسعد للتجارة</h1>
                    <p>
                        إرث يمتد لسنوات في خدمة قطاع البناء والتشطيب، نوفر أجود أنواع الحدايد والبويات والأدوات.
                    </p>
                </div>
                <div className="hero-glow"></div>
            </header>

            {/* Our Story */}
            <section className="story-section">
                <div className="container">
                    <div className="story-grid">
                        <div className="story-content reveal active">
                            <span>قصتنا</span>
                            <h2>أكثر من مجرد متجر</h2>
                            <p>
                                بدأت رحلة "آل مسعد" كمتجر صغير يسعى لتلبية احتياجات السوق المحلية من مواد البناء الأساسية. وبفضل الالتزام بالجودة والأمانة في التعامل، توسعنا لنصبح اليوم الوجهة الأولى للمقاولين، الفنيين، وأصحاب المنازل.
                            </p>
                            <p>
                                نحن لا نبيع فقط "حدايد وبويات"، بل نبيع الثقة في جودة كل قطرة دهان وكل مسمار يُستخدم في بناء بيوتكم ومشاريعكم.
                            </p>
                        </div>
                        <div className="story-image-wrapper">
                            <img 
                                src="https://images.unsplash.com/photo-1541888946425-d81bb19480c5?auto=format&fit=crop&q=80&w=600" 
                                alt="Store building" 
                                className="story-image"
                            />
                            <div className="experience-badge">
                                <div className="badge-icon">
                                    <History size={24} />
                                </div>
                                <div className="badge-text">
                                    <h4>15+</h4>
                                    <p>عاماً من الخبرة</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            {/* Values */}
            <section className="values-section">
                <div className="container">
                    <div className="section-header" style={{ textAlign: 'center', marginBottom: '60px' }}>
                        <h2 style={{ fontSize: '36px', fontWeight: '800', color: 'var(--primary)' }}>قيمنا الأساسية</h2>
                    </div>
                    <div className="values-grid">
                        {[
                            { icon: <ShieldCheck size={40} />, title: "الجودة أولاً", desc: "نحن لا نرضى بغير الأفضل، ونختار موردينا بعناية فائقة لضمان أعلى المعايير." },
                            { icon: <Users size={40} />, title: "العميل شريك", desc: "نبني علاقات طويلة الأمد مع عملائنا تقوم على النصح الصادق والخدمة المتميزة." },
                            { icon: <Target size={40} />, title: "الابتكار", desc: "نسعى باستمرار لتطوير خدماتنا وحلولنا الرقمية لتسهيل رحلة الشراء." }
                        ].map((v, i) => (
                            <div key={i} className="value-card">
                                <div className="value-icon">
                                    {v.icon}
                                </div>
                                <h3>{v.title}</h3>
                                <p>{v.desc}</p>
                            </div>
                        ))}
                    </div>
                </div>
            </section>
        </div>
    );
};

export default About;
