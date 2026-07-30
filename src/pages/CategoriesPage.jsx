import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { getCategories } from '@/services/supabase/inventoryService';
import { ChevronLeft } from 'lucide-react';

const CategoriesPage = () => {
    const [categories, setCategories] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const loadCategories = async () => {
            const { data } = await getCategories();
            if (data) setCategories(data);
            setLoading(false);
        };
        loadCategories();
    }, []);

    const getSlug = (cat) => {
        const mapping = {
            'بويات': 'paints',
            'حدايد': 'hardware',
            'ديكور': 'decor',
            'مواد لاصقة': 'adhesives',
            'عدد يدوية': 'daily-tools',
            'عروض وخصومات': 'offers',
            'أدوات': 'hardware',
            'عدد يدوية': 'hardware',
            'سباكة': 'hardware'
        };
        return mapping[cat.name] || cat.id;
    };

    return (
        <div style={{ padding: '80px 0' }}>
            <div className="container">
                <div style={{ marginBottom: '60px', textAlign: 'center' }}>
                    <h1 style={{ fontSize: '42px', fontWeight: '900', marginBottom: '15px' }}>تصفح الأقسام</h1>
                    <p style={{ color: 'var(--text-muted)', fontSize: '18px' }}>كل ما تحتاجه للبناء والتشطيب في مكان واحد</p>
                </div>

                {loading ? (
                    <div style={{ display: 'flex', justifyContent: 'center', padding: '100px 0' }}>
                        <div className="spinner" style={{ width: '50px', height: '50px', border: '5px solid #efefef', borderTopColor: 'var(--secondary)', borderRadius: '50%', animation: 'spin 1s linear infinite' }} />
                    </div>
                ) : (
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '40px' }}>
                        {categories.map((cat, i) => (
                            <Link to={`/category/${getSlug(cat)}`} key={cat.id} style={{ textDecoration: 'none', color: 'inherit' }}>
                                <div style={{ 
                                    background: 'white', 
                                    borderRadius: '30px', 
                                    overflow: 'hidden', 
                                    boxShadow: 'var(--shadow-sm)',
                                    transition: 'all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275)'
                                }} className="hover-lift">
                                    <div style={{ position: 'relative', paddingTop: '100%', overflow: 'hidden' }}>
                                        <img 
                                            src={cat.image_url || 'https://via.placeholder.com/400x400?text=No+Image'} 
                                            alt={cat.name} 
                                            style={{ 
                                                position: 'absolute', 
                                                top: 0, 
                                                left: 0, 
                                                width: '100%', 
                                                height: '100%', 
                                                objectFit: 'cover',
                                                transition: 'transform 0.6s'
                                            }}
                                        />
                                        <div style={{
                                            position: 'absolute',
                                            bottom: '0',
                                            left: '0',
                                            right: '0',
                                            background: 'linear-gradient(transparent, rgba(0,0,0,0.8))',
                                            padding: '30px 20px',
                                            color: 'white',
                                            display: 'flex',
                                            alignItems: 'center',
                                            justifyContent: 'space-between'
                                        }}>
                                            <h3 style={{ fontSize: '22px', fontWeight: '900', margin: '0' }}>{cat.name}</h3>
                                            <div style={{ background: 'var(--secondary)', width: '36px', height: '36px', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                                <ChevronLeft size={20} />
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </Link>
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
};

export default CategoriesPage;
