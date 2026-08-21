import React, { useState, useEffect } from 'react';
import { collection, addDoc, Timestamp } from 'firebase/firestore';
import { db } from '../lib/firebase';
import {
    isDriveConfigured,
    loadDriveConfig,
    setDriveConfig,
    uploadToDrive,
    loadGoogleIdentityScript,
} from '../lib/google-drive';

type UploadMode = 'drive' | 'url';

export default function StickerForm() {
    const [name, setName] = useState('');
    const [requiredStreak, setRequiredStreak] = useState<number>(0);
    const [mediaFile, setMediaFile] = useState<File | null>(null);
    const [mediaUrlInput, setMediaUrlInput] = useState('');
    const [uploadMode, setUploadMode] = useState<UploadMode>('drive');
    
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
            setMediaFile(e.target.files[0]);
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        
        if (!name.trim()) {
            setStatusMessage({ type: 'error', text: 'El nombre del sticker es obligatorio.' });
            return;
        }

        if (uploadMode === 'drive' && !mediaFile) {
            setStatusMessage({ type: 'error', text: 'Por favor selecciona un archivo de imagen.' });
            return;
        }

        if (uploadMode === 'url' && !mediaUrlInput.trim()) {
            setStatusMessage({ type: 'error', text: 'Por favor ingresa un enlace válido.' });
            return;
        }

        if (uploadMode === 'drive' && !driveConfigured) {
            setShowDriveSetup(true);
            return;
        }

        setUploading(true);
        setStatusMessage(null);
        let finalMediaUrl = '';

        try {
            if (uploadMode === 'url') {
                finalMediaUrl = mediaUrlInput.trim();
            } else if (uploadMode === 'drive' && mediaFile) {
                setUploadProgress('Subiendo imagen a Google Drive...');
                const uploadResult = await uploadToDrive(mediaFile);
                finalMediaUrl = uploadResult.viewUrl;
            }

            setUploadProgress('Guardando datos en Firebase...');
            
            await addDoc(collection(db, 'stickers'), {
                name: name.trim(),
                url: finalMediaUrl,
                requiredStreak: requiredStreak,
                createdAt: Timestamp.now(),
            });

            setStatusMessage({ type: 'success', text: '✅ Sticker guardado exitosamente.' });
            
            // Reset form
            setName('');
            setRequiredStreak(0);
            setMediaFile(null);
            setMediaUrlInput('');
            
            if (document.getElementById('file-upload')) {
                (document.getElementById('file-upload') as HTMLInputElement).value = '';
            }

        } catch (error: any) {
            console.error("Error al guardar:", error);
            setStatusMessage({ type: 'error', text: `Error: ${error.message || 'Error desconocido'}` });
        } finally {
            setUploading(false);
            setUploadProgress('');
        }
    };

    return (
        <div className="bg-slate-800 rounded-2xl border border-slate-700 overflow-hidden relative">
            <div className="p-6 md:p-8">
                {statusMessage && (
                    <div className={`mb-6 p-4 rounded-xl flex items-start gap-3 ${statusMessage.type === 'success' ? 'bg-emerald-500/10 border border-emerald-500/20 text-emerald-400' : 'bg-red-500/10 border border-red-500/20 text-red-400'}`}>
                        <span>{statusMessage.type === 'success' ? '✨' : '⚠️'}</span>
                        <p>{statusMessage.text}</p>
                    </div>
                )}

                {showDriveSetup && (
                    <div className="mb-8 bg-blue-500/10 border border-blue-500/30 rounded-xl p-6">
                        <h3 className="text-lg font-bold text-blue-400 mb-2">⚙️ Configuración de Google Drive</h3>
                        <p className="text-sm text-slate-300 mb-4">
                            Para subir stickers directamente a Drive, necesitas configurar tu Client ID y el Folder ID.
                        </p>
                        
                        <div className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-slate-400 mb-1">Google Client ID</label>
                                <input
                                    type="text"
                                    value={driveClientId}
                                    onChange={(e) => setDriveClientId(e.target.value)}
                                    placeholder="ej: 123456789-abc.apps.googleusercontent.com"
                                    className="w-full bg-slate-900 border border-slate-700 rounded-lg px-4 py-2 text-white focus:ring-2 focus:ring-purple-500 outline-none"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-400 mb-1">Folder ID (Donde se guardarán los stickers)</label>
                                <input
                                    type="text"
                                    value={driveFolderId}
                                    onChange={(e) => setDriveFolderId(e.target.value)}
                                    placeholder="ej: 1aBcD2eFgH3iJkL4mNoP5qRsT6uVwXyZ"
                                    className="w-full bg-slate-900 border border-slate-700 rounded-lg px-4 py-2 text-white focus:ring-2 focus:ring-purple-500 outline-none"
                                />
                            </div>
                            
                            <div className="flex gap-3 pt-2">
                                <button 
                                    onClick={handleSaveDriveConfig}
                                    className="px-4 py-2 bg-blue-600 hover:bg-blue-500 text-white rounded-lg font-medium transition-colors"
                                >
                                    Guardar Configuración
                                </button>
                                <button 
                                    onClick={() => setShowDriveSetup(false)}
                                    className="px-4 py-2 bg-slate-700 hover:bg-slate-600 text-white rounded-lg font-medium transition-colors"
                                >
                                    Cancelar
                                </button>
                            </div>
                        </div>
                    </div>
                )}

                <form onSubmit={handleSubmit} className="space-y-6">
                    {/* Nombre del Sticker */}
                    <div>
                        <label className="block text-sm font-medium text-slate-400 mb-2">Nombre del Sticker *</label>
                        <input
                            type="text"
                            value={name}
                            onChange={(e) => setName(e.target.value)}
                            placeholder="Ej: Logo Casino 3D"
                            className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-3 text-white focus:ring-2 focus:ring-purple-500 focus:border-transparent outline-none transition-all"
                            required
                        />
                    </div>

                    {/* Tipo de Usuario según Racha */}
                    <div>
                        <label className="block text-sm font-medium text-slate-400 mb-2">Tipo de Usuario (Según su Racha) *</label>
                        <select
                            value={requiredStreak}
                            onChange={(e) => setRequiredStreak(Number(e.target.value))}
                            className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-3 text-white focus:ring-2 focus:ring-purple-500 focus:border-transparent outline-none transition-all"
                        >
                            <option value={0}>Todos los usuarios (0 días de racha)</option>
                            <option value={1}>Usuario Bronce (1 día de racha)</option>
                            <option value={3}>Usuario Plata (3 días de racha)</option>
                            <option value={7}>Usuario Oro (7 días de racha)</option>
                            <option value={14}>Usuario Platino (14 días de racha)</option>
                            <option value={21}>Usuario VIP Diamante (21 días de racha)</option>
                            <option value={28}>Usuario VIP Leyenda (28 días de racha)</option>
                        </select>
                        <p className="mt-2 text-xs text-slate-500">El sticker se desbloqueará según la categoría de racha del usuario.</p>
                    </div>

                    {/* Método de subida */}
                    <div>
                        <label className="block text-sm font-medium text-slate-400 mb-3">Fuente de la Imagen</label>
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <button
                                type="button"
                                onClick={() => setUploadMode('drive')}
                                className={`flex items-center gap-3 p-4 rounded-xl border transition-all ${
                                    uploadMode === 'drive' 
                                    ? 'bg-blue-500/10 border-blue-500 text-blue-400' 
                                    : 'bg-slate-900 border-slate-700 text-slate-400 hover:border-slate-500'
                                }`}
                            >
                                <span className="text-2xl">📁</span>
                                <div className="text-left">
                                    <div className="font-medium text-white">Subir a Google Drive</div>
                                    <div className="text-xs mt-1">Sube el archivo desde tu PC</div>
                                </div>
                            </button>

                            <button
                                type="button"
                                onClick={() => setUploadMode('url')}
                                className={`flex items-center gap-3 p-4 rounded-xl border transition-all ${
                                    uploadMode === 'url' 
                                    ? 'bg-purple-500/10 border-purple-500 text-purple-400' 
                                    : 'bg-slate-900 border-slate-700 text-slate-400 hover:border-slate-500'
                                }`}
                            >
                                <span className="text-2xl">🔗</span>
                                <div className="text-left">
                                    <div className="font-medium text-white">Usar Enlace Existente</div>
                                    <div className="text-xs mt-1">Pega un link de Drive o web</div>
                                </div>
                            </button>
                        </div>
                    </div>

                    {/* Subida Drive */}
                    {uploadMode === 'drive' && (
                        <div className="p-6 bg-slate-900 rounded-xl border border-slate-700 border-dashed">
                            <label className="block text-sm font-medium text-slate-400 mb-4">Seleccionar Imagen</label>
                            <input
                                id="file-upload"
                                type="file"
                                accept="image/*"
                                onChange={handleFileChange}
                                className="block w-full text-sm text-slate-400
                                    file:mr-4 file:py-2.5 file:px-4
                                    file:rounded-full file:border-0
                                    file:text-sm file:font-semibold
                                    file:bg-purple-500 file:text-white
                                    hover:file:bg-purple-400 cursor-pointer transition-all"
                            />
                            {mediaFile && (
                                <div className="mt-4 text-sm text-emerald-400 flex items-center gap-2">
                                    <span>✅</span> Archivo seleccionado: {mediaFile.name} ({(mediaFile.size / 1024 / 1024).toFixed(2)} MB)
                                </div>
                            )}
                            
                            <div className="mt-4 pt-4 border-t border-slate-800 flex justify-end">
                                <button 
                                    type="button" 
                                    onClick={() => setShowDriveSetup(!showDriveSetup)}
                                    className="text-xs text-blue-400 hover:text-blue-300 underline"
                                >
                                    Configurar Google Drive
                                </button>
                            </div>
                        </div>
                    )}

                    {/* Input de URL */}
                    {uploadMode === 'url' && (
                        <div>
                            <label className="block text-sm font-medium text-slate-400 mb-2">Enlace de la imagen *</label>
                            <input
                                type="url"
                                value={mediaUrlInput}
                                onChange={(e) => setMediaUrlInput(e.target.value)}
                                placeholder="https://drive.google.com/file/d/..."
                                className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-3 text-white focus:ring-2 focus:ring-purple-500 focus:border-transparent outline-none transition-all"
                            />
                            <p className="mt-2 text-xs text-slate-500">Puedes pegar enlaces de visualización o descarga directa.</p>
                        </div>
                    )}

                    {/* Submit Button */}
                    <div className="pt-6">
                        <button
                            type="submit"
                            disabled={uploading}
                            className={`w-full py-4 rounded-xl font-bold text-lg transition-all flex items-center justify-center gap-3
                                ${uploading 
                                    ? 'bg-slate-700 text-slate-400 cursor-not-allowed' 
                                    : 'bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-500 hover:to-pink-500 text-white shadow-lg shadow-purple-500/25 hover:shadow-purple-500/40'
                                }`}
                        >
                            {uploading ? (
                                <>
                                    <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                                    </svg>
                                    {uploadProgress || 'Procesando...'}
                                </>
                            ) : (
                                <>
                                    <span>✨</span> Publicar Sticker
                                </>
                            )}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}
