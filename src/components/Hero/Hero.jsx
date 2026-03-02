import React from 'react';
import './Hero.css';

const Hero = ({ bannerSrc }) => {
    return (
        <section className="hero-section">
            <div className="container">
                <div className="hero-slider">
                    <div className="slide">
                        <img src={bannerSrc} alt="Al Massoud Store Banner" className="hero-image" />
                        <div className="slide-content">
                            <div className="badge">رمضان كريم</div>
                            <h2>عروض وخصومات رمضان</h2>
                            <div className="offers-grid flex">
                                <div className="offer-item">
                                    <span className="offer-value">0%</span>
                                    <span className="offer-label">فوائد</span>
                                </div>
                                <div className="offer-item">
                                    <span className="offer-value">0%</span>
                                    <span className="offer-label">مصاريف إدارية</span>
                                </div>
                                <div className="offer-item">
                                    <span className="offer-value">0%</span>
                                    <span className="offer-label">مقدم</span>
                                </div>
                            </div>
                            <p className="offer-validity">العرض ساري من 18 ل 28 فبراير</p>
                        </div>

                        <button className="slider-nav prev"><i className="icon-chevron-right"></i></button>
                        <button className="slider-nav next"><i className="icon-chevron-left"></i></button>
                    </div>
                </div>
            </div>
        </section>
    );
};

export default Hero;
