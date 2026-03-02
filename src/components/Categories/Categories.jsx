import React from 'react';
import './Categories.css';

const Categories = () => {
    const categories = [
        { name: 'الخلاطات وأنظمة الدفن والشاور', img: 'https://cdn-icons-png.flaticon.com/512/2942/2942363.png' },
        { name: 'سيراميك وبورسلين', img: 'https://cdn-icons-png.flaticon.com/512/3536/3536640.png' },
        { name: 'أجهزة منزلية', img: 'https://cdn-icons-png.flaticon.com/512/3659/3659899.png' },
        { name: 'المرايات', img: 'https://cdn-icons-png.flaticon.com/512/2704/2704400.png' },
        { name: 'أنظمة الإضاءة والمبات', img: 'https://cdn-icons-png.flaticon.com/512/3176/3176165.png' },
        { name: 'خلاطات مطبخ', img: 'https://cdn-icons-png.flaticon.com/512/2942/2942363.png' },
        { name: 'الاحواض و الوحدات', img: 'https://cdn-icons-png.flaticon.com/512/3091/3091427.png' },
    ];

    return (
        <section className="categories-section">
            <div className="container">
                <div className="categories-grid">
                    {categories.map((cat, index) => (
                        <div key={index} className="category-item">
                            <div className="category-icon-wrapper">
                                <img src={cat.img} alt={cat.name} />
                            </div>
                            <p className="category-name">{cat.name}</p>
                        </div>
                    ))}
                </div>
            </div>
        </section>
    );
};

export default Categories;
