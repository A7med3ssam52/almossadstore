import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { supabase } from '../../supabaseClient';
import AuthScene from './AuthScene';
import './Login.css';

const Login = () => {
    const navigate = useNavigate();
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [formData, setFormData] = useState({
        email: '',
        password: ''
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

    const handleLogin = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError(null);

        try {
            const { error: authError } = await supabase.auth.signInWithPassword({
                email: formData.email,
                password: formData.password,
            });

            if (authError) throw authError;

            // Success! Redirect to home
            navigate('/');
        } catch (err) {
            setError('البريد الإلكتروني أو كلمة المرور غير صحيحة');
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
                        <h2>تسجيل الدخول</h2>
                        <p>مرحباً بعودتك إلى مسعد ستور</p>
                    </div>

                    {error && <div className="error-message">{error}</div>}

                    <form className="auth-form" onSubmit={handleLogin}>
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

                        <button type="submit" className="auth-button" disabled={loading} aria-label="تسجيل الدخول">
                            {loading ? 'جاري التحميل...' : 'تسجيل الدخول'}
                        </button>
                    </form>

                    <div className="auth-footer">
                        <span>ليس لديك حساب؟</span>
                        <Link to="/signup" className="auth-link">إنشاء حساب جديد</Link>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Login;
