import React from 'react';
import { ChevronRight, ChevronLeft } from 'lucide-react';

const Pagination = ({ currentPage, totalItems, itemsPerPage, onPageChange }) => {
    const totalPages = Math.max(1, Math.ceil(totalItems / itemsPerPage));

    if (totalItems === 0 || totalPages <= 1) return null;

    // Generate page numbers
    const getPageNumbers = () => {
        const pages = [];
        if (totalPages <= 5) {
            for (let i = 1; i <= totalPages; i++) pages.push(i);
        } else {
            if (currentPage <= 3) {
                pages.push(1, 2, 3, 4, '...', totalPages);
            } else if (currentPage >= totalPages - 2) {
                pages.push(1, '...', totalPages - 3, totalPages - 2, totalPages - 1, totalPages);
            } else {
                pages.push(1, '...', currentPage - 1, currentPage, currentPage + 1, '...', totalPages);
            }
        }
        return pages;
    };

    return (
        <div style={{
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px', 
            marginTop: '40px', marginBottom: '20px', direction: 'rtl'
        }}>
            <button 
                onClick={() => onPageChange(currentPage - 1)}
                disabled={currentPage === 1}
                style={{
                    width: '40px', height: '40px', display: 'flex', alignItems: 'center', justifyContent: 'center',
                    borderRadius: '12px', border: '1.5px solid #e2e8f0', background: '#fff',
                    color: currentPage === 1 ? '#cbd5e1' : '#0f172a',
                    cursor: currentPage === 1 ? 'not-allowed' : 'pointer', transition: 'all 0.2s'
                }}
            ><ChevronRight size={18} /></button>

            <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                {getPageNumbers().map((num, i) => (
                    num === '...' ? (
                        <span key={i} style={{ padding: '0 8px', color: '#94a3b8', fontWeight: 'bold' }}>...</span>
                    ) : (
                        <button
                            key={i}
                            onClick={() => onPageChange(num)}
                            style={{
                                width: '40px', height: '40px', display: 'flex', alignItems: 'center', justifyContent: 'center',
                                borderRadius: '12px', border: num === currentPage ? 'none' : '1.5px solid #e2e8f0',
                                background: num === currentPage ? '#ea580c' : '#fff',
                                color: num === currentPage ? '#fff' : '#0f172a',
                                fontWeight: '800', fontSize: '14px', cursor: 'pointer', transition: 'all 0.2s'
                            }}
                        >{num}</button>
                    )
                ))}
            </div>

            <button 
                onClick={() => onPageChange(currentPage + 1)}
                disabled={currentPage === totalPages}
                style={{
                    width: '40px', height: '40px', display: 'flex', alignItems: 'center', justifyContent: 'center',
                    borderRadius: '12px', border: '1.5px solid #e2e8f0', background: '#fff',
                    color: currentPage === totalPages ? '#cbd5e1' : '#0f172a',
                    cursor: currentPage === totalPages ? 'not-allowed' : 'pointer', transition: 'all 0.2s'
                }}
            ><ChevronLeft size={18} /></button>
        </div>
    );
};

export default Pagination;
