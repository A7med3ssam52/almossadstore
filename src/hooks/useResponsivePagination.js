import { useState, useEffect } from 'react';

export const useResponsivePagination = (desktopLimit = 12, mobileLimit = 10) => {
    const [currentPage, setCurrentPage] = useState(1);
    const [itemsPerPage, setItemsPerPage] = useState(desktopLimit);

    useEffect(() => {
        const handleResize = () => {
            const isMobile = window.innerWidth < 768;
            setItemsPerPage(isMobile ? mobileLimit : desktopLimit);
        };
        handleResize(); // Init on mount
        
        window.addEventListener('resize', handleResize);
        return () => window.removeEventListener('resize', handleResize);
    }, [desktopLimit, mobileLimit]);

    return {
        currentPage,
        setCurrentPage,
        itemsPerPage
    };
};
