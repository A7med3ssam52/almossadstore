import { useState, useEffect } from 'react';

const STORAGE_KEY = 'al_mossad_auth_journey';

const initialState = {
    signup: {
        currentStep: 1,
        data: {
            fullName: '',
            email: '',
            phone: '',
            address: '',
        }
    },
    login: {
        currentStep: 1,
        data: {
            email: '',
        }
    }
};

export const useAuthJourney = (type = 'signup') => {
    const [journeyState, setJourneyState] = useState(() => {
        const saved = localStorage.getItem(STORAGE_KEY);
        if (saved) {
            try {
                const parsed = JSON.parse(saved);
                // Merge with initialState to ensure structure
                return {
                    ...initialState,
                    ...parsed,
                    [type]: {
                        ...initialState[type],
                        ...parsed[type]
                    }
                };
            } catch (e) {
                console.error('Failed to parse auth journey state', e);
                return initialState;
            }
        }
        return initialState;
    });

    const state = journeyState[type];

    useEffect(() => {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(journeyState));
    }, [journeyState]);

    const updateData = (newData) => {
        setJourneyState(prev => ({
            ...prev,
            [type]: {
                ...prev[type],
                data: {
                    ...prev[type].data,
                    ...newData
                }
            }
        }));
    };

    const nextStep = () => {
        setJourneyState(prev => ({
            ...prev,
            [type]: {
                ...prev[type],
                currentStep: prev[type].currentStep + 1
            }
        }));
    };

    const prevStep = () => {
        setJourneyState(prev => ({
            ...prev,
            [type]: {
                ...prev[type],
                currentStep: Math.max(1, prev[type].currentStep - 1)
            }
        }));
    };

    const goToStep = (step) => {
        setJourneyState(prev => ({
            ...prev,
            [type]: {
                ...prev[type],
                currentStep: step
            }
        }));
    };

    const resetJourney = () => {
        setJourneyState(prev => ({
            ...prev,
            [type]: initialState[type]
        }));
    };

    return {
        currentStep: state.currentStep,
        formData: state.data,
        updateData,
        nextStep,
        prevStep,
        goToStep,
        resetJourney
    };
};
