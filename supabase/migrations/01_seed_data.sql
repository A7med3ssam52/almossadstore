-- Seed Data for Al Mossad Store

-- Categories
INSERT INTO categories (name_ar, icon_name, sort_order) VALUES
('عدد يدوية', 'wrench', 1),
('بويات وطلاء', 'paint-bucket', 2),
('سباكة', 'droplets', 3),
('كهرباء', 'zap', 4),
('أجهزة منزلية', 'tv', 5),
('أبواب ونوافذ', 'door-closed', 6);

-- Hero Slides
INSERT INTO hero_slides (title_ar, subtitle_ar, image_url, badge_text_ar, sort_order) VALUES
('عروض رمضان الحصرية', 'خصومات تصل إلى 50% على جميع أنواع البويات', 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?q=80&w=2000', 'رمضان كريم', 1),
('أحدث العدد اليدوية', 'ماركات توتال وإينكو الأصلية الآن بأفضل الأسعار', 'https://images.unsplash.com/photo-1530124560676-41bc1275d4d6?q=80&w=2000', 'جديد', 2);

-- Products (Flash Sale)
INSERT INTO products (name_ar, brand_ar, price, old_price, discount_percent, image_url, is_flash_sale, stock_quantity) VALUES
('ثلاجة شارب 2 باب 450 لتر', 'شارب', 25000, 28000, 10, 'https://m.media-amazon.com/images/I/41Dq9Zl6nQL._AC_SL1000_.jpg', true, 5),
('ميكروويف شارب 25 لتر', 'شارب', 6500, 7500, 13, 'https://m.media-amazon.com/images/I/61k88L-47ML._AC_SL1500_.jpg', true, 12),
('قفل باب ذكي ليزن', 'ليزن', 4200, 5000, 16, 'https://m.media-amazon.com/images/I/51A9A9X+XPL._AC_SL1000_.jpg', true, 8),
('بويات جوتن فينوماستيك 10 لتر', 'جوتن', 1200, 1450, 17, 'https://api.jotun.com/media-repository/1243_Fenomastic_My_Home_Smooth_Silk_12qt.png', true, 20);
