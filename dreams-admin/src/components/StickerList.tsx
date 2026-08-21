import React, { useEffect, useState } from 'react';
import { collection, onSnapshot, doc, deleteDoc, orderBy, query } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { deleteFromDrive } from '../lib/google-drive';

interface StickerPost {
    id: string;
    name: string;
    url: string;
    requiredStreak?: number;
    createdAt: any;
}

/** Convierte URLs de Google Drive a formato embebible */
function getDriveFileId(url: string): string | null {
    if (!url) return null;
    const trimmed = url.trim();
    const match = trimmed.match(/\/file\/d\/([a-zA-Z0-9_-]+)/) ||
                  trimmed.match(/id=([a-zA-Z0-9_-]+)/) ||
                  trimmed.match(/\/d\/([a-zA-Z0-9_-]+)/);
    return match ? match[1] : null;
}

function formatDriveImageUrl(url: string): string {
    const fileId = getDriveFileId(url);
    if (fileId) return `https://lh3.googleusercontent.com/d/${fileId}`;
    return url ? url.trim() : '';
}

export default function StickerList() {
    const [stickers, setStickers] = useState<StickerPost[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const q = query(collection(db, 'stickers'), orderBy('createdAt', 'desc'));
        const unsubscribe = onSnapshot(q, (snapshot) => {
            const data = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            })) as StickerPost[];
            setStickers(data);
            setLoading(false);
        }, (error) => {
            console.error("Error reading stickers:", error);
            setLoading(false);
        });

        return () => unsubscribe();
    }, []);

    const handleDelete = async (sticker: StickerPost) => {
        if (confirm('¿Estás seguro de que quieres eliminar este sticker?')) {
            try {
                if (sticker.url) {
                    await deleteFromDrive(sticker.url).catch(() => console.warn("No se pudo borrar de Drive"));
                }
                await deleteDoc(doc(db, 'stickers', sticker.id));
            } catch (error) {
                console.error("Error deleting sticker:", error);
                alert("Error al eliminar el sticker");
            }
        }
    };

    if (loading) return <div className="text-white text-center p-10">Cargando stickers...</div>;

    if (stickers.length === 0) return (
        <div className="text-slate-400 text-center p-12 bg-slate-800/50 rounded-2xl border border-slate-700">
            <p className="text-lg font-medium text-slate-300">No hay stickers todavía.</p>
            <p className="text-sm text-slate-500 mt-1">Sube el primer sticker usando el formulario.</p>
        </div>
    );

    return (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
            {stickers.map((sticker) => {
                const formattedUrl = formatDriveImageUrl(sticker.url);
                const streak = sticker.requiredStreak ?? 0;

                let streakBadge = { label: '🌐 Todos', bg: 'bg-slate-700', text: 'text-slate-300' };
                if (streak >= 28) streakBadge = { label: '💎 Leyenda (28d)', bg: 'bg-cyan-500/20', text: 'text-cyan-300' };
                else if (streak >= 21) streakBadge = { label: '🪙 Diamante (21d)', bg: 'bg-purple-500/20', text: 'text-purple-300' };
                else if (streak >= 14) streakBadge = { label: '🥇 Platino (14d)', bg: 'bg-amber-500/20', text: 'text-amber-300' };
                else if (streak >= 7) streakBadge = { label: '🥈 Oro (7d)', bg: 'bg-zinc-500/20', text: 'text-zinc-300' };
                else if (streak >= 3) streakBadge = { label: '🥉 Plata (3d)', bg: 'bg-orange-500/20', text: 'text-orange-300' };
                else if (streak >= 1) streakBadge = { label: '🏔️ Bronce (1d)', bg: 'bg-emerald-500/20', text: 'text-emerald-300' };

                return (
                    <div key={sticker.id} className="bg-slate-800 rounded-2xl border border-slate-700 overflow-hidden flex flex-col hover:border-slate-500 transition-colors">
                        <div className="h-40 w-full bg-slate-900 flex items-center justify-center p-4 relative">
                            {formattedUrl ? (
                                <img 
                                    src={formattedUrl} 
                                    alt={sticker.name} 
                                    className="w-full h-full object-contain"
                                    onError={(e) => {
                                        (e.target as HTMLImageElement).src = 'https://via.placeholder.com/150?text=Error+Imagen';
                                    }}
                                />
                            ) : (
                                <span className="text-slate-500">Sin imagen</span>
                            )}
                            {/* Streak badge overlay */}
                            <span className={`absolute top-2 left-2 text-xs font-bold px-2 py-1 rounded-full ${streakBadge.bg} ${streakBadge.text}`}>
                                {streakBadge.label}
                            </span>
                        </div>
                        <div className="p-4 flex-1 flex flex-col justify-between">
                            <h3 className="text-white font-medium mb-1 truncate" title={sticker.name}>
                                {sticker.name}
                            </h3>
                            <p className="text-xs text-slate-400 mb-4 truncate">
                                {new Date(sticker.createdAt?.seconds * 1000).toLocaleDateString()}
                            </p>
                            
                            <button 
                                onClick={() => handleDelete(sticker)}
                                className="w-full py-2 px-3 rounded-lg bg-red-500/10 hover:bg-red-500/20 text-red-400 text-sm font-medium transition-colors flex justify-center items-center gap-2"
                            >
                                <span>🗑️</span> Eliminar
                            </button>
                        </div>
                    </div>
                );
            })}
        </div>
    );
}
