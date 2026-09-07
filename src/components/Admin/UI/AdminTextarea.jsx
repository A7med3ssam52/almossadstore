import React from 'react';

const AdminTextarea = React.forwardRef(({ className = '', ...props }, ref) => {
    const textareaClasses = `w-full bg-slate-50 border border-slate-200/60 rounded-3xl px-4 py-3.5 text-slate-900 text-sm focus:outline-none focus:ring-4 focus:ring-orange-500/10 focus:border-orange-500 transition-all font-medium resize-none ${className}`;

    return <textarea ref={ref} className={textareaClasses} {...props} />;
});

AdminTextarea.displayName = 'AdminTextarea';

export default AdminTextarea;
