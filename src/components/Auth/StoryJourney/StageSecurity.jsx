import React, { useState, useEffect } from 'react';
import { motion, useAnimation } from 'framer-motion';
import './StoryJourney.css';

const StageSecurity = ({ data, updateData, onNext, onBack }) => {
    const [password, setPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    const [strength, setStrength] = useState(0);
    const lockControls = useAnimation();

    const calculateStrength = (pwd) => {
        let s = 0;
        if (pwd.length >= 6) s += 1;
        if (pwd.length >= 10) s += 1;
        if (/[A-Z]/.test(pwd)) s += 1;
        if (/[0-9]/.test(pwd)) s += 1;
        if (/[^A-Za-z0-9]/.test(pwd)) s += 1;
        return s;
    };

    useEffect(() => {
        const s = calculateStrength(password);
        setStrength(s);

        // Animate lock based on strength
        if (s >= 4) {
            lockControls.start({ scale: 1.1, rotate: [0, -10, 10, 0], transition: { duration: 0.3 } });
        } else if (s > 0) {
            lockControls.start({ scale: 1.0, rotate: 0 });
        }
    }, [password, lockControls]);

    const handleNext = () => {
        if (password === confirmPassword && password.length >= 6) {
            updateData({ password });
            onNext();
        }
    };

    const strengthColor = strength === 0 ? '#cbd5e1' :
        strength === 1 ? '#ef4444' : // ضعيفة جداً
            strength === 2 ? '#f87171' : // ضعيفة
                strength === 3 ? '#f59e0b' : // متوسطة
                    strength === 4 ? '#10b981' : // قوية
                        '#059669'; // ممتازة

    const strengthText = strength === 0 ? '' :
        strength === 1 ? 'ضعيفة جداً' :
            strength === 2 ? 'ضعيفة' :
                strength === 3 ? 'متوسطة' :
                    strength === 4 ? 'قوية' : 'ممتازة';

    return (
        <motion.div
            className="stage-container"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
        >
            <div className="micro-copy" style={{ color: '#1F2933' }}>تأمين البناء! اختر كلمة مرور قوية لحماية حسابك.</div>

            <div className="stage-content">
                <div className="form-group">
                    <label>كلمة المرور</label>
                    <input
                        type="password"
                        placeholder="••••••••"
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                    />
                    {password && (
                        <div className="strength-indicator" style={{ textAlign: 'right', marginTop: '0.5rem' }}>
                            <span style={{ color: strengthColor, fontSize: '0.85rem' }}>قوة الكلمة: {strengthText}</span>
                            <div className="strength-bar-bg" style={{ height: '4px', background: 'rgba(255,255,255,0.1)', borderRadius: '2px', marginTop: '0.25rem' }}>
                                <div className="strength-bar-fill" style={{ height: '100%', width: `${(strength / 5) * 100}%`, background: strengthColor, borderRadius: '2px', transition: 'all 0.3s ease' }} />
                            </div>
                        </div>
                    )}
                </div>
                <div className="form-group">
                    <label>تأكيد كلمة المرور</label>
                    <input
                        type="password"
                        placeholder="••••••••"
                        value={confirmPassword}
                        onChange={(e) => setConfirmPassword(e.target.value)}
                    />
                    {confirmPassword && password !== confirmPassword && (
                        <p style={{ color: '#ef4444', fontSize: '0.8rem', marginTop: '0.25rem', textAlign: 'right' }}>كلمات المرور غير متطابقة</p>
                    )}
                </div>

                <div className="stage-actions">
                    <button className="btn-back" onClick={onBack}>
                        رجوع
                    </button>
                    <button
                        className="btn-next"
                        onClick={handleNext}
                        disabled={!password || password !== confirmPassword || password.length < 6}
                    >
                        التالي: اللمسات الأخيرة
                    </button>
                </div>
            </div>
        </motion.div>
    );
};

export default StageSecurity;
