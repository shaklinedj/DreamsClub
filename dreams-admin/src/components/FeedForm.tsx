
import React, { useState } from 'react';
import { collection, addDoc, Timestamp } from 'firebase/firestore';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import { db, storage } from '../lib/firebase';

export default function FeedForm() {
    const [title, setTitle] = useState('');
    const [description, setDescription] = useState('');
    const [imageFile, setImageFile] = useState<File | null>(null);
    const [uploading, setUploading] = useState(false);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();

        if (!title || !description) {
            alert('Por favor completa título y descripción');
            return;
        }

        setUploading(true);

        try {
            let mediaUrl = '';

            // Upload Image
            if (imageFile) {
                const storageRef = ref(storage, `feed/${Date.now()}_${imageFile.name}`);
                const snapshot = await uploadBytes(storageRef, imageFile);
                mediaUrl = await getDownloadURL(snapshot.ref);
            }

            // Create Post Field
            await addDoc(collection(db, 'posts'), {
                title,
                description,
                mediaUrl,
                mediaType: 'image', // Hardcoded for now
                postType: 'news',
                createdAt: Timestamp.now(),
                likesCount: 0,
                commentsCount: 0,
                sharesCount: 0,
                casinoId: null, // Global post
            });

            alert('Publicación creada con éxito!');
            window.location.href = '/feed'; // Simple redirect

        } catch (error) {
            console.error("Error creating post:", error);
            alert("Error al crear la publicación");
        } finally {
            setUploading(false);
        }
    };

    return (
        <form onSubmit={handleSubmit} className="bg-slate-800 rounded-2xl border border-slate-700 p-8 shadow-xl max-w-2xl mx-auto">
            <div className="space-y-6">
                <div>
                    <label className="block text-slate-300 font-medium mb-2">Título</label>
                    <input
                        type="text"
                        value={title}
                        onChange={(e) => setTitle(e.target.value)}
                        className="w-full bg-slate-900 border border-slate-700 rounded-lg px-4 py-3 text-white focus:ring-2 focus:ring-purple-500 outline-none"
                        placeholder="Título del anuncio..."
                    />
                </div>

                <div>
                    <label className="block text-slate-300 font-medium mb-2">Descripción</label>
                    <textarea
                        value={description}
                        onChange={(e) => setDescription(e.target.value)}
                        rows={4}
                        className="w-full bg-slate-900 border border-slate-700 rounded-lg px-4 py-3 text-white focus:ring-2 focus:ring-purple-500 outline-none"
                        placeholder="Detalles del evento o noticia..."
                    ></textarea>
                </div>

                <div>
                    <label className="block text-slate-300 font-medium mb-2">Imagen</label>
                    <input
                        type="file"
                        accept="image/*"
                        onChange={(e) => setImageFile(e.target.files ? e.target.files[0] : null)}
                        className="w-full bg-slate-900 border border-slate-700 rounded-lg px-4 py-3 text-slate-300"
                    />
                </div>

                <div className="pt-4 flex justify-end gap-3">
                    <a href="/feed" className="px-4 py-2 text-slate-400 hover:text-white transition-colors">Cancelar</a>
                    <button
                        type="submit"
                        disabled={uploading}
                        className="bg-purple-600 hover:bg-purple-700 disabled:opacity-50 text-white px-6 py-2 rounded-lg font-bold transition-colors"
                    >
                        {uploading ? 'Publicando...' : 'Publicar'}
                    </button>
                </div>
            </div>
        </form>
    );
}
