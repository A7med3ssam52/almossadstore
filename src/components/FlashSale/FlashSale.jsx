import React from 'react';
import './FlashSale.css';

const ProductCard = ({ product }) => (
    <div className="product-card">
        <div className="card-image-wrapper">
            <img src={product.img} alt={product.name} />
            {product.discount && <span className="discount-badge">-{product.discount}%</span>}
            <span className="brand-badge">{product.brand}</span>
        </div>
        <div className="card-info">
            <h3 className="product-name">{product.name}</h3>
            <div className="price-row flex">
                <span className="current-price">{product.price} جنيه</span>
                {product.oldPrice && <span className="old-price">{product.oldPrice} جنيه</span>}
            </div>
            <p className="brand-name">{product.brand}</p>
        </div>
    </div>
);

const FlashSale = () => {
    const products = [
        { name: 'ثلاجة شارب 2 باب 450 لتر', price: '25,000', oldPrice: '28,000', discount: '10', brand: 'شارب', img: 'https://m.media-amazon.com/images/I/41Dq9Zl6nQL._AC_SL1000_.jpg' },
        { name: 'ثلاجة شارب انفرتر 530 لتر', price: '32,000', oldPrice: '35,000', discount: '8', brand: 'شارب', img: 'https://m.media-amazon.com/images/I/41Dq9Zl6nQL._AC_SL1000_.jpg' },
        { name: 'ميكروويف شارب 25 لتر', price: '6,500', oldPrice: '7,500', discount: '13', brand: 'شارب', img: 'https://m.media-amazon.com/images/I/61k88L-47ML._AC_SL1500_.jpg' },
        { name: 'قفل باب ذكي ليزن', price: '4,200', oldPrice: '5,000', discount: '16', brand: 'ليزن', img: 'https://m.media-amazon.com/images/I/51A9A9X+XPL._AC_SL1000_.jpg' },
    ];

    return (
        <section className="flash-sale-section">
            <div className="container">
                <div className="section-header">
                    <h2>عروض فلاش سيل</h2>
                    <p>أفضل وأقوى عروض فلاش سيل من آل مسعود على الموقع الألكتروني</p>
                </div>
                <div className="products-grid">
                    {products.map((p, i) => <ProductCard key={i} product={p} />)}
                </div>
            </div>
        </section>
    );
};

export default FlashSale;
