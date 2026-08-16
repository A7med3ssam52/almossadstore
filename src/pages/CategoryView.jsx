import React, { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { getProducts, getCategories } from '@/services/supabase/inventoryService';
import { ProductCard } from '@/components/FlashSale/FlashSale';
import EmptyCategory from '@/components/EmptyStates/EmptyCategory';
import Pagination from '@/components/ui/Pagination';
import { useResponsivePagination } from '@/hooks/useResponsivePagination';
import './CategoryView.css';

const CategoryView = () => {
    const { slug } = useParams();
    const [products, setProducts] = useState([]);
    const [category, setCategory] = useState(null);
    const [loading, setLoading] = useState(true);

    const { currentPage, setCurrentPage, itemsPerPage } = useResponsivePagination(12, 10);

    const categoryTranslations = {
        'paints': 'بويات',
        'hardware': 'حدايد',
        'decor': 'ديكور',
        'adhesives': 'مواد لاصقة',
        'daily-tools': 'عدد يدوية',
        'tools': 'عدد يدوية',
        'offers': 'عروض وخصومات'
    };

    useEffect(() => {
        const fetchCategoryAndProducts = async () => {
            setLoading(true);
            try {
                const arabicName = categoryTranslations[slug.toLowerCase()] || slug.replace(/-/g, ' ');
                const { data: allCategories } = await getCategories();
                
                // Match slug to name or translation
                const matchedCat = allCategories.find(c => 
                    c.name.replace(/\s+/g, '-').toLowerCase() === slug.toLowerCase() ||
                    c.name.toLowerCase() === slug.replace(/-/g, ' ').toLowerCase() ||
                    c.name.toLowerCase() === arabicName.toLowerCase()
                );

                if (matchedCat) {
                    setCategory(matchedCat);
                    const { data: prods } = await getProducts({ categoryId: matchedCat.id });
                    setProducts(prods || []);
                } else {
                    // Fallback to translated name even if not in DB yet
                    setCategory({ name: arabicName });
                    setProducts([]);
                }
            } catch (error) {
                console.error('Error in CategoryView:', error);
            } finally {
                setLoading(false);
            }
        };

        fetchCategoryAndProducts();
    }, [slug]);

    useEffect(() => {
        setCurrentPage(1); // Reset page on category change
    }, [slug, setCurrentPage]);

    if (loading) {
        return (
            <div className="category-view-section">
                <div className="container">
                    <div className="loading-wrapper" style={{ 
                        padding: '150px 0', 
                        display: 'flex', 
                        flexDirection: 'column', 
                        alignItems: 'center', 
                        justifyContent: 'center',
                        width: '100%'
                    }}>
                        <div className="spinner" style={{ width: '40px', height: '40px', border: '4px solid rgba(0,0,0,0.1)', borderTop: '4px solid var(--primary)', borderRadius: '50%', animation: 'spin 1s linear infinite' }} />
                        <p style={{ marginTop: '20px', color: 'var(--text-muted)', fontWeight: '600' }}>جاري تحميل المنتجات...</p>
                    </div>
                </div>
            </div>
        );
    }

    return (
        <div className="category-view-section">
            <div className="container">
                <header className="category-header">
                    <h1 className="category-title">{category?.name}</h1>
                    <p className="category-count">
                        {products.length > 0 ? `${products.length} منتج متوفر حالياً` : 'بدأنا في إضافة منتجات جديدة'}
                    </p>
                </header>

                {products.length > 0 ? (
                    <>
                        <div className="category-products-grid">
                            {products.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage).map(product => (
                                <ProductCard key={product.id} product={product} />
                            ))}
                        </div>
                        <Pagination 
                            currentPage={currentPage}
                            totalItems={products.length}
                            itemsPerPage={itemsPerPage}
                            onPageChange={setCurrentPage}
                        />
                    </>
                ) : (
                    <EmptyCategory categoryName={category?.name || slug} />
                )}
            </div>
        </div>
    );
};

export default CategoryView;
