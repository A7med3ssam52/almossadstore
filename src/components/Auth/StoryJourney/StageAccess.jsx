import React from 'react';
import { motion } from 'framer-motion';
import './StoryJourney.css';

const StageAccess = ({ data, updateData, onBack, onSubmit, isLoading }) => {
    return (
        <motion.div
            className="stage-container"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
        >
            <div className="micro-copy" style={{ color: '#1F2933' }}>لقد اقتربنا! نحتاج فقط لتفاصيل التوصيل والاتصال.</div>

            <div className="stage-content">
                <div className="form-group">
                    <label>رقم الهاتف</label>
                    <input
                        type="tel"
                        placeholder="0123456789"
                        value={data.phone || ''}
                        onChange={(e) => updateData({ phone: e.target.value })}
                    />
                </div>
                <div className="form-group">
                    <label>العنوان</label>
                    <input
                        type="text"
                        placeholder="المدينة، الشارع، المبنى"
                        value={data.address || ''}
                        onChange={(e) => updateData({ address: e.target.value })}
                    />
                </div>

                <div className="stage-actions">
                    <button className="btn-back" onClick={onBack} disabled={isLoading}>
                        رجوع
                    </button>
                    <button
                        className="btn-submit"
                        onClick={onSubmit}
                        disabled={!data.phone || !data.address || isLoading}
                    >
                        {isLoading ? 'جاري اكتمال البناء...' : 'إنشاء وحفظ البناء'}
                    </button>
                </div>
            </div>
        </motion.div>
    );
};

export default StageAccess;
