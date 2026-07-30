import React from 'react';
import { Link } from 'react-router-dom';
import { Facebook, Instagram, Twitter, Phone, Mail, MapPin, Send } from 'lucide-react';
import './Footer.css';

const Footer = () => {
    return (
        <footer className="site-footer reveal active">
            <div className="container">
                <div className="footer-grid">
                    {/* About Section */}
                    <div className="footer-section about">
                        <h3 className="footer-title">آل مسعد</h3>
                        <p className="footer-desc">
                            نحن متخصصون في توفير أرقى أنواع الحدايد والبويات والأدوات اليدوية والكهربائية. نسعى دائماً لتقديم أفضل المنتجات بأعلى جودة وأنسب الأسعار.
                        </p>
                        <div className="social-links">
                            <a href="#" className="social-icon"><Facebook size={20} /></a>
                            <a href="#" className="social-icon"><Instagram size={20} /></a>
                            <a href="#" className="social-icon"><Twitter size={20} /></a>
                        </div>
                    </div>

                    {/* Quick Links */}
                    <div className="footer-section links">
                        <h3 className="footer-title">روابط سريعة</h3>
                        <ul>
                            <li><Link to="/catalog">كل المنتجات</Link></li>
                            <li><Link to="/offers">أحدث العروض</Link></li>
                            <li><Link to="/categories">تصفح الأقسام</Link></li>
                            <li><Link to="/about">من نحن</Link></li>
                            <li><Link to="/privacy">سياسة الخصوصية</Link></li>
                            <li><Link to="/terms">الشروط والأحكام</Link></li>
                        </ul>
                    </div>

                    {/* Contact Info */}
                    <div className="footer-section contact">
                        <h3 className="footer-title">تواصل معنا</h3>
                        <div className="contact-item">
                            <MapPin size={18} />
                            <span>39 شارع ربيع الجيزي - الجيزة - بجوار مستشفى أم المصريين</span>
                        </div>
                        <div className="contact-item">
                            <Phone size={18} />
                            <span>01284858999</span>
                        </div>
                        <div className="contact-item">
                            <Mail size={18} />
                            <span>info@almossadstore.com</span>
                        </div>
                    </div>

                    {/* Newsletter (WhatsApp) */}
                    <div className="footer-section newsletter">
                        <h3 className="footer-title">اشترك في النشرة البريدية</h3>
                        <p>انضم إلينا على واتساب لتصلك أحدث العروض والخصومات فور صدورها.</p>
                        <div className="newsletter-box">
                            <input type="text" placeholder="رقم الواتساب الخاص بك" />
                            <button className="newsletter-btn">
                                <Send size={18} />
                                <span>اشتراك</span>
                            </button>
                        </div>
                    </div>
                </div>

                <div className="footer-bottom">
                    <div className="payment-icons">
                        <img src="https://encrypted-tbn3.gstatic.com/images?q=tbn:ANd9GcR_FrTaaaGEk9eULQpb355SxtAFizG5jleBqp_1q8j2dgMxqfHT" alt="Visa" />
                        <img src="https://upload.wikimedia.org/wikipedia/commons/a/a4/Mastercard_2019_logo.svg" alt="Mastercard" />
                        <img src="https://managewallet.meeza.eg/Content/logo-01.svg" alt="Meeza" />
                        <img src="https://upload.wikimedia.org/wikipedia/ar/thumb/d/db/%D9%81%D9%88%D8%B1%D9%8A.png/330px-%D9%81%D9%88%D8%B1%D9%8A.png" alt="Fawry" />
                        <img src="https://arabhardware.net/wp-content/uploads/2021/05/vodafone-cash.jpeg" alt="VodafoneCash" />
                    </div>
                    <p className="copyright">
                        &copy; {new Date().getFullYear()} آل مسعد لتجارة الحدايد والبويات. جميع الحقوق محفوظة.
                    </p>
                </div>
            </div>
        </footer>
    );
};

export default Footer;
