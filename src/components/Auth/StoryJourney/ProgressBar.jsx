import React from 'react';
import { motion } from 'framer-motion';
import './StoryJourney.css';

const ProgressBar = ({ currentStep, totalSteps, labels }) => {
    const percentage = (currentStep / totalSteps) * 100;

    // Default labels if none provided
    const defaultLabels = ['أساسات', 'أمان', 'وصول'];
    const activeLabels = labels || defaultLabels;

    return (
        <div className="progress-container">
            <div className="progress-track">
                <motion.div
                    className="progress-fill"
                    initial={{ width: 0 }}
                    animate={{ width: `${percentage}%` }}
                    transition={{ duration: 0.5, ease: "easeOut" }}
                />
                <div className="paint-tube-cap" />
            </div>
            <div className="progress-labels">
                {activeLabels.map((label, index) => (
                    <span
                        key={index}
                        className={currentStep >= (index + 1) ? 'active' : ''}
                    >
                        {label}
                    </span>
                ))}
            </div>
        </div>
    );
};

export default ProgressBar;
