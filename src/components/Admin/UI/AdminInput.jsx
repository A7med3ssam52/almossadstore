import React from 'react';

const AdminInput = React.forwardRef(({ className = '', inputClassName = '', icon: Icon, ...props }, ref) => {
    const defaultClasses = `w-full bg-slate-50 border border-slate-200/60 rounded-3xl px-4 py-3.5 text-slate-900 text-sm focus:outline-none focus:ring-4 focus:ring-orange-500/10 focus:border-orange-500 transition-all font-medium ${Icon ? 'pl-12' : ''} ${inputClassName}`;

    if (Icon) {
        return (
            <div className={`relative ${className}`}>
                <input ref={ref} className={defaultClasses} {...props} />
                <Icon size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
            </div>
        );
    }

    return <input ref={ref} className={`${defaultClasses} ${className}`} {...props} />;
});

AdminInput.displayName = 'AdminInput';

export default AdminInput;
