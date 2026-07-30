import React, { useEffect, useState } from 'react';
import { getProducts } from '@/services/supabase/inventoryService';
import { ProductCard } from '../FlashSale/FlashSale';
import Pagination from '@/components/UI/Pagination';
import { useResponsivePagination } from '@/hooks/useResponsivePagination';
import './ShopSection.css';
import '../FlashSale/FlashSale.css';

const ShopSection = () => {
    const [products, setProducts] = useState([]);
    const [loading, setLoading] = useState(true);

    const { currentPage, setCurrentPage, itemsPerPage } = useResponsivePagination(12, 10);

    useEffect(() => {
        const loadProducts = async () => {
            const { data } = await getProducts();
            if (data) setProducts(data);
            setLoading(false);
        };
        loadProducts();
    }, []);

    return (
        <section className="shop-section" id="shop-section">
            <div className="container">
                <div className="section-header">
                    <h2 className="section-title">متجرنا</h2>
                    <p className="section-subtitle">تسوق أحدث المنتجات الأصلية عالية الجودة من آل مسعد</p>
                </div>

                {loading ? (
                    <div className="loading-wrapper">
                        <div className="spinner" />
                    </div>
                ) : (
                    <>
                        <div className="products-grid-shop">
                            {products.length > 0 ? (
                                products.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage).map((p) => <ProductCard key={p.id} product={p} />)
                            ) : (
                                <p className="empty-msg">لا توجد منتجات متوفرة حالياً</p>
                            )}
                        </div>
                        {products.length > 0 && (
                            <Pagination 
                                currentPage={currentPage}
                                totalItems={products.length}
                                itemsPerPage={itemsPerPage}
                                onPageChange={setCurrentPage}
                            />
                        )}
                    </>
                )}
            </div>
        </section>
    );
};

export default ShopSection;
