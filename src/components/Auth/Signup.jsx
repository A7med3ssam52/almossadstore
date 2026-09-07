import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { supabase } from '../../supabaseClient';
import AuthScene from './AuthScene';
import { showToast } from '../Common/StoreToast';
import './Signup.css';

const Signup = () => {
    const navigate = useNavigate();
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [formData, setFormData] = useState({
        fullName: '',
        email: '',
        phone: '',
        address: '',
        password: '',
        confirmPassword: ''
    });
    const [focusedField, setFocusedField] = useState(null);

    const handleChange = (e) => {
        setFormData({
            ...formData,
            [e.target.name]: e.target.value
        });
    };

    const handleFocus = (field) => setFocusedField(field);
    const handleBlur = () => setFocusedField(null);

    const handleSignup = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError(null);

        // Validation
        if (formData.password !== formData.confirmPassword) {
            setError('كلمات المرور غير متطابقة');
            setLoading(false);
            return;
        }

        if (formData.password.length < 8) {
            setError('كلمة المرور يجب أن تكون 8 أحرف على الأقل');
            setLoading(false);
            return;
        }

        try {
            // 1. Sign up user in Supabase Auth
            const { data: authData, error: authError } = await supabase.auth.signUp({
                email: formData.email,
                password: formData.password,
            });

            if (authError) throw authError;

            if (authData.user) {
                // 2. Create entry in profiles table
                const { error: profileError } = await supabase
                    .from('profiles')
                    .insert([
                        {
                            id: authData.user.id,
                            full_name: formData.fullName,
                            email: formData.email,
                            phone_number: formData.phone,
                            address: formData.address,
                        }
                    ]);

                if (profileError) throw profileError;

                // Success! Redirect to home
                navigate('/');
                showToast('تم إنشاء الحساب بنجاح! مرحباً بك في آل مسعد ستور', 'success');
            }
        } catch (err) {
            setError(err.message || 'حدث خطأ أثناء إنشاء الحساب');
            showToast('حدث خطأ أثناء إنشاء الحساب، يرجى المحاولة مرة أخرى', 'error');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="auth-split-layout">
            <div className="auth-3d-side">
                <AuthScene isFocused={!!focusedField} focusField={focusedField} />
            </div>

            <div className="auth-form-side">
                <div className="auth-card">
                    <div className="auth-header">
                        <h2>إنشاء حساب جديد</h2>
                        <p>انضم إلينا للاستمتاع بأفضل العروض</p>
                    </div>

                    {error && <div className="error-message">{error}</div>}

                    <form className="auth-form" onSubmit={handleSignup}>
                        <div className="form-group">
                            <label htmlFor="fullName">الاسم بالكامل</label>
                            <input
                                id="fullName"
                                type="text"
                                name="fullName"
                                placeholder="مثال: أحمد محمد"
                                required
                                aria-required="true"
                                aria-label="الاسم بالكامل"
                                value={formData.fullName}
                                onChange={handleChange}
                                onFocus={() => handleFocus('fullName')}
                                onBlur={handleBlur}
                            />
                        </div>

                        <div className="form-group">
                            <label htmlFor="email">البريد الإلكتروني</label>
                            <input
                                id="email"
                                type="email"
                                name="email"
                                placeholder="example@mail.com"
                                required
                                aria-required="true"
                                aria-label="البريد الإلكتروني"
                                value={formData.email}
                                onChange={handleChange}
                                onFocus={() => handleFocus('email')}
                                onBlur={handleBlur}
                            />
                        </div>

                        <div className="form-group">
                            <label htmlFor="phone">رقم الهاتف</label>
                            <input
                                id="phone"
                                type="tel"
                                name="phone"
                                placeholder="01xxxxxxxxx"
                                required
                                aria-required="true"
                                aria-label="رقم الهاتف"
                                value={formData.phone}
                                onChange={handleChange}
                                onFocus={() => handleFocus('phone')}
                                onBlur={handleBlur}
                            />
                        </div>

                        <div className="form-group">
                            <label htmlFor="address">العنوان بالتفصيل</label>
                            <input
                                id="address"
                                type="text"
                                name="address"
                                placeholder="المحافظة، الحي، الشارع..."
                                required
                                aria-required="true"
                                aria-label="العنوان بالتفصيل"
                                value={formData.address}
                                onChange={handleChange}
                                onFocus={() => handleFocus('address')}
                                onBlur={handleBlur}
                            />
                        </div>

                        <div className="form-group">
                            <label htmlFor="password">كلمة المرور</label>
                            <input
                                id="password"
                                type="password"
                                name="password"
                                placeholder="••••••••"
                                required
                                aria-required="true"
                                aria-label="كلمة المرور"
                                value={formData.password}
                                onChange={handleChange}
                                onFocus={() => handleFocus('password')}
                                onBlur={handleBlur}
                            />
                        </div>

                        <div className="form-group">
                            <label htmlFor="confirmPassword">تأكيد كلمة المرور</label>
                            <input
                                id="confirmPassword"
                                type="password"
                                name="confirmPassword"
                                placeholder="••••••••"
                                required
                                aria-required="true"
                                aria-label="تأكيد كلمة المرور"
                                value={formData.confirmPassword}
                                onChange={handleChange}
                                onFocus={() => handleFocus('confirmPassword')}
                                onBlur={handleBlur}
                            />
                        </div>

                        <button type="submit" className="auth-button" disabled={loading} aria-label="إنشاء الحساب">
                            {loading ? 'جاري التحميل...' : 'إنشاء الحساب'}
                        </button>
                    </form>

                    <div className="auth-footer">
                        <span>لديك حساب بالفعل؟</span>
                        <Link to="/login" className="auth-link">تسجيل الدخول</Link>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Signup;
