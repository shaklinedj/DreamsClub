import React, { useEffect, useState } from 'react';
import { collection, onSnapshot, doc, deleteDoc, orderBy, query } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { deleteFromDrive } from '../lib/google-drive';

interface FeedPost {
    id: string;
    title: string;
    description: string;
    mediaUrl: string;
    mediaType?: 'image' | 'video';
    postType?: string;
    createdAt: any;
    likesCount?: number;
    reactionsCount?: number;
    reactionCounts?: Record<string, number>;
    userReactions?: Record<string, string>;
    commentsCount: number;
    location?: string;
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

function extractYoutubeId(url: string): string | null {
    if (!url) return null;
    const trimmed = url.trim();
    const match = trimmed.match(/(?:v=|\/embed\/|\/v\/|\/shorts\/|\/live\/|youtu\.be\/)([\w-]{11})/);
    return match ? match[1] : null;
}

function formatDriveImageUrl(url: string): string {
    const fileId = getDriveFileId(url);
    if (fileId) return `https://lh3.googleusercontent.com/d/${fileId}`;
    return url ? url.trim() : '';
}

export default function FeedList() {
    const [posts, setPosts] = useState<FeedPost[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const q = query(collection(db, 'posts'), orderBy('createdAt', 'desc'));
        const unsubscribe = onSnapshot(q, (snapshot) => {
            const postsData = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            })) as FeedPost[];
            setPosts(postsData);
            setLoading(false);
        }, (error) => {
            console.error("Error reading posts:", error);
            setLoading(false);
        });

        return () => unsubscribe();
    }, []);

    const handleDelete = async (post: FeedPost) => {
        if (confirm('¿Estás seguro de que quieres eliminar esta publicación?')) {
            try {
                if (post.mediaUrl) {
                    try {
                        await deleteFromDrive(post.mediaUrl);
                    } catch (driveError) {
                        console.warn("Error deleting media from Google Drive:", driveError);
                    }
                }
                await deleteDoc(doc(db, 'posts', post.id));
            } catch (error) {
                console.error("Error deleting post:", error);
                alert("Error al eliminar la publicación");
            }
        }
    };

    if (loading) return <div className="text-white text-center p-10">Cargando publicaciones...</div>;

    if (posts.length === 0) return (
        <div className="text-slate-400 text-center p-12 bg-slate-800/50 rounded-2xl border border-slate-700">
            <p className="text-lg font-medium text-slate-300">No hay publicaciones todavía.</p>
            <p className="text-sm text-slate-500 mt-1">Crea la primera publicación usando el botón "Nueva Publicación".</p>
        </div>
    );

    return (
        <div className="space-y-6">
            {posts.map((post) => {
                const driveFileId = getDriveFileId(post.mediaUrl);
                const isDriveVideo = post.mediaType === 'video' && driveFileId !== null;
                const youtubeId = extractYoutubeId(post.mediaUrl);

                return (
                    <div key={post.id} className="bg-slate-800 rounded-2xl border border-slate-700 overflow-hidden flex flex-col md:flex-row gap-6 p-6 hover:border-slate-600 transition-colors">
                        {/* Media Preview */}
                        <div className="w-full md:w-56 h-48 md:h-auto shrink-0 rounded-xl overflow-hidden bg-slate-900 border border-slate-700 relative flex items-center justify-center">
                            {post.mediaUrl ? (
                                youtubeId ? (
                                    <iframe 
                                        src={`https://www.youtube.com/embed/${youtubeId}`} 
                                        className="w-full h-full min-h-[180px] border-0" 
                                        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" 
                                        allowFullScreen 
                                    />
                                ) : post.mediaType === 'video' ? (
                                    <video 
                                        src={isDriveVideo ? `https://drive.google.com/uc?export=download&id=${driveFileId}` : post.mediaUrl} 
                                        controls 
                                        className="w-full h-full object-cover min-h-[180px]"
                                    />
                                ) : (
                                    <img 
                                        src={formatDriveImageUrl(post.mediaUrl)} 
                                        alt={post.title} 
                                        className="w-full h-full object-cover"
                                        onError={(e) => {
                                            const target = e.target as HTMLImageElement;
                                            target.style.display = 'none';
                                            target.parentElement!.innerHTML = '<div class="w-full h-full flex items-center justify-center text-slate-600 text-xs p-2 text-center">⚠️ No se pudo cargar la imagen</div>';
                                        }}
                                    />
                                )
                            ) : (
                                <div className="w-full h-full flex items-center justify-center text-slate-600 text-sm">
                                    Sin imagen/video
                                </div>
                            )}
                            {post.mediaType === 'video' && !youtubeId && (
                                <span className="absolute top-2 left-2 bg-black/70 text-purple-300 text-xs px-2 py-0.5 rounded font-bold backdrop-blur-sm pointer-events-none">
                                    🎬 Video
                                </span>
                            )}
                        </div>

                    {/* Content */}
                    <div className="flex-1">
                        <div className="flex flex-wrap items-center gap-2 mb-2">
                            {post.postType && (
                                <span className="text-xs px-2.5 py-0.5 rounded-full bg-purple-900/50 text-purple-300 border border-purple-700/50 font-semibold uppercase">
                                    {post.postType === 'news' ? 'Noticia' : post.postType === 'event' ? 'Evento' : 'Promoción'}
                                </span>
                            )}
                            <span className="text-xs text-slate-400">
                                📍 {post.location || 'Dreams Coyhaique'}
                            </span>
                            <span className="text-xs text-slate-500">
                                • {post.createdAt?.toDate ? post.createdAt.toDate().toLocaleString() : 'Reciente'}
                            </span>
                        </div>

                        <h3 className="font-bold text-white text-xl mb-2">{post.title || 'Sin título'}</h3>
                        <p className="text-slate-300 text-sm mb-4 line-clamp-3 leading-relaxed">{post.description}</p>

                        <div className="flex items-center gap-6 text-sm">
                            <span className="flex items-center gap-1.5 text-rose-400 font-medium bg-rose-500/10 px-3 py-1 rounded-lg border border-rose-500/20">
                                ❤️ {(post.reactionsCount ?? (post.userReactions ? Object.keys(post.userReactions).length : post.likesCount)) || 0} Reacciones
                            </span>
                            <span className="flex items-center gap-1.5 text-blue-400 font-medium bg-blue-500/10 px-3 py-1 rounded-lg border border-blue-500/20">
                                💬 {post.commentsCount || 0} Comentarios
                            </span>
                        </div>
                    </div>

                    {/* Actions */}
                    <div className="flex md:flex-col gap-2 justify-center border-t md:border-t-0 md:border-l border-slate-700 pt-4 md:pt-0 md:pl-6">
                        <a
                            href={`/feed/detail?id=${post.id}`}
                            className="px-4 py-2 bg-purple-600/20 hover:bg-purple-600 text-purple-300 hover:text-white border border-purple-500/30 rounded-lg text-sm font-semibold transition-colors text-center"
                        >
                            Ver Interacciones
                        </a>
                        <div className="flex gap-2">
                            <button
                                onClick={() => handleDelete(post)}
                                className="flex-1 bg-rose-500/10 text-rose-400 hover:bg-rose-500 hover:text-white px-4 py-2 rounded-lg font-semibold text-sm transition-colors border border-rose-500/20 cursor-pointer"
                            >
                                Eliminar
                            </button>
                        </div>
                    </div>
                </div>
            );
        })}
    </div>
);
}
