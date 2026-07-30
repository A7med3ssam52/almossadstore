import React from 'react';

const AdminSelect = React.forwardRef(({ className = '', children, ...props }, ref) => {
    const selectClasses = `w-full bg-slate-50 border border-slate-200/60 rounded-3xl px-4 py-3.5 text-slate-900 text-sm focus:outline-none focus:ring-4 focus:ring-orange-500/10 focus:border-orange-500 transition-all font-medium appearance-none ${className}`;
    
    const bgUrl = `url("data:image/svg+xml;charset=utf-8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20fill%3D%22none%22%20viewBox%3D%220%200%2020%2020%22%3E%3Cpath%20stroke%3D%22%2364748b%22%20stroke-linecap%3D%22round%22%20stroke-linejoin%3D%22round%22%20stroke-width%3D%221.5%22%20d%3D%22m6%208%204%204%204-4%22%2F%3E%3C%2Fsvg%3E")`;

    return (
        <div className="relative">
            <select 
                ref={ref} 
                className={selectClasses} 
                style={{ 
                    backgroundImage: bgUrl, 
                    backgroundSize: '1.25rem 1.25rem', 
                    backgroundPosition: 'left 1rem center', 
                    backgroundRepeat: 'no-repeat' 
                }}
                {...props}
            >
                {children}
            </select>
        </div>
    );
});

AdminSelect.displayName = 'AdminSelect';

export default AdminSelect;
