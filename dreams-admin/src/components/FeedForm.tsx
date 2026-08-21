import React, { useState, useEffect } from 'react';
import { collection, addDoc, Timestamp } from 'firebase/firestore';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import { db, storage } from '../lib/firebase';
import {
    isDriveConfigured,
    loadDriveConfig,
    setDriveConfig,
    uploadToDrive,
    loadGoogleIdentityScript,
} from '../lib/google-drive';
import { compressImage } from '../lib/image-compressor';

type UploadMode = 'drive' | 'url' | 'firebase';

export default function FeedForm() {
    const [title, setTitle] = useState('');
    const [description, setDescription] = useState('');
    const [postType, setPostType] = useState<'news' | 'event' | 'promotion'>('news');
    const [mediaType, setMediaType] = useState<'image' | 'video'>('image');
    const [mediaFile, setMediaFile] = useState<File | null>(null);
    const [mediaSource, setMediaSource] = useState<'drive' | 'youtube'>('drive');
    const [youtubeUrl, setYoutubeUrl] = useState('');
    const [uploading, setUploading] = useState(false);
    const [uploadProgress, setUploadProgress] = useState('');
    const [statusMessage, setStatusMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

    // Drive config state
    const [driveConfigured, setDriveConfigured] = useState(false);
    const [showDriveSetup, setShowDriveSetup] = useState(false);
    const [driveClientId, setDriveClientId] = useState('');
    const [driveFolderId, setDriveFolderId] = useState('');

    useEffect(() => {
        const config = loadDriveConfig();
        setDriveClientId(config.clientId);
        setDriveFolderId(config.folderId);
        setDriveConfigured(isDriveConfigured());
        // Pre-load GIS script
        loadGoogleIdentityScript().catch(() => {});
    }, []);

    const handleSaveDriveConfig = () => {
        setDriveConfig(driveClientId.trim(), driveFolderId.trim());
        setDriveConfigured(isDriveConfigured());
        setShowDriveSetup(false);
        setStatusMessage({ type: 'success', text: '✅ Configuración de Google Drive guardada correctamente.' });
    };

    const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        if (e.target.files && e.target.files[0]) {
            const file = e.target.files[0];
            setMediaFile(file);
            if (file.type.startsWith('video/')) {
                setMediaType('video');
            } else {
                setMediaType('image');
            }
        }
    };

    /** Transforma URLs de Google Drive al formato embebible */
    const formatDriveUrl = (url: string, isVideo: boolean = false): string => {
        const trimmed = url.trim();
        // Extraer file ID de diferentes formatos de Drive
        const driveMatch = trimmed.match(/\/file\/d\/([a-zA-Z0-9_-]+)/) ||
                           trimmed.match(/id=([a-zA-Z0-9_-]+)/) ||
                           trimmed.match(/\/d\/([a-zA-Z0-9_-]+)/);
        if (driveMatch && driveMatch[1]) {
            if (isVideo) {
                return `https://drive.google.com/uc?export=download&id=${driveMatch[1]}`;
            }
            return `https://lh3.googleusercontent.com/d/${driveMatch[1]}`;
        }
        return trimmed;
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setStatusMessage(null);
        setUploadProgress('');

        if (!title.trim() || !description.trim()) {
            setStatusMessage({ type: 'error', text: 'Por favor completa el título y la descripción.' });
            return;
        }

        setUploading(true);

        try {
            let finalMediaUrl = '';
            let finalMediaType = mediaType;

            if (mediaSource === 'youtube') {
                if (!youtubeUrl.trim()) {
                    setStatusMessage({ type: 'error', text: 'Por favor ingresa un enlace de YouTube.' });
                    setUploading(false);
                    return;
                }
                const ytRegex = /^(https?:\/\/)?(www\.)?(youtube\.com|youtu\.be)\/.+$/;
                if (!ytRegex.test(youtubeUrl.trim())) {
                    setStatusMessage({ type: 'error', text: 'Enlace de YouTube no válido. Asegúrate de que comience con youtube.com o youtu.be' });
                    setUploading(false);
                    return;
                }
                finalMediaUrl = youtubeUrl.trim();
                finalMediaType = 'video';
            } else {
                // ── MODO ÚNICO: Google Drive ──────────────────
                if (!mediaFile) {
                    setStatusMessage({ type: 'error', text: 'Selecciona un archivo para subir a Google Drive.' });
                    setUploading(false);
                    return;
                }
                if (!driveConfigured) {
                    setStatusMessage({ type: 'error', text: 'Configura tu Google Drive primero (botón ⚙️ arriba).' });
                    setUploading(false);
                    return;
                }

                setUploadProgress('Comprimiendo y autenticando con Google Drive...');
                
                // Comprimir la imagen si es aplicable antes de subir
                const compressedFile = await compressImage(mediaFile);
                
                const result = await uploadToDrive(compressedFile);
                finalMediaType = compressedFile.type.startsWith('video/') ? 'video' : 'image';
                finalMediaUrl = finalMediaType === 'video'
                    ? `https://drive.google.com/uc?export=download&id=${result.fileId}`
                    : result.directUrl;
                setUploadProgress('Archivo subido a Drive ✓');
            }

            setUploadProgress('Guardando publicación en Firestore...');

            // Crear documento en Firestore
            await addDoc(collection(db, 'posts'), {
                title: title.trim(),
                description: description.trim(),
                mediaUrl: finalMediaUrl,
                mediaType: finalMediaType,
                postType: postType,
                createdAt: Timestamp.now(),
                likesCount: 0,
                commentsCount: 0,
                sharesCount: 0,
                casinoId: '4',
                location: 'Dreams Coyhaique',
            });

            setStatusMessage({ type: 'success', text: '¡Publicación creada con éxito! Redirigiendo...' });
            setTimeout(() => { window.location.href = '/feed'; }, 1200);

        } catch (error: any) {
            console.error('Error creating post:', error);
            setStatusMessage({
                type: 'error',
                text: `Error al publicar: ${error?.message || 'Revisa los permisos o la conexión.'}`,
            });
        } finally {
            setUploading(false);
            setUploadProgress('');
        }
    };



    return (
        <form onSubmit={handleSubmit} className="bg-slate-800 rounded-2xl border border-slate-700 p-8 shadow-xl max-w-2xl mx-auto">
            <h2 className="text-xl font-bold text-white mb-6">Nueva Publicación (Dreams Coyhaique)</h2>

            {statusMessage && (
                <div className={`p-4 rounded-xl mb-6 text-sm font-medium ${
                    statusMessage.type === 'success'
                        ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30'
                        : 'bg-rose-500/20 text-rose-300 border border-rose-500/30'
                }`}>
                    {statusMessage.text}
                </div>
            )}

            <div className="space-y-6">

                {/* ── CONFIGURACIÓN DE GOOGLE DRIVE ── */}
                {showDriveSetup && (
                    <div className="p-5 bg-blue-900/30 rounded-xl border border-blue-500/40 space-y-4">
                        <h3 className="text-sm font-bold text-blue-300">⚙️ Configurar Google Drive</h3>
                        <p className="text-xs text-blue-200/70">
                            Necesitas un <strong>OAuth Client ID</strong> de Google Cloud Console y el <strong>ID de tu carpeta</strong> de Drive.
                        </p>
                        <div>
                            <label className="block text-xs text-blue-300 mb-1">OAuth 2.0 Client ID</label>
                            <input
                                type="text"
                                value={driveClientId}
                                onChange={(e) => setDriveClientId(e.target.value)}
                                placeholder="123456789-abc.apps.googleusercontent.com"
                                className="w-full bg-slate-900 border border-blue-500/30 rounded-lg px-3 py-2 text-white text-sm focus:ring-2 focus:ring-blue-500 outline-none"
                            />
                        </div>
                        <div>
                            <label className="block text-xs text-blue-300 mb-1">ID de Carpeta de Google Drive</label>
                            <input
                                type="text"
                                value={driveFolderId}
                                onChange={(e) => setDriveFolderId(e.target.value)}
                                placeholder="1AbCdEfGhIjK_lMnOpQrStU (de la URL de tu carpeta)"
                                className="w-full bg-slate-900 border border-blue-500/30 rounded-lg px-3 py-2 text-white text-sm focus:ring-2 focus:ring-blue-500 outline-none"
                            />
                        </div>
                        <div className="flex gap-2">
                            <button
                                type="button"
                                onClick={handleSaveDriveConfig}
                                className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-bold transition-colors"
                            >
                                Guardar Configuración
                            </button>
                            <button
                                type="button"
                                onClick={() => setShowDriveSetup(false)}
                                className="text-slate-400 hover:text-white px-3 py-2 text-sm transition-colors"
                            >
                                Cancelar
                            </button>
                        </div>
                    </div>
                )}





                {/* Tipo de contenido */}
                <div>
                    <label className="block text-slate-300 font-medium mb-2">Tipo de Contenido</label>
                    <div className="grid grid-cols-3 gap-3">
                        {(['news', 'event', 'promotion'] as const).map((type) => (
                            <button
                                key={type}
                                type="button"
                                onClick={() => setPostType(type)}
                                className={`py-2 px-4 rounded-lg font-medium text-sm transition-colors capitalize ${
                                    postType === type
                                        ? 'bg-purple-600 text-white'
                                        : 'bg-slate-900 text-slate-400 hover:bg-slate-700 hover:text-white'
                                }`}
                            >
                                {type === 'news' ? 'Noticia' : type === 'event' ? 'Evento' : 'Promoción'}
                            </button>
                        ))}
                    </div>
                </div>

                {/* Título */}
                <div>
                    <label className="block text-slate-300 font-medium mb-2">Título</label>
                    <input
                        type="text"
                        value={title}
                        onChange={(e) => setTitle(e.target.value)}
                        className="w-full bg-slate-900 border border-slate-700 rounded-lg px-4 py-3 text-white focus:ring-2 focus:ring-purple-500 outline-none"
                        placeholder="Ej: Gran Torneo de Poker en Coyhaique..."
                        required
                    />
                </div>

                {/* Descripción */}
                <div>
                    <label className="block text-slate-300 font-medium mb-2">Descripción</label>
                    <textarea
                        value={description}
                        onChange={(e) => setDescription(e.target.value)}
                        rows={4}
                        className="w-full bg-slate-900 border border-slate-700 rounded-lg px-4 py-3 text-white focus:ring-2 focus:ring-purple-500 outline-none"
                        placeholder="Escribe los detalles o información para los socios..."
                        required
                    ></textarea>
                </div>

                {/* Origen de Multimedia */}
                <div>
                    <label className="block text-slate-300 font-medium mb-2">Origen de Multimedia</label>
                    <div className="grid grid-cols-2 gap-3 mb-4">
                        <button
                            type="button"
                            onClick={() => setMediaSource('drive')}
                            className={`py-2 px-4 rounded-lg font-medium text-sm transition-colors ${
                                mediaSource === 'drive'
                                    ? 'bg-purple-600 text-white border border-purple-500'
                                    : 'bg-slate-900 text-slate-400 hover:bg-slate-700 hover:text-white border border-transparent'
                            }`}
                        >
                            📁 Archivo (Google Drive)
                        </button>
                        <button
                            type="button"
                            onClick={() => setMediaSource('youtube')}
                            className={`py-2 px-4 rounded-lg font-medium text-sm transition-colors ${
                                mediaSource === 'youtube'
                                    ? 'bg-purple-600 text-white border border-purple-500'
                                    : 'bg-slate-900 text-slate-400 hover:bg-slate-700 hover:text-white border border-transparent'
                            }`}
                        >
                            🔗 Enlace de YouTube
                        </button>
                    </div>
                </div>

                {mediaSource === 'drive' ? (
                    <div>
                        <label className="block text-slate-300 font-medium mb-2">
                            📁 Archivo para Google Drive
                        </label>

                        <div>
                            <input
                                type="file"
                                accept="image/*,video/*"
                                onChange={handleFileChange}
                                className="w-full bg-slate-900 border border-slate-700 rounded-lg px-4 py-3 text-slate-300 file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-semibold file:bg-green-600 file:text-white hover:file:bg-green-700"
                            />
                            {mediaFile && (
                                <p className="mt-2 text-xs text-slate-400">
                                    Archivo: <strong className="text-green-400">{mediaFile.name}</strong> ({(mediaFile.size / 1024 / 1024).toFixed(1)} MB) — Tipo: <strong className="text-purple-400 uppercase">{mediaType}</strong>
                                </p>
                            )}
                            {!driveConfigured && (
                                <p className="mt-2 text-xs text-amber-400">
                                    ⚠️ Debes configurar Google Drive primero. Toca <strong>⚙️ Config Drive</strong> arriba.
                                </p>
                            )}
                        </div>
                    </div>
                ) : (
                    <div>
                        <label className="block text-slate-300 font-medium mb-2">
                            🔗 Enlace de YouTube (Video o En Vivo)
                        </label>
                        <input
                            type="url"
                            value={youtubeUrl}
                            onChange={(e) => setYoutubeUrl(e.target.value)}
                            placeholder="Ej: https://www.youtube.com/watch?v=dQw4w9WgXcQ o https://youtu.be/..."
                            className="w-full bg-slate-900 border border-slate-700 rounded-lg px-4 py-3 text-white focus:ring-2 focus:ring-purple-500 outline-none"
                            required={mediaSource === 'youtube'}
                        />
                        <p className="mt-2 text-xs text-slate-400">
                            Pega el enlace directo de un video subido o de una transmisión activa (YouTube Live).
                        </p>
                    </div>
                )}

                {/* Progreso de subida */}
                {uploadProgress && (
                    <div className="flex items-center gap-3 text-sm text-blue-300 bg-blue-900/20 px-4 py-3 rounded-xl border border-blue-500/20">
                        <span className="animate-spin inline-block w-4 h-4 border-2 border-blue-400 border-t-transparent rounded-full"></span>
                        {uploadProgress}
                    </div>
                )}

                {/* Botones */}
                <div className="pt-4 flex justify-end gap-3">
                    <a href="/feed" className="px-4 py-2 text-slate-400 hover:text-white transition-colors">Cancelar</a>
                    <button
                        type="submit"
                        disabled={uploading}
                        className="bg-purple-600 hover:bg-purple-700 disabled:opacity-50 text-white px-6 py-2 rounded-lg font-bold transition-colors flex items-center gap-2"
                    >
                        {uploading ? (
                            <>
                                <span className="animate-spin inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full"></span>
                                Publicando...
                            </>
                        ) : 'Publicar Ahora'}
                    </button>
                </div>
            </div>
        </form>
    );
}
