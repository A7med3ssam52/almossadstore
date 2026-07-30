import React from 'react';
import { motion } from 'framer-motion';
import './StoryJourney.css';

const StageFoundations = ({ data, updateData, onNext }) => {
    return (
        <motion.div
            className="stage-container"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
        >
            <div className="micro-copy" style={{ color: '#1F2933' }}>مرحباً بك! لنبدأ بوضع حجر الأساس لحسابك.</div>

            <div className="stage-content">
                <div className="form-group">
                    <label>الاسم الكامل</label>
                    <input
                        type="text"
                        placeholder="أدخل اسمك بالكامل"
                        value={data.fullName || ''}
                        onChange={(e) => updateData({ fullName: e.target.value })}
                    />
                </div>
                <div className="form-group">
                    <label>البريد الإلكتروني</label>
                    <input
                        type="email"
                        placeholder="example@mail.com"
                        value={data.email || ''}
                        onChange={(e) => updateData({ email: e.target.value })}
                    />
                </div>

                <div className="stage-actions">
                    <button
                        className="btn-next"
                        onClick={onNext}
                        disabled={!data.fullName || !data.email}
                        style={{ width: '100%' }}
                    >
                        التالي: تأمين البناء
                    </button>
                </div>
                <div style={{ marginTop: '1.5rem', textAlign: 'center' }}>
                    <p style={{ color: '#64748b', fontSize: '0.9rem' }}>
                        لديك حساب بالفعل؟ <span onClick={() => window.dispatchEvent(new CustomEvent('auth:open', { detail: { mode: 'login' } }))} style={{ color: '#1F2933', cursor: 'pointer', fontWeight: 700 }}>سجل الدخول</span>
                    </p>
                </div>
            </div>
        </motion.div>
    );
};

export default StageFoundations;
