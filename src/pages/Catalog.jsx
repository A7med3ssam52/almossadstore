import React, { useState, useEffect, useMemo } from 'react';
import { Search, Filter, SlidersHorizontal, ChevronDown, ShoppingBag, X } from 'lucide-react';
import { getProducts, getCategories } from '../services/supabase/inventoryService';
import { ProductCard } from '../components/FlashSale/FlashSale';
import Pagination from '../components/UI/Pagination';
import { useResponsivePagination } from '../hooks/useResponsivePagination';
import './Catalog.css';
import '../components/FlashSale/FlashSale.css';

const Catalog = () => {
    const [products, setProducts] = useState([]);
    const [categories, setCategories] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showMobileFilters, setShowMobileFilters] = useState(false);
    
    const { currentPage, setCurrentPage, itemsPerPage } = useResponsivePagination(12, 10);

    // Filters State
    const [searchQuery, setSearchQuery] = useState('');
    const [selectedCategory, setSelectedCategory] = useState('all');
    const [priceRange, setPriceRange] = useState([0, 50000]);
    const [sortBy, setSortBy] = useState('newest');

    useEffect(() => {
        const fetchData = async () => {
            setLoading(true);
            const [prodRes, catRes] = await Promise.all([
                getProducts(),
                getCategories()
            ]);
            if (prodRes.data) setProducts(prodRes.data);
            if (catRes.data) setCategories(catRes.data);
            setLoading(false);
        };
        fetchData();
    }, []);

    // Extended filtering logic
    const filteredProducts = useMemo(() => {
        return products
            .filter(p => {
                const matchesSearch = p.name.toLowerCase().includes(searchQuery.toLowerCase());
                const matchesCategory = selectedCategory === 'all' || p.category_id === selectedCategory || p.categories?.name === selectedCategory;
                const matchesPrice = p.base_price >= priceRange[0] && p.base_price <= priceRange[1];
                return matchesSearch && matchesCategory && matchesPrice;
            })
            .sort((a, b) => {
                if (sortBy === 'newest') return new Date(b.created_at) - new Date(a.created_at);
                if (sortBy === 'price-low') return a.base_price - b.base_price;
                if (sortBy === 'price-high') return b.base_price - a.base_price;
                return 0;
            });
    }, [products, searchQuery, selectedCategory, priceRange, sortBy]);

    useEffect(() => {
        setCurrentPage(1);
    }, [searchQuery, selectedCategory, priceRange, sortBy, setCurrentPage]);

    const paginatedProducts = useMemo(() => {
        const start = (currentPage - 1) * itemsPerPage;
        return filteredProducts.slice(start, start + itemsPerPage);
    }, [filteredProducts, currentPage, itemsPerPage]);

    const Sidebar = () => (
        <aside className="catalog-sidebar">
            <div className="filter-group">
                <h3 className="filter-title">الأقسام</h3>
                <div className="filter-options">
                    <button 
                        className={`filter-btn ${selectedCategory === 'all' ? 'active' : ''}`}
                        onClick={() => setSelectedCategory('all')}
                    >
                        الكل
                    </button>
                    {categories.map(cat => (
                        <button 
                            key={cat.id}
                            className={`filter-btn ${selectedCategory === cat.id ? 'active' : ''}`}
                            onClick={() => setSelectedCategory(cat.id)}
                        >
                            {cat.name}
                        </button>
                    ))}
                </div>
            </div>

            <div className="filter-group">
                <h3 className="filter-title">نطاق السعر</h3>
                <div className="price-inputs">
                    <div className="price-input-wrap">
                        <span>من</span>
                        <input 
                            type="number" 
                            value={priceRange[0]} 
                            onChange={(e) => setPriceRange([parseInt(e.target.value) || 0, priceRange[1]])}
                        />
                    </div>
                    <div className="price-input-wrap">
                        <span>إلى</span>
                        <input 
                            type="number" 
                            value={priceRange[1]} 
                            onChange={(e) => setPriceRange([priceRange[0], parseInt(e.target.value) || 0])}
                        />
                    </div>
                </div>
            </div>

            <div className="filter-group">
                <h3 className="filter-title">الترتيب حسب</h3>
                <select 
                    className="catalog-select"
                    value={sortBy}
                    onChange={(e) => setSortBy(e.target.value)}
                >
                    <option value="newest">الأحدث أولاً</option>
                    <option value="price-low">السعر: من الأقل</option>
                    <option value="price-high">السعر: من الأعلى</option>
                </select>
            </div>
        </aside>
    );

    return (
        <div className="catalog-page">
            <div className="catalog-hero">
                <div className="container">
                    <h1>متجر آل مسعد</h1>
                    <p>اكتشف تشكيلتنا الواسعة من المنتجات عالية الجودة</p>
                </div>
            </div>

            <div className="container catalog-container">
                {/* Search Bar */}
                <div className="catalog-toolbar">
                    <div className="search-box">
                        <Search size={20} className="search-icon" />
                        <input 
                            type="text" 
                            placeholder="ابحث عن منتج..."
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                        />
                    </div>
                    <button 
                        className="mobile-filter-trigger"
                        onClick={() => setShowMobileFilters(true)}
                    >
                        <Filter size={20} />
                        فلاتر
                    </button>
                    <div className="desktop-sort">
                        <select 
                            value={sortBy}
                            onChange={(e) => setSortBy(e.target.value)}
                        >
                            <option value="newest">الأحدث</option>
                            <option value="price-low">السعر للأقل</option>
                            <option value="price-high">السعر للأعلى</option>
                        </select>
                    </div>
                </div>

                <div className="catalog-layout">
                    {/* Desktop Sidebar */}
                    <div className="catalog-sidebar-wrapper">
                        <Sidebar />
                    </div>

                    {/* Product Grid */}
                    <div className="catalog-main">
                        {loading ? (
                            <div className="catalog-loading">
                                <div className="spinner" />
                            </div>
                        ) : filteredProducts.length > 0 ? (
                            <>
                                <div className="catalog-grid">
                                    {paginatedProducts.map(product => (
                                        <ProductCard key={product.id} product={product} />
                                    ))}
                                </div>
                                <Pagination 
                                    currentPage={currentPage}
                                    totalItems={filteredProducts.length}
                                    itemsPerPage={itemsPerPage}
                                    onPageChange={setCurrentPage}
                                />
                            </>
                        ) : (
                            <div className="catalog-empty">
                                <ShoppingBag size={64} />
                                <h2>لا توجد نتائج</h2>
                                <p>جرب تصفية مختلفة أو ابحث عن شيء آخر</p>
                                <button className="reset-btn" onClick={() => {
                                    setSearchQuery('');
                                    setSelectedCategory('all');
                                    setPriceRange([0, 50000]);
                                }}>
                                    إعادة ضبط الكل
                                </button>
                            </div>
                        )}
                    </div>
                </div>
            </div>

            {/* Mobile Filter Drawer */}
            <div className={`filter-drawer-overlay ${showMobileFilters ? 'active' : ''}`} onClick={() => setShowMobileFilters(false)}>
                <div className={`filter-drawer ${showMobileFilters ? 'active' : ''}`} onClick={e => e.stopPropagation()}>
                    <div className="drawer-header">
                        <h2>تصفية المنتجات</h2>
                        <button onClick={() => setShowMobileFilters(false)}><X size={24} /></button>
                    </div>
                    <div className="drawer-body">
                        <Sidebar />
                    </div>
                    <div className="drawer-footer">
                        <button className="apply-btn" onClick={() => setShowMobileFilters(false)}>إظهار {filteredProducts.length} منتج</button>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Catalog;
