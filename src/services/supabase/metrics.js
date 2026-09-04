import { supabase } from './adminClient';

export const getDashboardMetrics = async () => {
    try {
        const now = new Date();
        const firstDayOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();
        const firstDayPrevMonth = new Date(now.getFullYear(), now.getMonth()-1, 1).toISOString();
        const lastDayPrevMonth = new Date(now.getFullYear(), now.getMonth(), 0).toISOString();

        // Only completed/paid orders count as sales (fix logical error)
        const salesStatuses = ['completed','paid','processing']; // processing counts as revenue but not pending/cancelled
        // 1. Current month sales
        const { data: salesData, error: salesError } = await supabase
            .from('orders')
            .select('total_amount, status')
            .gte('created_at', firstDayOfMonth)
            .in('status', salesStatuses);
        if (salesError) throw salesError;
        const totalSales = salesData?.reduce((acc, curr) => acc + Number(curr.total_amount), 0) || 0;

        // 2. Order counts
        const { count: orderCount } = await supabase.from('orders').select('*', { count: 'exact', head: true }).gte('created_at', firstDayOfMonth).in('status', salesStatuses);
        const { count: prevOrderCount } = await supabase.from('orders').select('*', { count: 'exact', head: true }).gte('created_at', firstDayPrevMonth).lte('created_at', lastDayPrevMonth).in('status', salesStatuses);
        const { data: prevSalesData } = await supabase.from('orders').select('total_amount').gte('created_at', firstDayPrevMonth).lte('created_at', lastDayPrevMonth).in('status', salesStatuses);
        const prevTotalSales = prevSalesData?.reduce((acc,c)=>acc+Number(c.total_amount),0)||0;

        // 3. User count
        const { count: userCount } = await supabase.from('profiles').select('*', { count: 'exact', head: true });
        const { count: prevUserCount } = await supabase.from('profiles').select('*', { count: 'exact', head: true }).lte('created_at', lastDayPrevMonth);

        const conversionRate = userCount > 0 ? ((orderCount / userCount) * 100).toFixed(2) : 0;

        const calcTrend = (curr, prev) => {
            if (!prev || prev===0) return curr>0 ? '+100%' : '0%';
            const pct = ((curr - prev)/prev*100).toFixed(1);
            return (pct>=0?'+':'')+pct+'%';
        };

        const trends = {
            sales: calcTrend(totalSales, prevTotalSales),
            orders: calcTrend(orderCount||0, prevOrderCount||0),
            users: calcTrend(userCount||0, prevUserCount||0),
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
        console.warn('Supabase error:', error);
        return {
            totalSales: "0 ج.م",
            orderCount: 0,
            userCount: 0,
            conversionRate: "0%",
            trends: { sales: '0%', orders: '0%', users: '0%', conversion: '0%' }
        };
    }
};

export const getSalesChartData = async (days = 7) => {
    try {
        const now = new Date();
        const startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - days + 1);
        startDate.setHours(0, 0, 0, 0);
        const { data: salesData, error } = await supabase
            .from('orders')
            .select('total_amount, created_at')
            .gte('created_at', startDate.toISOString())
            .in('status', ['completed','paid','processing'])
            .order('created_at', { ascending: true });
        if (error) throw error;
        const dataMap = {};
        for (let i = 0; i < days; i++) {
            const date = new Date(startDate);
            date.setDate(startDate.getDate() + i);
            const dateStr = date.toISOString().split('T')[0];
            const name = days <= 7 ? getArabicDayName(date.getDay()) : `${date.getDate()}/${date.getMonth() + 1}`;
            dataMap[dateStr] = { name, sales: 0, revenue: 0 };
        }
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

function getArabicDayName(dayIndex) {
    const days = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    return days[dayIndex];
}

export const getRecentOrders = async (limit = 5) => {
    // Fix: column is user_id not customer_id, join profiles correctly
    const { data, error } = await supabase
        .from('orders')
        .select(`
      id,
      user_id,
      total_amount,
      status,
      created_at,
      customer_name,
      profiles ( full_name )
    `)
        .order('created_at', { ascending: false })
        .limit(limit);
    if (error) {
        console.error('Error fetching recent orders:', error);
        return [];
    }
    return data.map(order => ({
        id: `#ORD-${order.id.slice(0, 4).toUpperCase()}`,
        rawId: order.id,
        customer: order.profiles?.full_name || order.customer_name || 'زبون',
        total: `${Number(order.total_amount).toLocaleString()} ج.م`,
        status: order.status,
        time: formatArabicRelativeTime(new Date(order.created_at))
    }));
};

function formatArabicRelativeTime(date) {
    const diff = Date.now() - date.getTime();
    const minutes = Math.floor(diff / 60000);
    if (minutes < 1) return 'الآن';
    if (minutes < 60) return `منذ ${minutes} دقيقة`;
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `منذ ${hours} ساعة`;
    return date.toLocaleDateString('ar-SA');
}