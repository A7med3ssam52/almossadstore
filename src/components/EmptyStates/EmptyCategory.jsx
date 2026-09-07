import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { PackageSearch, ArrowLeft, LayoutGrid, Search } from 'lucide-react';
import { getCategories } from '@/services/supabase/inventoryService';

const EmptyCategory = ({ categoryName }) => {
    const [categories, setCategories] = useState([]);

    useEffect(() => {
        const fetchCats = async () => {
            const { data } = await getCategories();
            if (data) setCategories(data.filter(c => c.name !== categoryName).slice(0, 4));
        };
        fetchCats();
    }, [categoryName]);

    return (
        <div className="empty-category-wrapper">
            <div className="empty-state-card reveal active">
                <div className="empty-icon-box">
                    <PackageSearch size={80} strokeWidth={1} />
                </div>
                <h2>قريباً في قسم {categoryName}</h2>
                <p>
                    نعمل حالياً على إضافة أفضل المنتجات لهذا القسم. 
                    يمكنك تصفح بقية الأقسام أو العودة للرئيسية لاكتشاف أحدث العروض.
                </p>
                
                <div className="empty-actions">
                    <Link to="/" className="btn-home">
                        <ArrowLeft size={18} />
                        <span>الرئيسية</span>
                    </Link>
                    <Link to="/catalog" className="btn-catalog">
                        <Search size={18} />
                        <span>كل المنتجات</span>
                    </Link>
                </div>
            </div>

            {categories.length > 0 && (
                <div className="other-categories-suggestion">
                    <div className="suggestion-header">
                        <LayoutGrid size={20} />
                        <h3>تصفح أقسام أخرى</h3>
                    </div>
                    <div className="suggestion-grid">
                        {categories.map((cat) => (
                            <Link 
                                key={cat.id} 
                                to={`/category/${cat.name.replace(/\s+/g, '-')}`} 
                                className="suggestion-item"
                            >
                                <div className="suggestion-icon">
                                    {cat.icon_url ? (
                                        <img src={cat.icon_url} alt={cat.name} />
                                    ) : (
                                        <div className="fallback-icon">{cat.name[0]}</div>
                                    )}
                                </div>
                                <span>{cat.name}</span>
                            </Link>
                        ))}
                    </div>
                </div>
            )}
        </div>
    );
};

export default EmptyCategory;
