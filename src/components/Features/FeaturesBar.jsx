import React from 'react';
import { Truck, ShieldCheck, Headphones, CreditCard } from 'lucide-react';
import './FeaturesBar.css';

const FeaturesBar = () => {
    const features = [
        {
            icon: <Truck size={32} />,
            title: "توصيل سريع",
            desc: "لكافة أنحاء الجمهورية"
        },
        {
            icon: <ShieldCheck size={32} />,
            title: "منتجات أصلية",
            desc: "ضمان جودة 100%"
        },
        {
            icon: <Headphones size={32} />,
            title: "دعم متواصل",
            desc: "نحن معك دائماً المساعدة"
        },
        {
            icon: <CreditCard size={32} />,
            title: "دفع آمن",
            desc: "طرق دفع متعددة وسهلة"
        }
    ];

    return (
        <section className="features-bar">
            <div className="container">
                <div className="features-grid">
                    {features.map((feature, index) => (
                        <div key={index} className="feature-item">
                            <div className="feature-icon">
                                {feature.icon}
                            </div>
                            <div className="feature-info">
                                <h3>{feature.title}</h3>
                                <p>{feature.desc}</p>
                            </div>
                        </div>
                    ))}
                </div>
            </div>
        </section>
    );
};

export default FeaturesBar;
