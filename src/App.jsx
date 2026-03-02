import React from 'react';
import Header from './components/Header/Header';
import Navbar from './components/Navbar/Navbar';
import Hero from './components/Hero/Hero';
import Categories from './components/Categories/Categories';
import FlashSale from './components/FlashSale/FlashSale';
import WhatsAppWidget from './components/WhatsAppWidget/WhatsAppWidget';
import bannerImg from './assets/banner.png';

function App() {
  return (
    <div className="app">
      <Header />
      <Navbar />
      <main>
        <Hero bannerSrc={bannerImg} />
        <Categories />
        <FlashSale />
      </main>
      <footer className="site-footer">
        <div className="container">
          <p>&copy; {new Date().getFullYear()} آل مسعود لتجارة الحدايد والبويات. جميع الحقوق محفوظة.</p>
        </div>
      </footer>
      <WhatsAppWidget />
    </div>
  );
}

export default App;
