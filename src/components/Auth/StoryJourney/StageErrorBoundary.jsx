import React from 'react';

class StageErrorBoundary extends React.Component {
    constructor(props) {
        super(props);
        this.state = { hasError: false };
    }

    static getDerivedStateFromError(error) {
        return { hasError: true };
    }

    componentDidCatch(error, errorInfo) {
        console.error('Stage Error:', error, errorInfo);
    }

    render() {
        if (this.state.hasError) {
            return (
                <div className="stage-container" style={{ textAlign: 'center', padding: '2rem' }}>
                    <h3 style={{ color: '#ef4444' }}>عذراً، حدث خطأ في تحميل هذه المرحلة.</h3>
                    <button
                        className="btn-back"
                        onClick={() => window.location.reload()}
                        style={{ marginTop: '1rem' }}
                    >
                        إعادة المحاولة
                    </button>
                </div>
            );
        }

        return this.props.children;
    }
}

export default StageErrorBoundary;
