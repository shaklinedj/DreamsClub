import React, { useEffect, useState } from 'react';
import { doc, collection, onSnapshot, orderBy, query, deleteDoc } from 'firebase/firestore';
import { db } from '../lib/firebase';

interface CommentItem {
    id: string;
    userId: string;
    userName?: string;
    userAvatar?: string;
    text: string;
    createdAt: any;
}

interface LikeItem {
    id: string;
    userId: string;
    userName?: string;
    reactionType?: string;
    createdAt: any;
}

interface PostDetail {
    title: string;
    description: string;
    mediaUrl: string;
    mediaType?: string;
    likesCount?: number;
    reactionsCount?: number;
    reactionCounts?: Record<string, number>;
    commentsCount: number;
    createdAt: any;
}

function extractYoutubeId(url: string): string | null {
    if (!url) return null;
    const trimmed = url.trim();
    const match = trimmed.match(/(?:v=|\/embed\/|\/v\/|\/shorts\/|\/live\/|youtu\.be\/)([\w-]{11})/);
    return match ? match[1] : null;
}

export default function PostInteractions({ postId: propPostId }: { postId?: string }) {
    const [currentPostId, setCurrentPostId] = useState<string>(propPostId || '');
    const [post, setPost] = useState<PostDetail | null>(null);
    const [comments, setComments] = useState<CommentItem[]>([]);
    const [likes, setLikes] = useState<LikeItem[]>([]);
    const [activeTab, setActiveTab] = useState<'comments' | 'likes'>('comments');
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        let activeId = propPostId;
        if (!activeId && typeof window !== 'undefined') {
            const params = new URLSearchParams(window.location.search);
            activeId = params.get('id') || '';
        }
        setCurrentPostId(activeId || '');

        if (!activeId) {
            setLoading(false);
            return;
        }

        // 1. Post details
        const unsubPost = onSnapshot(doc(db, 'posts', activeId), (docSnap) => {
            if (docSnap.exists()) {
                setPost(docSnap.data() as PostDetail);
            }
        });

        // 2. Comments subcollection
        const commentsQ = query(collection(db, 'posts', activeId, 'comments'), orderBy('createdAt', 'desc'));
        const unsubComments = onSnapshot(commentsQ, (snap) => {
            const list = snap.docs.map(d => ({
                id: d.id,
                ...d.data()
            })) as CommentItem[];
            setComments(list);
            setLoading(false);
        }, (err) => {
            console.warn("Comments query error:", err);
            setLoading(false);
        });

        // 3. Likes / Reactions subcollection
        const likesQ = query(collection(db, 'posts', activeId, 'reactions'));
        const unsubLikes = onSnapshot(likesQ, (snap) => {
            const list = snap.docs.map(d => ({
                id: d.id,
                ...d.data()
            })) as LikeItem[];
            setLikes(list);
        }, (err) => {
            console.warn("Likes query error:", err);
        });

        return () => {
            unsubPost();
            unsubComments();
            unsubLikes();
        };
    }, [propPostId]);

    const handleDeleteComment = async (commentId: string) => {
        if (!currentPostId) return;
        if (confirm('¿Eliminar este comentario?')) {
            try {
                await deleteDoc(doc(db, 'posts', currentPostId, 'comments', commentId));
            } catch (err) {
                console.error("Error deleting comment:", err);
                alert("Error al borrar comentario");
            }
        }
    };

    if (loading && !post) {
        return <div className="text-white text-center p-12">Cargando detalles de la publicación...</div>;
    }

    if (!currentPostId || (!loading && !post)) {
        return (
            <div className="text-center p-12 bg-slate-800 rounded-2xl border border-slate-700">
                <p className="text-slate-300 font-bold text-lg mb-2">Publicación no encontrada</p>
                <p className="text-slate-500 text-sm mb-4">No se especificó un ID válido de publicación o fue eliminada.</p>
                <a href="/feed" className="text-purple-400 font-semibold hover:underline">← Volver al Feed</a>
            </div>
        );
    }

    const renderAvatar = (name?: string, avatarUrl?: string) => {
        const isHttp = avatarUrl && (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://') || avatarUrl.startsWith('data:'));
        if (isHttp) {
            return (
                <img 
                    src={avatarUrl} 
                    alt={name || 'Avatar'} 
                    className="w-full h-full object-cover rounded-full" 
                />
            );
        }
        const initial = name && name.trim().length > 0 ? name.trim()[0].toUpperCase() : '👤';
        return <span>{initial}</span>;
    };

    const formatDisplayName = (name?: string, userId?: string) => {
        if (name && name.trim().length > 0 && name.toLowerCase() !== 'usuario') {
            return name;
        }
        if (userId) {
            if (userId.includes('@')) {
                return userId.split('@')[0];
            }
            return userId.length > 12 ? userId.substring(0, 10) : userId;
        }
        return 'Anónimo';
    };

    return (
        <div className="max-w-4xl mx-auto space-y-8">
            {/* Header Back & Summary */}
            <div className="flex items-center justify-between">
                <a 
                    href="/feed" 
                    className="inline-flex items-center gap-2 text-sm text-purple-400 hover:text-purple-300 font-semibold transition-colors"
                >
                    ← Volver a Publicaciones
                </a>
                <span className="text-xs text-slate-500">ID Post: {currentPostId}</span>
            </div>

            {/* Post Card */}
            {post && (
                <div className="bg-slate-800 rounded-2xl border border-slate-700 p-6 flex flex-col md:flex-row gap-6">
                    {post.mediaUrl && (
                        <div className="w-full md:w-48 h-36 shrink-0 rounded-xl overflow-hidden bg-slate-900 border border-slate-700">
                            {extractYoutubeId(post.mediaUrl) ? (
                                <iframe 
                                    src={`https://www.youtube.com/embed/${extractYoutubeId(post.mediaUrl)}`} 
                                    className="w-full h-full border-0" 
                                    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" 
                                    allowFullScreen 
                                />
                            ) : post.mediaType === 'video' ? (
                                <video src={post.mediaUrl} controls className="w-full h-full object-cover" />
                            ) : (
                                <img src={post.mediaUrl} alt={post.title} className="w-full h-full object-cover" />
                            )}
                        </div>
                    )}
                    <div className="flex-1">
                        <h2 className="text-2xl font-bold text-white mb-2">{post.title}</h2>
                        <p className="text-slate-300 text-sm mb-4 leading-relaxed">{post.description}</p>
                        <div className="flex gap-4 text-sm font-semibold">
                            <span className="text-rose-400">❤️ {(post.reactionsCount ?? (likes.length || post.likesCount)) || 0} Reacciones</span>
                            <span className="text-blue-400">💬 {post.commentsCount || comments.length || 0} Comentarios</span>
                        </div>
                    </div>
                </div>
            )}

            {/* Interaction Tabs */}
            <div className="bg-slate-800 rounded-2xl border border-slate-700 overflow-hidden">
                <div className="flex border-b border-slate-700">
                    <button
                        onClick={() => setActiveTab('comments')}
                        className={`flex-1 py-4 font-bold text-sm transition-colors border-b-2 ${
                            activeTab === 'comments'
                                ? 'border-purple-500 text-purple-400 bg-slate-800'
                                : 'border-transparent text-slate-400 hover:text-slate-200 bg-slate-900/50'
                        }`}
                    >
                        💬 Comentarios ({comments.length})
                    </button>
                    <button
                        onClick={() => setActiveTab('likes')}
                        className={`flex-1 py-4 font-bold text-sm transition-colors border-b-2 ${
                            activeTab === 'likes'
                                ? 'border-purple-500 text-purple-400 bg-slate-800'
                                : 'border-transparent text-slate-400 hover:text-slate-200 bg-slate-900/50'
                        }`}
                    >
                        ❤️ Me Gusta / Reacciones ({likes.length})
                    </button>
                </div>

                <div className="p-6">
                    {activeTab === 'comments' ? (
                        comments.length === 0 ? (
                            <div className="text-center py-12 text-slate-500 text-sm">
                                Aún no hay comentarios en esta publicación.
                            </div>
                        ) : (
                            <div className="space-y-4">
                                {comments.map((comment) => (
                                    <div key={comment.id} className="p-4 bg-slate-900 rounded-xl border border-slate-700/60 flex items-start justify-between gap-4">
                                        <div className="flex items-start gap-3">
                                            <div className="w-10 h-10 rounded-full bg-purple-600/30 border border-purple-500/40 text-purple-300 font-bold flex items-center justify-center text-sm shrink-0 overflow-hidden">
                                                {renderAvatar(comment.userName, comment.userAvatar)}
                                            </div>
                                            <div>
                                                <div className="flex items-center gap-2">
                                                    <span className="font-bold text-white text-sm">
                                                        {formatDisplayName(comment.userName, comment.userId)}
                                                    </span>
                                                    <span className="text-xs text-slate-500">
                                                        {comment.createdAt?.toDate ? comment.createdAt.toDate().toLocaleString() : 'Reciente'}
                                                    </span>
                                                </div>
                                                <p className="text-slate-300 text-sm mt-1">{comment.text}</p>
                                            </div>
                                        </div>
                                        <button
                                            onClick={() => handleDeleteComment(comment.id)}
                                            className="text-xs text-rose-400 hover:text-rose-300 hover:bg-rose-500/10 px-2.5 py-1 rounded transition-colors"
                                            title="Moderar comentario"
                                        >
                                            Eliminar
                                        </button>
                                    </div>
                                ))}
                            </div>
                        )
                    ) : (
                        likes.length === 0 ? (
                            <div className="text-center py-12 text-slate-500 text-sm">
                                Aún no hay registros de reacciones en esta publicación.
                            </div>
                        ) : (
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                                {likes.map((like) => (
                                    <div key={like.id} className="p-3 bg-slate-900 rounded-xl border border-slate-700/60 flex items-center justify-between">
                                        <div className="flex items-center gap-3">
                                            <div className="w-9 h-9 rounded-full bg-purple-600/30 border border-purple-500/40 text-purple-300 font-bold flex items-center justify-center text-xs shrink-0 overflow-hidden">
                                                {renderAvatar(like.userName)}
                                            </div>
                                            <div>
                                                <div className="font-semibold text-white text-sm">
                                                    {formatDisplayName(like.userName, like.userId || like.id)}
                                                </div>
                                                <div className="text-xs text-slate-500">
                                                    {like.createdAt?.toDate ? like.createdAt.toDate().toLocaleDateString() : 'Reacción registrada'}
                                                </div>
                                            </div>
                                        </div>
                                        <div className="flex items-center gap-1.5 bg-purple-900/40 px-2.5 py-1 rounded-full">
                                            <span className="text-sm">
                                                {like.reactionType === 'love' ? '❤️' : like.reactionType === 'haha' ? '😆' : like.reactionType === 'wow' ? '😮' : '👍'}
                                            </span>
                                            <span className="text-xs text-purple-300 uppercase font-semibold">
                                                {like.reactionType || 'Like'}
                                            </span>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        )
                    )}
                </div>
            </div>
        </div>
    );
}
