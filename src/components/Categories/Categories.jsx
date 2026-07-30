import React, { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import './Categories.css';

const Categories = () => {
    const categories = [
        { name: 'بويات', img: 'https://images.alborsaanews.com/2021/01/1588710723_862_19099_49121003_1376346015829712_3952716118279323648_n1.jpg', route: '/category/paints' },
        { name: 'حدايد', img: 'https://images.unsplash.com/photo-1530124566582-a618bc2615dc?auto=format&fit=crop&q=80&w=300', route: '/category/hardware' },
        { name: 'ديكور', img: 'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&q=80&w=300', route: '/category/decor' },
        { name: 'مواد لاصقة', img: 'https://cdn.prod.website-files.com/5897fc2c176071a2715ce48c/59e7b3d178fec4000117a907_adhesive_1.jpg', route: '/category/adhesives' },
        { name: 'عدد يدوية', img: 'https://images.unsplash.com/photo-1581244276891-83393a8ba21d?auto=format&fit=crop&q=80&w=300', route: '/category/daily-tools' },
        { name: 'عروض وخصومات', img: 'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?auto=format&fit=crop&q=80&w=300', route: '/category/offers' },
    ];

    const [isInView, setIsInView] = useState(false);
    const sectionRef = useRef(null);

    useEffect(() => {
        const observer = new IntersectionObserver(
            ([entry]) => {
                if (entry.isIntersecting) {
                    setIsInView(true);
                    observer.unobserve(entry.target);
                }
            },
            { threshold: 0.2 }
        );

        if (sectionRef.current) {
            observer.observe(sectionRef.current);
        }

        return () => {
            if (sectionRef.current) observer.unobserve(sectionRef.current);
        };
    }, []);

    return (
        <section className="categories-section" ref={sectionRef}>
            <div className="container">
                <div className={`categories-grid ${isInView ? 'trigger-hint' : ''}`}>
                    {categories.map((cat, index) => (
                        <Link 
                            to={cat.route} 
                            key={index} 
                            className="category-item"
                            onClick={() => window.scrollTo(0, 0)}
                        >
                            <div className="category-icon-wrapper">
                                <img src={cat.img} alt={cat.name} />
                            </div>
                            <p className="category-name">{cat.name}</p>
                        </Link>
                    ))}
                </div>
            </div>
        </section>
    );
};

export default Categories;
