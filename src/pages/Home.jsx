import React from 'react';
import Hero from '../components/Hero/Hero';
import Categories from '../components/Categories/Categories';
import ShopSection from '../components/ShopSection/ShopSection';
import bannerImg from '../assets/banner.png';

const Home = () => {
    return (
        <main>
            <Hero bannerSrc={bannerImg} />
            <Categories />
            <ShopSection />
        </main>
    );
};

export default Home;
