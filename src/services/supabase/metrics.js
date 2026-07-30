import { supabase } from './adminClient';

/**
 * Metrics Service
 * Responsible for fetching aggregate statistical data for the admin dashboard.
 * Currently uses mock data logic or direct Supabase queries.
 */

export const getDashboardMetrics = async () => {
    try {
        const now = new Date();
        const firstDayOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();

        // 1. Fetch Total Sales (Current Month)
        const { data: salesData, error: salesError } = await supabase
            .from('orders')
            .select('total_amount')
            .gte('created_at', firstDayOfMonth)
            .neq('status', 'cancelled');

        if (salesError) throw salesError;
        const totalSales = salesData?.reduce((acc, curr) => acc + Number(curr.total_amount), 0) || 0;

        // 2. Fetch Order Count (Current Month)
        const { count: orderCount, error: countError } = await supabase
            .from('orders')
            .select('*', { count: 'exact', head: true })
            .gte('created_at', firstDayOfMonth)
            .neq('status', 'cancelled');

        if (countError) throw countError;

        // 3. Fetch User Count (Total Profiles)
        const { count: userCount, error: userError } = await supabase
            .from('profiles')
            .select('*', { count: 'exact', head: true });

        if (userError) throw userError;

        // 4. Calculate Conversion Rate (Orders/Users)
        const conversionRate = userCount > 0 ? ((orderCount / userCount) * 100).toFixed(2) : 0;

        // 5. Mock trends for now (could be compared to previous month in future)
        const trends = {
            sales: totalSales > 0 ? '+15.2%' : '0%',
            orders: orderCount > 0 ? '+8.5%' : '0%',
            users: userCount > 0 ? '+12.1%' : '0%',
            conversion: '+0.4%'
        };

        return {
            totalSales: `${totalSales.toLocaleString()} ج.م`,
            orderCount: orderCount || 0,
            userCount: userCount || 0,
            conversionRate: `${conversionRate}%`,
            trends
        };
    } catch (error) {
        console.warn('Supabase error or unreachable, using default values:', error);
        return {
            totalSales: "0 ج.م",
            orderCount: 0,
            userCount: 0,
            conversionRate: "0%",
            trends: { sales: '0%', orders: '0%', users: '0%', conversion: '0%' }
        };
    }
};

/**
 * Fetch and aggregate sales data for charts (Weekly/Monthly)
 */
export const getSalesChartData = async (days = 7) => {
    try {
        const now = new Date();
        const startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - days + 1);
        startDate.setHours(0, 0, 0, 0);

        const { data: salesData, error } = await supabase
            .from('orders')
            .select('total_amount, created_at')
            .gte('created_at', startDate.toISOString())
            .neq('status', 'cancelled')
            .order('created_at', { ascending: true });

        if (error) throw error;

        // Create a map of dates in the range
        const dataMap = {};
        for (let i = 0; i < days; i++) {
            const date = new Date(startDate);
            date.setDate(startDate.getDate() + i);
            const dateStr = date.toISOString().split('T')[0];
            
            // Format name based on timeframe
            const name = days <= 7 
                ? getArabicDayName(date.getDay()) 
                : `${date.getDate()}/${date.getMonth() + 1}`;

            dataMap[dateStr] = { name, sales: 0, revenue: 0 };
        }

        // Aggregate real data
        salesData?.forEach(order => {
            const dateStr = new Date(order.created_at).toISOString().split('T')[0];
            if (dataMap[dateStr]) {
                dataMap[dateStr].sales += 1;
                dataMap[dateStr].revenue += Number(order.total_amount);
            }
        });

        return Object.values(dataMap);
    } catch (error) {
        console.error('Error fetching chart data:', error);
        return [];
    }
};

/**
 * Helper to get Arabic Day Name
 */
function getArabicDayName(dayIndex) {
    const days = ['الأحد', 'الأثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    return days[dayIndex];
}

/**
 * Fetch Recent Orders for the Quick Actions Feed.
 */
export const getRecentOrders = async (limit = 5) => {
    const { data, error } = await supabase
        .from('orders')
        .select(`
      id,
      customer_id,
      total_amount,
      status,
      created_at,
      profiles (
        full_name
      )
    `)
        .order('created_at', { ascending: false })
        .limit(limit);

    if (error) {
        console.error('Error fetching recent orders:', error);
        return [];
    }

    return data.map(order => ({
        id: `#ORD-${order.id.slice(0, 4).toUpperCase()}`,
        customer: order.profiles?.full_name || 'عميل مجهول',
        total: `${Number(order.total_amount).toLocaleString()} ج.م`,
        status: order.status,
        time: formatArabicRelativeTime(new Date(order.created_at))
    }));
};

/**
 * Helper to format relative time in Arabic (Simple implementation)
 */
function formatArabicRelativeTime(date) {
    const diff = Date.now() - date.getTime();
    const minutes = Math.floor(diff / 60000);
    if (minutes < 1) return 'الآن';
    if (minutes < 60) return `منذ ${minutes} دقيقة`;
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `منذ ${hours} ساعة`;
    return date.toLocaleDateString('ar-SA');
}
