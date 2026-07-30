import React, { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Upload, Image as ImageIcon, Loader2, AlertCircle, CheckCircle2, Check, DollarSign, Box, Tag, FileText, X, FolderOpen, PlusCircle, ChevronDown } from 'lucide-react';
import { createProduct, updateProduct, uploadMultipleImages, createCategory } from '@/services/supabase/inventoryService';

const ProductForm = ({ product, categories, onClose, onSaved, onRefreshCategories }) => {
    const [form, setForm] = useState({
        name: product?.name || '',
        description: product?.description || '',
        base_price: product?.base_price || '',
        discount: product?.discount || 0,
        stock_quantity: product?.stock_quantity || 0,
        category_ids: product?.category_ids || (product?.category_id ? [product?.category_id] : []),
        images: product?.images || [],
        is_featured: product?.is_featured || false,
    });
    const [formError, setFormError] = useState(null);

    const [selectedFiles, setSelectedFiles] = useState([]);
    const [previews, setPreviews] = useState(product?.images || []);
    const [saving, setSaving] = useState(false);
    const [uploading, setUploading] = useState(false);
    
    // Quick Add Category State
    const [showQuickAdd, setShowQuickAdd] = useState(false);
    const [newCatName, setNewCatName] = useState('');
    const [isCreatingCat, setIsCreatingCat] = useState(false);
    const dropdownRef = useRef(null);

    // Close dropdown when clicking outside
    useEffect(() => {
        const handleClickOutside = (event) => {
            if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
                setShowQuickAdd(false);
            }
        };

        if (showQuickAdd) {
            document.addEventListener('mousedown', handleClickOutside);
        } else {
            document.removeEventListener('mousedown', handleClickOutside);
        }

        return () => {
            document.removeEventListener('mousedown', handleClickOutside);
        };
    }, [showQuickAdd]);

    const handleFileChange = (e) => {
        const files = Array.from(e.target.files);
        if (files.length + previews.length > 5) {
            setFormError('الحد الأقصى هو 5 صور للمنتج الواحد');
            return;
        }

        setSelectedFiles(prev => [...prev, ...files]);
        const newPreviews = files.map(file => URL.createObjectURL(file));
        setPreviews(prev => [...prev, ...newPreviews]);
        setFormError(null);
    };

    const removeImage = (index) => {
        setPreviews(prev => prev.filter((_, i) => i !== index));
        setSelectedFiles(prev => prev.filter((_, i) => (i + (product?.images?.length || 0)) !== index));
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setFormError(null);
        setSaving(true);

        let finalImageUrls = previews.filter(p => p.startsWith('http'));

        if (selectedFiles.length > 0) {
            setUploading(true);
            const tempId = product?.id || `new-${Math.random().toString(36).substring(7)}`;
            const { urls, error: uploadErr } = await uploadMultipleImages(selectedFiles, tempId);
            if (uploadErr) console.warn('Upload error:', uploadErr);
            finalImageUrls = [...finalImageUrls, ...urls];
            setUploading(false);
        }

        const productData = {
            name: form.name.trim(),
            description: form.description.trim() || null,
            base_price: parseFloat(form.base_price) || 0,
            discount: parseInt(form.discount) || 0,
            stock_quantity: parseInt(form.stock_quantity) || 0,
            category_ids: form.category_ids,
            category_id: form.category_ids.length > 0 ? form.category_ids[0] : null, // Keep for backward compatibility
            images: finalImageUrls,
            is_featured: form.is_featured,
        };

        const result = product?.id 
            ? await updateProduct(product.id, productData)
            : await createProduct(productData);

        setSaving(false);

        if (result.error) {
            setFormError(`فشل الحفظ: ${result.error}`);
            return;
        }

        onSaved(product?.id ? 'تم تحديث المنتج بنجاح' : 'تم إضافة المنتج بنجاح');
    };

    const handleQuickAddCategory = async () => {
        if (!newCatName.trim()) return;
        setIsCreatingCat(true);
        const { data, error } = await createCategory({ name: newCatName.trim() });
        setIsCreatingCat(false);
        
        if (!error && data) {
            setForm(prev => ({ ...prev, category_ids: [...prev.category_ids, data.id] }));
            setNewCatName('');
            setShowQuickAdd(false);
            if (onRefreshCategories) await onRefreshCategories();
        }
    };

    // Helper to render hierarchical categories
    const renderHierarchicalCategories = () => {
        const parents = categories.filter(c => !c.parent_id);
        const children = (parentId) => categories.filter(c => c.parent_id === parentId);
        
        const items = [];
        parents.forEach(p => {
            items.push({ ...p, isParent: true });
            children(p.id).forEach(c => items.push({ ...c, isChild: true }));
        });
        
        // Add any categories that don't fit the parent/child logic (or are orphans)
        const orphanIds = categories.filter(c => c.parent_id && !categories.some(p => p.id === c.parent_id)).map(o => o.id);
        const processedIds = items.map(i => i.id);
        categories.filter(c => !processedIds.includes(c.id)).forEach(o => items.push(o));

        return items;
    };

    // Final Categories List (Server + Static Fallbacks)
    const getActiveCategories = () => {
        if (categories && categories.length > 0) return categories;
        
        // Return hardcoded fallbacks matching Navbar if DB is empty
        return [
            { id: 'paints', name: 'بويات' },
            { id: 'hardware', name: 'حدايد' },
            { id: 'decor', name: 'ديكور' },
            { id: 'adhesives', name: 'مواد لاصقة' },
            { id: 'daily-tools', name: 'عدد يدوية' }
        ];
    };

    const inputClasses = "w-full bg-slate-100/60 border-transparent rounded-[1.25rem] px-8 py-4 text-slate-900 text-sm focus:outline-none focus:ring-4 focus:ring-orange-500/10 focus:bg-white transition-all duration-500 placeholder:text-slate-400 font-medium shadow-inner active:scale-[0.99]";
    const labelClasses = "flex items-center gap-2 text-[10px] font-black text-slate-400 uppercase tracking-[0.2em] mb-3 mr-1";

    return (
        <form onSubmit={handleSubmit} className="grid grid-cols-1 lg:grid-cols-12 gap-6 sm:gap-8 relative">
            {/* Main Content Area */}
            <div className="lg:col-span-7 space-y-6">
                <div className="grid grid-cols-1 gap-6">
                    {/* Name */}
                    <div>
                        <label className={labelClasses}>
                            <Tag size={12} className="text-orange-500" /> اسم المنتج
                        </label>
                        <input 
                            required 
                            type="text" 
                            placeholder="مثلاً: ساعة يد ذكية Pro"
                            value={form.name} 
                            onChange={e => setForm({ ...form, name: e.target.value })}
                            className={inputClasses} 
                        />
                    </div>

                    {/* Description */}
                    <div>
                        <label className={labelClasses}>
                            <FileText size={12} className="text-orange-500" /> وصف المنتج
                        </label>
                        <textarea 
                            rows={4} 
                            placeholder="اكتب وصفاً تفصيلياً يشرح مميزات المنتج..."
                            value={form.description} 
                            onChange={e => setForm({ ...form, description: e.target.value })}
                            className={`${inputClasses} resize-none`} 
                        />
                    </div>
                </div>

                {/* Pricing & Stock Grid */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 p-6 bg-slate-50/30 rounded-[2.5rem] border border-slate-100/50">
                    <div>
                        <label className={labelClasses}>
                            <DollarSign size={12} className="text-green-600" /> السعر الأساسي
                        </label>
                        <div className="relative">
                            <input 
                                type="number" 
                                min="0" 
                                step="0.01" 
                                placeholder="0.00"
                                value={form.base_price} 
                                onChange={e => setForm({ ...form, base_price: e.target.value })}
                                className={`${inputClasses} pl-16`} 
                            />
                            <span className="absolute left-6 top-1/2 -translate-y-1/2 text-slate-400 font-bold text-xs uppercase">EGP</span>
                        </div>
                    </div>
                    
                    <div>
                        <label className={labelClasses}>
                            <Tag size={12} className="text-red-500" /> نسبة الخصم %
                        </label>
                        <input 
                            type="number" 
                            min="0" 
                            max="100" 
                            placeholder="خصم 0%"
                            value={form.discount} 
                            onChange={e => setForm({ ...form, discount: e.target.value })}
                            className={inputClasses} 
                        />
                    </div>

                    <div className="sm:col-span-2">
                        <label className={labelClasses}>
                            <Box size={12} className="text-blue-500" /> الكمية المتوفرة
                        </label>
                        <input 
                            type="number" 
                            min="0" 
                            placeholder="أدخل عدد الوحدات المتاحة"
                            value={form.stock_quantity} 
                            onChange={e => setForm({ ...form, stock_quantity: e.target.value })}
                            className={inputClasses} 
                        />
                    </div>
                </div>
            </div>

            {/* Sidebar Area (Category & Images) */}
            <div className="lg:col-span-5 space-y-8">
                {/* Categories & Featured */}
                <div className="space-y-4">
                    <div className="sm:col-span-2">
                        <label className={labelClasses}>
                            <Tag size={12} className="text-orange-500" /> تصنيف المنتج (كما في القائمة الرئيسية)
                        </label>
                        
                        <div className="relative" ref={dropdownRef}>
                            <button
                                type="button"
                                onClick={() => setShowQuickAdd(!showQuickAdd)}
                                className={`w-full bg-slate-100/60 rounded-[1.25rem] px-8 py-4 text-sm font-bold flex items-center justify-between transition-all border-2 ${showQuickAdd ? 'border-orange-200 bg-white shadow-sm' : 'border-transparent text-slate-500 hover:bg-white hover:border-slate-200'}`}
                            >
                                <span>{form.category_ids.length > 0 ? `تم اختيار ${form.category_ids.length} تصنيف` : 'اختر التصنيف من القائمة...'}</span>
                                <ChevronDown size={16} className={`transition-transform duration-300 ${showQuickAdd ? 'rotate-180' : ''}`} />
                            </button>

                            <AnimatePresence>
                                {showQuickAdd && (
                                    <motion.div 
                                        initial={{ opacity: 0, y: 10, scale: 0.95 }}
                                        animate={{ opacity: 1, y: 0, scale: 1 }}
                                        exit={{ opacity: 0, y: 10, scale: 0.95 }}
                                        className="absolute z-50 top-[110%] left-0 right-0 bg-white rounded-[1.5rem] shadow-2xl border border-slate-100 p-3 max-h-[300px] overflow-y-auto no-scrollbar"
                                    >
                                        <div className="grid grid-cols-1 gap-1">
                                            {getActiveCategories().map(cat => {
                                                const isSelected = form.category_ids.includes(cat.id);
                                                return (
                                                    <button
                                                        key={cat.id}
                                                        type="button"
                                                        onClick={() => {
                                                            const newIds = isSelected 
                                                                ? form.category_ids.filter(id => id !== cat.id)
                                                                : [...form.category_ids, cat.id];
                                                            setForm({ ...form, category_ids: newIds });
                                                        }}
                                                        className={`flex items-center justify-between p-3.5 rounded-xl transition-all duration-300 group
                                                            ${isSelected 
                                                                ? 'bg-orange-50 text-orange-600 font-black' 
                                                                : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
                                                            }`}
                                                    >
                                                        <div className="flex items-center gap-3">
                                                            <div className={`w-2 h-2 rounded-full ${isSelected ? 'bg-orange-500' : 'bg-slate-200'}`} />
                                                            <span className="text-sm">{cat.name}</span>
                                                        </div>
                                                        {isSelected && <CheckCircle2 size={16} className="text-orange-600" />}
                                                    </button>
                                                );
                                            })}
                                        </div>
                                    </motion.div>
                                )}
                            </AnimatePresence>
                        </div>
                    </div>

                    <div className="flex items-center justify-between p-4 bg-slate-50/50 rounded-2xl border border-slate-100">
                        <div className="flex gap-3">
                            <Box size={18} className="text-orange-500" />
                            <div>
                                <p className="text-xs font-black text-slate-800">منتج مميز (Featured)</p>
                                <p className="text-[10px] text-slate-500 leading-none mt-1">يظهر المنتج في الصفحة الرئيسية</p>
                            </div>
                        </div>
                        <button
                            type="button"
                            onClick={() => setForm({ ...form, is_featured: !form.is_featured })}
                            className={`w-12 h-6 rounded-full relative transition-colors duration-300 ${form.is_featured ? 'bg-orange-500' : 'bg-slate-200'}`}
                        >
                            <div className={`absolute top-1 w-4 h-4 rounded-full bg-white transition-all duration-300 ${form.is_featured ? 'right-7' : 'right-1'}`} />
                        </button>
                    </div>
                </div>

                {/* Images */}
                <div className="space-y-4">
                    <label className={labelClasses}>صور المنتج (الحد الأقصى 5)</label>
                    
                    <div className="grid grid-cols-3 gap-3">
                        {previews.map((src, i) => (
                            <div 
                                key={src + i}
                                className="relative aspect-square bg-white rounded-2xl overflow-hidden group border border-slate-200 shadow-sm"
                            >
                                <img src={src} alt="" className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110" />
                                <button
                                    type="button"
                                    onClick={() => removeImage(i)}
                                    className="absolute top-1.5 right-1.5 p-1.5 bg-white/90 text-red-600 rounded-xl opacity-0 group-hover:opacity-100 transition-all hover:bg-red-50 shadow-lg"
                                >
                                    <X size={14} />
                                </button>
                                {i === 0 && (
                                    <div className="absolute bottom-0 inset-x-0 bg-orange-600/95 text-[9px] text-white py-1 text-center font-black tracking-widest uppercase">الرئيسية</div>
                                )}
                            </div>
                        ))}

                        {previews.length < 5 && (
                            <label className="relative aspect-square bg-slate-50 border-2 border-dashed border-slate-200 rounded-2xl flex flex-col items-center justify-center cursor-pointer hover:bg-orange-50 hover:border-orange-200 transition-all duration-300 group">
                                <input type="file" multiple accept="image/*" onChange={handleFileChange} className="hidden" />
                                <div className="p-3 bg-white rounded-xl shadow-sm text-slate-400 group-hover:text-orange-500 transition-colors">
                                    <Upload size={20} />
                                </div>
                                <span className="text-[10px] font-black text-slate-400 group-hover:text-orange-500 mt-2">رفع صور</span>
                            </label>
                        )}
                    </div>

                    <div className="p-5 bg-orange-50/30 rounded-[2rem] border border-orange-100/50">
                        <div className="flex gap-3">
                            <ImageIcon size={18} className="text-orange-600 shrink-0" />
                            <div>
                                <p className="text-xs font-black text-orange-900">جودة الصور ترفع مبيعاتك</p>
                                <p className="text-[10px] text-orange-800/70 leading-relaxed mt-1">يُفضل استخدام خلفية بيضاء لصور المنتجات لتبدو احترافية.</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {/* Status Messages */}
            {formError && (
                <div className="lg:col-span-12 flex items-center gap-3 p-4 bg-red-50 border border-red-100 rounded-2xl">
                    <AlertCircle size={18} className="text-red-600 shrink-0" />
                    <p className="text-sm font-bold text-red-700">{formError}</p>
                </div>
            )}

            {/* Footer Actions */}
            <div className="lg:col-span-12 flex flex-col sm:flex-row gap-4 pt-6 border-t border-slate-100 mt-4">
                <button 
                    type="button" 
                    onClick={onClose}
                    className="flex-1 px-8 py-4 bg-slate-100/80 text-slate-500 rounded-full text-sm font-bold hover:bg-slate-200 hover:text-slate-900 transition-all active:scale-95 font-sans"
                >
                    إلغاء
                </button>
                <button 
                    type="submit" 
                    disabled={saving || uploading}
                    className={`flex-[2] px-8 py-4 rounded-full text-sm font-bold text-white shadow-xl shadow-orange-500/20 transition-all active:scale-95 flex items-center justify-center gap-3 font-sans
                        ${saving || uploading ? 'bg-orange-400 shadow-none' : 'bg-gradient-to-r from-orange-600 to-orange-500 hover:from-orange-500 hover:to-orange-400'}`}
                >
                    {(saving || uploading) ? (
                        <>
                            <Loader2 size={18} className="animate-spin" />
                            <span>{uploading ? 'جارٍ رفع الصور المميزة...' : 'جارٍ حفظ المنتج...'}</span>
                        </>
                    ) : (
                        <>
                            <CheckCircle2 size={18} />
                            <span>{product ? 'حفظ التعديلات النهائية' : 'إضافة المنتج للمتجر'}</span>
                        </>
                    )}
                </button>
            </div>
        </form>
    );
};

export default ProductForm;
