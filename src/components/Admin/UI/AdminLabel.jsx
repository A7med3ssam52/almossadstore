import React from 'react';

const AdminLabel = ({ children, icon: Icon, iconClassName = "text-orange-500", className = '', ...props }) => {
    return (
        <label className={`flex items-center gap-2 text-[10px] font-black text-slate-500 uppercase tracking-widest mb-2 mr-1 ${className}`} {...props}>
            {Icon && <Icon size={12} className={iconClassName} />}
            {children}
        </label>
    );
};

export default AdminLabel;
