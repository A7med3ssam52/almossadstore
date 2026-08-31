import React, { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import {
    DollarSign,
    ShoppingBag,
    Users,
    ArrowUpRight,
    Plus,
    Loader2
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import StatsCard from '@/components/Admin/Stats/StatsCard';
import SalesChart from '@/components/Admin/Stats/SalesChart';
import QuickActions from '@/components/Admin/Dashboard/QuickActions';
import { Button } from "@/components/ui/button";
import { getDashboardMetrics, getSalesChartData } from '@/services/supabase/metrics';

/**
 * Admin Dashboard Overview Page
 * Primary landing page for store administrators featuring stats and sales performance.
 */
const Dashboard = () => {
    const navigate = useNavigate();
    const [loading, setLoading] = useState(true);
    const [metrics, setMetrics] = useState(null);
    const [chartData, setChartData] = useState([]);
    const [chartDays, setChartDays] = useState(7);

    useEffect(() => {
        const loadDashboardData = async () => {
            try {
                const [metricsData, salesData] = await Promise.all([
                    getDashboardMetrics(),
                    getSalesChartData(chartDays)
                ]);
                setMetrics(metricsData);
                setChartData(salesData);
            } catch (error) {
                console.error("Error loading dashboard data:", error);
                // Set fallback metrics
                setMetrics({
                    totalSales: "0 ج.م",
                    orderCount: 0,
                    userCount: 0,
                    conversionRate: "0%",
                    trends: { sales: '0%', orders: '0%', users: '0%', conversion: '0%' }
                });
            } finally {
                setLoading(false);
            }
        };
        loadDashboardData();
    }, [chartDays]);

    if (loading) {
        return (
            <div className="h-[60vh] flex flex-col items-center justify-center gap-4">
                <Loader2 className="animate-spin text-slate-400" size={40} />
                <p className="text-slate-500 font-bold tracking-widest uppercase text-[10px]">Loading Dashboard...</p>
            </div>
        );
    }

    // Default targets for progress visualization (can be made dynamic later)
    const salesTarget = 10000;
    const ordersTarget = 50;
    const usersTarget = 100;
    const conversionTarget = 5;

    const totalSalesNum = parseFloat(metrics?.totalSales?.replace(/,/g, '').replace(' ج.م', '')) || 0;

    return (
        <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="space-y-12 pb-12"
        >
            {/* Header / Page Title with Date & Actions */}
            <header className="flex flex-col lg:flex-row lg:items-center justify-between gap-6">
                <div className="flex flex-col gap-2">
                    <h1 className="text-4xl md:text-5xl font-black text-slate-900 tracking-tighter leading-none shadow-sm pr-4 border-r-4 border-[#1F2933] transition-colors duration-300">
                        لوحة المؤشرات
                    </h1>
                    <p className="text-slate-500 text-[11px] font-black tracking-widest uppercase flex items-center gap-2 pr-5">
                        <span className="w-2.5 h-2.5 bg-green-500 rounded-full animate-pulse shadow-[0_0_10px_rgba(34,197,94,0.2)]"></span>
                        نظام التشغيل الآن: نشط (Live Updates)
                    </p>
                </div>

                {/* Action Controls */}
                <div className="flex items-center gap-3">
                    <Button 
                        onClick={() => navigate('/admin/products')}
                        className="bg-slate-900 hover:bg-slate-800 text-white font-bold rounded-2xl px-6 py-6 shadow-lg shadow-slate-900/20 group transition-all duration-300"
                    >
                        <Plus size={18} className="ml-2 group-hover:rotate-90 transition-transform duration-300" />
                        إضافة منتج جديد
                    </Button>
                </div>
            </header>

            {/* Stats Grid - 4 Columns Responsive */}
            <section className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8 overflow-visible">
                <StatsCard
                    title="مبيعات الشهر الحالى"
                    value={metrics?.totalSales}
                    icon={<DollarSign size={24} />}
                    trend={metrics?.trends.sales.startsWith('+') ? 'up' : 'down'}
                    trendValue={metrics?.trends.sales}
                    color="orange"
                    progress={Math.min((totalSalesNum / salesTarget) * 100, 100) || 0}
                    targetLabel="Target 80%"
                />
                <StatsCard
                    title="طلبات جديدة"
                    value={metrics?.orderCount}
                    icon={<ShoppingBag size={24} />}
                    trend={metrics?.trends.orders.startsWith('+') ? 'up' : 'down'}
                    trendValue={metrics?.trends.orders}
                    color="blue"
                    progress={Math.min((metrics?.orderCount / ordersTarget) * 100, 100) || 0}
                    targetLabel="Target 80%"
                />
                <StatsCard
                    title="عدد المستخدمين"
                    value={metrics?.userCount}
                    icon={<Users size={24} />}
                    trend={metrics?.trends.users.startsWith('+') ? 'up' : 'down'}
                    trendValue={metrics?.trends.users}
                    color="orange"
                    progress={Math.min((metrics?.userCount / usersTarget) * 100, 100) || 0}
                    targetLabel="Target 80%"
                />
                <StatsCard
                    title="نسبة التحويل"
                    value={metrics?.conversionRate}
                    icon={<ArrowUpRight size={24} />}
                    trend={metrics?.trends.conversion.startsWith('+') ? 'up' : 'down'}
                    trendValue={metrics?.trends.conversion}
                    color="blue"
                    progress={Math.min((parseFloat(metrics?.conversionRate) / conversionTarget) * 100, 100) || 0}
                    targetLabel="Target 80%"
                />
            </section>

            {/* Main Content Area - Chart & Recent Activity */}
            <section className="grid grid-cols-1 gap-12 overflow-visible">

                {/* Sales Performance Chart (100% width) */}
                <div className="relative group">
                    <SalesChart 
                        data={chartData} 
                        activeDays={chartDays} 
                        onTimeframeChange={setChartDays} 
                    />
                    {/* Subtle Accent Glow */}
                    <div className="absolute inset-0 bg-[#1F2933]/[0.03] blur-[100px] rounded-[3rem] opacity-0 group-hover:opacity-100 transition-opacity duration-1000 -z-10"></div>
                </div>

                {/* Secondary Info Grid - Orders / Inventory / Alerts */}
                <QuickActions />

            </section>

        </motion.div>
    );
};

export default Dashboard;

