import React, { useState, useEffect } from 'react';
import { ChevronRight, ChevronLeft } from 'lucide-react';
import './Hero.css';

const Hero = ({ bannerSrc }) => {
    const slides = [
        {
            id: 1,
            bgGradient: 'linear-gradient(135deg, #0f172a 0%, #1e293b 100%)',
            title: 'آل مسعد للأصالة والجودة',
            brand: '',
            badge: 'الأصلي',
            features: [
                { value: '40+', label: 'عاماً' },
                { value: 'ثقة', label: 'عملاؤنا' },
                { value: 'جودة', label: 'عالمية' }
            ],
            footer: ''
        },
        {
            id: 2,
            bgGradient: 'linear-gradient(135deg, #1e293b 0%, #0f172a 100%)',
            title: 'الحديد ومواد البناء الأساسية',
            brand: '',
            badge: 'تخصصنا',
            features: [
                { value: 'نخب', label: 'أول' },
                { value: 'شحن', label: 'سريع' },
                { value: 'أفضل', label: 'سعر' }
            ],
            footer: ''
        },
        {
            id: 3,
            bgGradient: 'linear-gradient(135deg, #FF7E5F 0%, #FEB47B 100%)',
            image: 'https://images.alborsaanews.com/2021/01/1588710723_862_19099_49121003_1376346015829712_3952716118279323648_n1.jpg',
            title: 'متاح التلوين الكمبيوتر',
            brand: '',
            badge: 'إبداع',
            features: [
                { value: 'GLC', label: 'وكيل' },
                { value: 'SCIP', label: 'وكيل' },
                { value: 'جوتن', label: 'وكيل' }
            ],
            footer: ''
        },
        {
            id: 4,
            bgGradient: 'linear-gradient(135deg, #1e293b 0%, #020617 100%)',
            title: 'العدد والأدوات الاحترافية',
            brand: '',
            badge: 'احتراف',
            features: [
                { value: 'أصلي', label: '100%' },
                { value: 'ماركات', label: 'عالمية' },
                { value: 'ضمان', label: 'شامل' }
            ],
            footer: ''
        },
        {
            id: 5,
            bgGradient: 'linear-gradient(135deg, #3b82f6 0%, #1e3a8a 100%)',
            title: 'خدمة عملاء ودعم متميز',
            brand: '',
            badge: 'متميز',
            features: [
                { value: 'شحن', label: 'سريع' },
                { value: 'دعم', label: 'فني' },
                { value: 'إرجاع', label: 'سهل' }
            ],
            footer: ''
        }
    ];

    const [currentSlide, setCurrentSlide] = useState(0);

    useEffect(() => {
        const timer = setInterval(() => {
            setCurrentSlide((prev) => (prev === slides.length - 1 ? 0 : prev + 1));
        }, 6000);
        return () => clearInterval(timer);
    }, [slides.length, currentSlide]);

    const nextSlide = () => setCurrentSlide((prev) => (prev === slides.length - 1 ? 0 : prev + 1));
    const prevSlide = () => setCurrentSlide((prev) => (prev === 0 ? slides.length - 1 : prev - 1));

    return (
        <section className="hero-section">
            <div className="container">
                <div className="hero-slider-container">
                    {slides.map((slide, index) => (
                        <div
                            key={slide.id}
                            className={`hero-slide ${index === currentSlide ? 'active' : ''}`}
                            style={{ 
                                background: slide.image 
                                    ? `linear-gradient(rgba(0,0,0,0.3), rgba(0,0,0,0.3)), url(${slide.image}) center/cover no-repeat` 
                                    : slide.bgGradient 
                            }}
                        >
                            <div className="hero-overlay">
                                <div className="hero-content-wrap">
                                    {slide.brand && (
                                        <div className="hero-brand-tag">
                                            {slide.brand}
                                        </div>
                                    )}
                                    <h1 className="hero-promo-title">{slide.title}</h1>

                                    <div className="hero-highlight-row">
                                        {slide.badge && <div className="aman-badge">{slide.badge}</div>}
                                        <div className="percent-items">
                                            {slide.features.map((f, i) => (
                                                <div key={i} className="percent-item">
                                                    <span className="percent-val">{f.value}</span>
                                                    <span className="percent-label">{f.label}</span>
                                                </div>
                                            ))}
                                        </div>
                                    </div>

                                    <div className="hero-footer-row">
                                        {slide.footer && <p className="hero-promo-footer">{slide.footer}</p>}
                                        <button 
                                            className="hero-buy-btn"
                                            onClick={() => document.getElementById('shop-section')?.scrollIntoView({ behavior: 'smooth' })}
                                        >
                                            اكتشف الآن
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    ))}

                    {/* Navigation Controls */}
                    <button className="slider-arrow prev" onClick={prevSlide} aria-label="السابق">
                        <ChevronRight size={24} />
                    </button>
                    <button className="slider-arrow next" onClick={nextSlide} aria-label="التالي">
                        <ChevronLeft size={24} />
                    </button>

                    <div className="slider-dots">
                        {slides.map((_, idx) => (
                            <span
                                key={idx}
                                className={`slider-dot ${idx === currentSlide ? 'active' : ''}`}
                                onClick={() => setCurrentSlide(idx)}
                            />
                        ))}
                    </div>
                </div>
            </div>
        </section>
    );
};

export default Hero;
