
import React, { useEffect, useState } from 'react';
import { collection, onSnapshot, doc, deleteDoc, orderBy, query } from 'firebase/firestore';
import { db } from '../lib/firebase';

interface FeedPost {
    id: string;
    title: string;
    description: string;
    mediaUrl: string;
    createdAt: any;
    likesCount: number;
    commentsCount: number;
    author?: string; // Optional in our model but useful for display
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
        });

        return () => unsubscribe();
    }, []);

    const handleDelete = async (postId: string) => {
        if (confirm('¿Estás seguro de que quieres eliminar esta publicación?')) {
            try {
                await deleteDoc(doc(db, 'posts', postId));
            } catch (error) {
                console.error("Error deleting post:", error);
                alert("Error al eliminar el post");
            }
        }
    };

    if (loading) return <div className="text-white text-center p-10">Cargando feed...</div>;

    if (posts.length === 0) return <div className="text-slate-400 text-center p-10">No hay publicaciones.</div>;

    return (
        <div className="space-y-6">
            {posts.map((post) => (
                <div key={post.id} className="bg-slate-800 rounded-2xl border border-slate-700 overflow-hidden flex flex-col md:flex-row gap-6 p-6">
                    {/* Image */}
                    <div className="w-full md:w-48 h-32 md:h-auto shrink-0 rounded-xl overflow-hidden bg-slate-900 border border-slate-700">
                        {post.mediaUrl ? (
                            <img src={post.mediaUrl} alt={post.title} className="w-full h-full object-cover" />
                        ) : (
                            <div className="w-full h-full flex items-center justify-center text-slate-600">No Img</div>
                        )}
                    </div>

                    {/* Content */}
                    <div className="flex-1">
                        <div className="flex justify-between items-start mb-2">
                            <div>
                                <h3 className="font-bold text-white text-lg">{post.title || 'Sin título'}</h3>
                                <span className="text-xs text-slate-500">
                                    {post.createdAt?.toDate ? post.createdAt.toDate().toLocaleString() : 'Fecha desconocida'}
                                </span>
                            </div>
                        </div>

                        <p className="text-slate-300 mb-4 line-clamp-2">{post.description}</p>

                        <div className="flex items-center gap-6 text-sm text-slate-400">
                            <span className="flex items-center gap-1">
                                ❤️ {post.likesCount || 0}
                            </span>
                            <span className="flex items-center gap-1">
                                💬 {post.commentsCount || 0}
                            </span>
                        </div>
                    </div>

                    {/* Actions */}
                    <div className="flex md:flex-col gap-2 justify-center border-t md:border-t-0 md:border-l border-slate-700 pt-4 md:pt-0 md:pl-6">
                        <button
                            onClick={() => handleDelete(post.id)}
                            className="px-4 py-2 bg-red-500/10 hover:bg-red-500/20 text-red-400 border border-red-500/20 rounded-lg text-sm font-medium transition-colors"
                        >
                            Eliminar
                        </button>
                    </div>
                </div>
            ))}
        </div>
    );
}
