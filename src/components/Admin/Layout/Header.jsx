import React, { useEffect, useState } from 'react';
import {
    Bell,
    Search,
    User as UserIcon,
    Settings as SettingsIcon,
    Maximize2,
    ExternalLink,
    ChevronDown,
    Menu
} from 'lucide-react';
import { supabase } from '@/services/supabase/adminClient';

const Header = ({ onMenuClick }) => {
    const [adminName, setAdminName] = useState('مدير المتجر');
    const [showNotifications, setShowNotifications] = useState(false);
    const [isFullScreen, setIsFullScreen] = useState(false);

    useEffect(() => {
        const fetchAdminProfile = async () => {
            const { data: { user } } = await supabase.auth.getUser();
            if (user?.raw_user_meta_data?.full_name) {
                setAdminName(user.raw_user_meta_data.full_name);
            }
        };
        fetchAdminProfile();
    }, []);

    const toggleFullScreen = () => {
        try {
            if (!document.fullscreenElement) {
                document.documentElement.requestFullscreen();
                setIsFullScreen(true);
            } else if (document.exitFullscreen) {
                document.exitFullscreen();
                setIsFullScreen(false);
            }
        } catch (e) { console.log('Fullscreen error', e); }
    };

    return (
        <header className="h-20 bg-white/80 backdrop-blur-xl border-b border-slate-200 flex items-center justify-between px-4 md:px-8 lg:px-12 z-40 transition-all duration-500 shadow-sm shrink-0">

            <div className="flex items-center gap-3">
                {/* Mobile Menu Trigger */}
                <button
                    onClick={onMenuClick}
                    className="lg:hidden p-2.5 text-slate-400 hover:text-slate-900 hover:bg-slate-100 rounded-xl transition-all"
                >
                    <Menu size={20} />
                </button>

                {/* Search Bar - Hidden on very small mobile, compact on medium */}
                <div className="relative group max-w-[200px] md:max-w-md w-full ml-auto hidden sm:block">
                    <div className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-[#3A3F45] transition-colors duration-300 pointer-events-none">
                        <Search size={18} />
                    </div>
                    <input
                        type="text"
                        placeholder="بحث..."
                        className="w-full h-11 bg-slate-100/40 border-none rounded-2xl pr-12 pl-4 text-sm text-slate-900 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-[#3A3F45]/20 focus:bg-white transition-all duration-300 tracking-wide font-sans md:placeholder:content-['...'] shadow-sm"
                    />
                </div>
            </div>

            {/* Action Icons Section */}
            <div className="flex items-center gap-2 md:gap-4 pr-4 md:pr-8 border-r border-slate-200 h-10">

                {/* Full Screen - Hidden on mobile */}
                <button
                    onClick={toggleFullScreen}
                    className="hidden md:flex p-2.5 text-slate-400 hover:text-slate-900 hover:bg-slate-100 rounded-xl transition-all duration-300 group relative"
                >
                    <Maximize2 size={18} />
                </button>

                {/* Live Site Link - Icon only on small mobile */}
                <a
                    href="/"
                    target="_blank"
                    className="p-2.5 text-slate-400 hover:text-[#1F2933] hover:bg-slate-100 rounded-xl transition-all duration-300 group"
                >
                    <ExternalLink size={18} />
                </a>

                {/* Notifications */}
                <div className="relative">
                    <button className="p-2.5 text-slate-400 hover:text-[#1F2933] hover:bg-slate-100 rounded-xl transition-all duration-300 group relative">
                        <Bell size={18} />
                        <span className="absolute top-2.5 right-2.5 w-2 h-2 bg-[#1F2933] border-2 border-white rounded-full animate-pulse shadow-glow"></span>
                    </button>
                </div>

                {/* Admin User Profile - More compact on mobile */}
                <div className="flex items-center gap-2 md:gap-3 pr-2 md:pr-4 border-r border-slate-200 h-8 md:h-10 select-none group/user cursor-pointer">
                    <div className="flex flex-col text-left hidden md:flex">
                        <span className="text-[13px] font-black text-slate-900 leading-none tracking-tight font-sans transition-colors group-hover/user:text-[#1F2933]">{adminName}</span>
                        <span className="text-[10px] font-bold text-slate-500 uppercase tracking-widest mt-1">Administrator</span>
                    </div>
                    <div className="w-8 h-8 md:w-10 md:h-10 bg-gradient-to-br from-[#1F2933] to-[#3A3F45] rounded-lg md:rounded-xl flex items-center justify-center shadow-lg shadow-[#1F2933]/20 transition-transform duration-300 overflow-hidden shrink-0">
                        <UserIcon size={18} className="text-white md:size-[20px]" />
                    </div>
                </div>
            </div>

        </header>
    );
};

export default Header;

