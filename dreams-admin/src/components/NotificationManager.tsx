import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, deleteDoc, doc, orderBy, query, Timestamp } from 'firebase/firestore';
import { db } from '../lib/firebase';
import {
    isDriveConfigured,
    loadDriveConfig,
    setDriveConfig,
    uploadToDrive,
    deleteFromDrive,
    loadGoogleIdentityScript,
} from '../lib/google-drive';
import { compressImage } from '../lib/image-compressor';

interface NotificationItem {
    id: string;
    title: string;
    body: string;
    type?: string;
    targetSegment?: {
        streak?: string;
        presence?: string;
        consentOnly?: boolean;
        estimatedReach?: number;
    };
    imageUrl?: string;
    createdAt: any;
    status?: string;
}

interface UserItem {
    id: string;
    contactConsent?: boolean;
    currentStreak?: number;
    lastVisit?: any;
    isPresentToday?: boolean;
    fcmToken?: string;
    birthday?: any;
    name?: string;
    displayName?: string;
    email?: string;
    rut?: string;
}

interface ScheduledCampaign {
    id: string;
    title: string;
    body: string;
    type: 'birthday' | 'prize_reminder' | 'custom';
    status: string;
    targetDate?: string | null;
    createdAt: any;
}

interface PrizeItem {
    id: string;
    userId: string;
    status: string;
    prizeName?: string;
}

export default function NotificationManager() {
    const [title, setTitle] = useState('');
    const [body, setBody] = useState('');
    const [type, setType] = useState<'info' | 'promo' | 'event' | 'alert'>('promo');
    const [imageUrl, setImageUrl] = useState('');
    const [mediaFile, setMediaFile] = useState<File | null>(null);
    const [sending, setSending] = useState(false);
    const [statusMessage, setStatusMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);
    const [history, setHistory] = useState<NotificationItem[]>([]);
    const [users, setUsers] = useState<UserItem[]>([]);
    const [posts, setPosts] = useState<{ id: string; title: string; body?: string }[]>([]);
    const [selectedPostId, setSelectedPostId] = useState('');
    const [loading, setLoading] = useState(true);

    // Filtros de Segmentación de Audiencia
    const [targetStreak, setTargetStreak] = useState<'all' | 'active' | 'bronze' | 'silver' | 'gold' | 'platinum' | 'none'>('all');
    const [targetPresence, setTargetPresence] = useState<'all' | 'today' | 'inactive5' | 'inactive10'>('all');
    const [targetConsentOnly, setTargetConsentOnly] = useState(false);

    // Nuevos Filtros Avanzados
    const [targetBirthday, setTargetBirthday] = useState(false);
    const [targetUnclaimedPrizes, setTargetUnclaimedPrizes] = useState(false);
    const [targetAgeRange, setTargetAgeRange] = useState<'all' | 'under30' | '30to50' | 'over50'>('all');
    const [prizes, setPrizes] = useState<PrizeItem[]>([]);

    // Campañas Programadas
    const [scheduledCampaigns, setScheduledCampaigns] = useState<ScheduledCampaign[]>([]);
    const [schedTitle, setSchedTitle] = useState('');
    const [schedBody, setSchedBody] = useState('');
    const [schedType, setSchedType] = useState<'birthday' | 'prize_reminder' | 'custom'>('birthday');
    const [schedDate, setSchedDate] = useState('');

    // Drive config state
    const [driveConfigured, setDriveConfigured] = useState(false);
    const [showDriveSetup, setShowDriveSetup] = useState(false);
    const [driveClientId, setDriveClientId] = useState('');
    const [driveFolderId, setDriveFolderId] = useState('');

    // Vercel API state
    const [vercelApiUrl, setVercelApiUrl] = useState('');

    useEffect(() => {
        const qNotifs = query(collection(db, 'notifications'), orderBy('createdAt', 'desc'));
        const unsubNotifs = onSnapshot(qNotifs, (snapshot) => {
            const list = snapshot.docs.map((d) => ({
                id: d.id,
                ...d.data()
            })) as NotificationItem[];
            setHistory(list);
            setLoading(false);
        }, (err) => {
            console.error("Error reading notifications history:", err);
            setLoading(false);
        });

        const unsubUsers = onSnapshot(collection(db, 'users'), (snapshot) => {
            const uList = snapshot.docs.map(d => ({ id: d.id, ...d.data() })) as UserItem[];
            setUsers(uList);
        });

        const unsubPosts = onSnapshot(collection(db, 'posts'), (snapshot) => {
            const pList = snapshot.docs.map(d => ({
                id: d.id,
                title: d.data().title || d.data().description?.substring(0, 50) || d.id,
                body: d.data().description || ''
            }));
            setPosts(pList);
        });

        const unsubPrizes = onSnapshot(collection(db, 'user_prizes'), (snapshot) => {
            const pList = snapshot.docs.map(d => ({
                id: d.id,
                userId: d.data().userId || '',
                status: d.data().status || 'disponible',
                prizeName: d.data().prizeName || 'premio'
            })) as PrizeItem[];
            setPrizes(pList);
        });

        const unsubSched = onSnapshot(collection(db, 'scheduled_campaigns'), (snapshot) => {
            const list = snapshot.docs.map(d => ({
                id: d.id,
                ...d.data()
            })) as ScheduledCampaign[];
            setScheduledCampaigns(list);
        });

        return () => {
            unsubNotifs();
            unsubUsers();
            unsubPosts();
            unsubPrizes();
            unsubSched();
        };
    }, []);

    useEffect(() => {
        const config = loadDriveConfig();
        setDriveClientId(config.clientId);
        setDriveFolderId(config.folderId);
        setDriveConfigured(isDriveConfigured());
        loadGoogleIdentityScript().catch(() => {});

        const savedVercelUrl = localStorage.getItem('vercel_api_url') || '';
        setVercelApiUrl(savedVercelUrl);
    }, []);

    // Calcular usuarios alcanzados por la segmentación actual
    const getDaysSinceLastVisit = (lastVisit: any): number => {
        if (!lastVisit) return 999;
        const date = lastVisit.toDate ? lastVisit.toDate() : new Date(lastVisit);
        const diffTime = Math.abs(new Date().getTime() - date.getTime());
        return Math.floor(diffTime / (1000 * 60 * 60 * 24));
    };

    const calculateAge = (birthday: any): number => {
        if (!birthday) return 999;
        const date = birthday.toDate ? birthday.toDate() : new Date(birthday);
        const ageDifMs = Date.now() - date.getTime();
        const ageDate = new Date(ageDifMs);
        return Math.abs(ageDate.getUTCFullYear() - 1970);
    };

    const isBirthdayToday = (birthday: any): boolean => {
        if (!birthday) return false;
        const date = birthday.toDate ? birthday.toDate() : new Date(birthday);
        const today = new Date();
        return date.getDate() === today.getDate() && date.getMonth() === today.getMonth();
    };

    const targetUserCount = users.filter((u) => {
        const streak = u.currentStreak || 0;
        if (targetStreak === 'active' && streak < 1) return false;
        if (targetStreak === 'bronze' && streak < 3) return false;
        if (targetStreak === 'silver' && streak < 7) return false;
        if (targetStreak === 'gold' && streak < 14) return false;
        if (targetStreak === 'platinum' && streak < 30) return false;
        if (targetStreak === 'none' && streak > 0) return false;

        const daysInactive = getDaysSinceLastVisit(u.lastVisit);
        if (targetPresence === 'today' && !u.isPresentToday && daysInactive > 0) return false;
        if (targetPresence === 'inactive5' && daysInactive <= 5) return false;
        if (targetPresence === 'inactive10' && daysInactive <= 10) return false;

        if (targetConsentOnly && !u.contactConsent) return false;

        // Nuevos Filtros Avanzados
        if (targetBirthday && !isBirthdayToday(u.birthday)) return false;

        if (targetUnclaimedPrizes) {
            const hasUnclaimed = prizes.some(p => 
                (p.userId === u.id || 
                 (u.email && p.userId === u.email) || 
                 (u.rut && p.userId === u.rut)) && 
                p.status === 'disponible'
            );
            if (!hasUnclaimed) return false;
        }

        if (targetAgeRange !== 'all') {
            const age = calculateAge(u.birthday);
            if (targetAgeRange === 'under30' && age >= 30) return false;
            if (targetAgeRange === '30to50' && (age < 30 || age > 50)) return false;
            if (targetAgeRange === 'over50' && age <= 50) return false;
        }

        return true;
    }).length;

    const handleSaveDriveConfig = () => {
        setDriveConfig(driveClientId.trim(), driveFolderId.trim());
        setDriveConfigured(isDriveConfigured());
        localStorage.setItem('vercel_api_url', vercelApiUrl.trim());
        setShowDriveSetup(false);
        setStatusMessage({ type: 'success', text: '✅ Configuración guardada correctamente.' });
    };

    const handleAddScheduledCampaign = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!schedTitle.trim() || !schedBody.trim()) return;

        try {
            await addDoc(collection(db, 'scheduled_campaigns'), {
                title: schedTitle.trim(),
                body: schedBody.trim(),
                type: schedType,
                status: 'active',
                targetDate: schedType === 'custom' ? schedDate : null,
                createdAt: Timestamp.now(),
            });
            setSchedTitle('');
            setSchedBody('');
            setSchedDate('');
            setStatusMessage({ type: 'success', text: '✅ Campaña programada guardada exitosamente.' });
        } catch (err: any) {
            console.error("Error creating scheduled campaign:", err);
            setStatusMessage({ type: 'error', text: 'Error al guardar campaña: ' + err.message });
        }
    };

    const handleDeleteScheduledCampaign = async (id: string) => {
        if (confirm('¿Eliminar esta campaña programada?')) {
            try {
                await deleteDoc(doc(db, 'scheduled_campaigns', id));
            } catch (err) {
                console.error("Error deleting campaign:", err);
            }
        }
    };

    const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        if (e.target.files && e.target.files[0]) {
            setMediaFile(e.target.files[0]);
        }
    };

    const handleSend = async (e: React.FormEvent) => {
        e.preventDefault();
        setStatusMessage(null);

        if (!title.trim() || !body.trim()) {
            setStatusMessage({ type: 'error', text: 'Por favor ingresa un título y mensaje.' });
            return;
        }

        setSending(true);

        try {
            let finalImageUrl = imageUrl.trim() || null;

            if (mediaFile) {
                if (!driveConfigured) {
                    setStatusMessage({ type: 'error', text: 'Configura tu Google Drive primero (botón ⚙️) para subir la imagen.' });
                    setSending(false);
                    return;
                }
                const compressedFile = await compressImage(mediaFile);
                const result = await uploadToDrive(compressedFile);
                finalImageUrl = result.directUrl;
            }

            const docRef = await addDoc(collection(db, 'notifications'), {
                title: title.trim(),
                body: body.trim(),
                type: type,
                imageUrl: finalImageUrl,
                linkedPostId: selectedPostId || null,
                casinoId: '4', // Coyhaique
                createdAt: Timestamp.now(),
                status: 'sent',
                broadcast: targetStreak === 'all' && targetPresence === 'all' && !targetConsentOnly,
                targetSegment: {
                    streak: targetStreak,
                    presence: targetPresence,
                    consentOnly: targetConsentOnly,
                    estimatedReach: targetUserCount,
                }
            });

            // Dispatch background push notifications via Vercel FCM proxy if configured
            let pushStatus = '';
            if (vercelApiUrl.trim()) {
                const recipients = users.filter((u) => {
                    const streak = u.currentStreak || 0;
                    if (targetStreak === 'active' && streak < 1) return false;
                    if (targetStreak === 'bronze' && streak < 3) return false;
                    if (targetStreak === 'silver' && streak < 7) return false;
                    if (targetStreak === 'gold' && streak < 14) return false;
                    if (targetStreak === 'platinum' && streak < 30) return false;
                    if (targetStreak === 'none' && streak > 0) return false;

                    const daysInactive = getDaysSinceLastVisit(u.lastVisit);
                    if (targetPresence === 'today' && !u.isPresentToday && daysInactive > 0) return false;
                    if (targetPresence === 'inactive5' && daysInactive <= 5) return false;
                    if (targetPresence === 'inactive10' && daysInactive <= 10) return false;

                    if (targetConsentOnly && !u.contactConsent) return false;

                    // Nuevos Filtros Avanzados
                    if (targetBirthday && !isBirthdayToday(u.birthday)) return false;

                    if (targetUnclaimedPrizes) {
                        const hasUnclaimed = prizes.some(p => 
                            (p.userId === u.id || 
                             (u.email && p.userId === u.email) || 
                             (u.rut && p.userId === u.rut)) && 
                            p.status === 'disponible'
                        );
                        if (!hasUnclaimed) return false;
                    }

                    if (targetAgeRange !== 'all') {
                        const age = calculateAge(u.birthday);
                        if (targetAgeRange === 'under30' && age >= 30) return false;
                        if (targetAgeRange === '30to50' && (age < 30 || age > 50)) return false;
                        if (targetAgeRange === 'over50' && age <= 50) return false;
                    }

                    return !!u.fcmToken;
                }).map((u) => {
                    const userName = u.displayName || u.name || 'Socio';
                    const userPrize = prizes.find(p => 
                        (p.userId === u.id || (u.email && p.userId === u.email) || (u.rut && p.userId === u.rut)) && 
                        p.status === 'disponible'
                    );

                    let personalizedBody = body.trim()
                        .replace(/{name}/g, userName)
                        .replace(/{nombre}/g, userName);

                    if (userPrize) {
                        personalizedBody = personalizedBody.replace(/{pending_prize}/g, `tu '${userPrize.prizeName || 'premio'}'`);
                    } else {
                        personalizedBody = personalizedBody.replace(/{pending_prize}/g, 'tus beneficios');
                    }

                    const personalizedTitle = title.trim()
                        .replace(/{name}/g, userName)
                        .replace(/{nombre}/g, userName);

                    return {
                        token: u.fcmToken,
                        title: personalizedTitle,
                        body: personalizedBody,
                    };
                });

                if (recipients.length > 0) {
                    try {
                        const response = await fetch(vercelApiUrl.trim(), {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({
                                title: title.trim(),
                                body: body.trim(),
                                recipients: recipients,
                                notificationId: docRef.id,
                                customRoute: selectedPostId ? `/post/${selectedPostId}` : undefined,
                            }),
                        });
                        if (response.ok) {
                            const result = await response.json();
                            pushStatus = ` (+${result.successCount} push enviados exitosamente)`;
                        } else {
                            pushStatus = ' (Error al despachar push desde el proxy)';
                        }
                    } catch (err) {
                        pushStatus = ' (Error de conexión con el proxy Vercel)';
                        console.error('Push dispatch error:', err);
                    }
                }
            }

            setStatusMessage({ 
                type: 'success', 
                text: `¡Notificación programada/enviada exitosamente a ${targetUserCount} usuarios objetivo!${pushStatus}` 
            });
            setTitle('');
            setBody('');
            setImageUrl('');
            setSelectedPostId('');
            setMediaFile(null);
        } catch (error: any) {
            console.error("Error sending notification:", error);
            setStatusMessage({ type: 'error', text: `Error al enviar: ${error?.message || 'Revisa conexión/permisos'}` });
        } finally {
            setSending(false);
        }
    };

    const handleDelete = async (item: NotificationItem) => {
        if (confirm('¿Eliminar esta notificación del historial?')) {
            try {
                if (item.imageUrl) {
                    await deleteFromDrive(item.imageUrl);
                }
                await deleteDoc(doc(db, 'notifications', item.id));
            } catch (err) {
                console.error("Error deleting:", err);
            }
        }
    };

    return (
        <div className="space-y-10">
            {/* Formulario de Redacción */}
            <div className="bg-slate-800 rounded-2xl border border-slate-700 p-8 shadow-xl">
                <div className="flex justify-between items-center mb-6">
                    <h3 className="text-xl font-bold text-white flex items-center gap-2">
                        <span>📢</span> Notificación Segmentada
                    </h3>
                    <button
                        type="button"
                        onClick={() => setShowDriveSetup(!showDriveSetup)}
                        className="text-xs text-slate-400 hover:text-white bg-slate-700 px-3 py-1.5 rounded-lg transition-colors flex items-center gap-1"
                    >
                        ⚙️ Ajustes {driveConfigured ? '✅' : '❌'} {vercelApiUrl.trim() ? '✉️' : ''}
                    </button>
                </div>

                {showDriveSetup && (
                    <div className="mb-6 p-4 bg-slate-900 border border-slate-700 rounded-xl space-y-3">
                        <p className="text-xs font-semibold text-purple-400 uppercase">Configuración de Google Drive para Imágenes</p>
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                            <input
                                type="text"
                                placeholder="OAuth Client ID"
                                value={driveClientId}
                                onChange={(e) => setDriveClientId(e.target.value)}
                                className="px-3 py-2 bg-slate-800 border border-slate-700 rounded-lg text-xs text-white"
                            />
                            <input
                                type="text"
                                placeholder="Folder ID de Drive"
                                value={driveFolderId}
                                onChange={(e) => setDriveFolderId(e.target.value)}
                                className="px-3 py-2 bg-slate-800 border border-slate-700 rounded-lg text-xs text-white"
                            />
                        </div>

                        <p className="text-xs font-semibold text-purple-400 uppercase pt-2">Configuración de FCM Proxy (Vercel)</p>
                        <div className="grid grid-cols-1 gap-3">
                            <input
                                type="url"
                                placeholder="URL de la API en Vercel (Ej: https://dreamsclub.vercel.app/api/send-push)"
                                value={vercelApiUrl}
                                onChange={(e) => setVercelApiUrl(e.target.value)}
                                className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-lg text-xs text-white"
                            />
                        </div>

                        <button
                            type="button"
                            onClick={handleSaveDriveConfig}
                            className="px-4 py-2 bg-purple-600 hover:bg-purple-500 text-white rounded-lg text-xs font-medium"
                        >
                            Guardar Configuración
                        </button>
                    </div>
                )}

                {statusMessage && (
                    <div className={`p-4 rounded-xl mb-6 text-sm font-medium ${
                        statusMessage.type === 'success' 
                            ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30' 
                            : 'bg-rose-500/20 text-rose-300 border border-rose-500/30'
                    }`}>
                        {statusMessage.text}
                    </div>
                )}

                <form onSubmit={handleSend} className="space-y-6">
                    {/* Categoría */}
                    <div>
                        <label className="block text-slate-300 font-medium mb-2 text-sm">Categoría</label>
                        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                            {(['promo', 'event', 'info', 'alert'] as const).map((t) => (
                                <button
                                    key={t}
                                    type="button"
                                    onClick={() => setType(t)}
                                    className={`py-2 px-3 rounded-lg font-medium text-xs uppercase transition-colors ${
                                        type === t
                                            ? 'bg-purple-600 text-white font-bold'
                                            : 'bg-slate-900 text-slate-400 hover:bg-slate-700'
                                    }`}
                                >
                                    {t === 'promo' ? '🎁 Promoción' : t === 'event' ? '🎉 Evento' : t === 'info' ? 'ℹ️ Información' : '⚠️ Alerta'}
                                </button>
                            ))}
                        </div>
                    </div>

                    {/* Segmentación de Audiencia Objetivo */}
                    <div className="bg-slate-900 p-5 rounded-xl border border-slate-700 space-y-4">
                        <div className="flex justify-between items-center">
                            <label className="text-xs font-bold uppercase tracking-wider text-purple-400 flex items-center gap-2">
                                <span>🎯</span> Audiencia Objetivo & Segmentación
                            </label>
                            <span className="text-xs font-semibold px-3 py-1 bg-purple-500/20 border border-purple-500/30 text-purple-300 rounded-full">
                                Alcance Estimado: {targetUserCount} usuarios
                            </span>
                        </div>

                        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                            <div>
                                <label className="block text-xs text-slate-400 mb-1">Segmento por Racha</label>
                                <select
                                    value={targetStreak}
                                    onChange={(e) => setTargetStreak(e.target.value as any)}
                                    className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-lg text-xs text-white focus:outline-none focus:border-purple-500"
                                >
                                    <option value="all">🔥 Todos los usuarios</option>
                                    <option value="active">🔥 Racha Inicial (≥1 Día)</option>
                                    <option value="bronze">⭐ Racha Austral (≥3 Días)</option>
                                    <option value="silver">🏆 Leyenda Patagónica (≥7 Días)</option>
                                    <option value="gold">👑 Maestro de Coyhaique (≥14 Días)</option>
                                    <option value="platinum">💎 Racha VIP Máxima (≥30 Días)</option>
                                    <option value="none">❄️ Sin Racha (0 Días)</option>
                                </select>
                            </div>

                            <div>
                                <label className="block text-xs text-slate-400 mb-1">Segmento por Asistencia</label>
                                <select
                                    value={targetPresence}
                                    onChange={(e) => setTargetPresence(e.target.value as any)}
                                    className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-lg text-xs text-white focus:outline-none focus:border-purple-500"
                                >
                                    <option value="all">📍 Toda la asistencia</option>
                                    <option value="today">🏢 Presentes Hoy en Casino</option>
                                    <option value="inactive5">⏳ Inactivos (&gt;5 Días sin asistir)</option>
                                    <option value="inactive10">⚠️ Inactivos (&gt;10 Días sin asistir)</option>
                                </select>
                            </div>

                            <div className="flex items-end">
                                <label className="flex items-center gap-2 cursor-pointer bg-slate-800 px-3 py-2 rounded-lg border border-slate-700 text-xs text-slate-300 w-full">
                                    <input
                                        type="checkbox"
                                        checked={targetConsentOnly}
                                        onChange={(e) => setTargetConsentOnly(e.target.checked)}
                                        className="rounded text-purple-600 focus:ring-purple-500 bg-slate-900 border-slate-700"
                                    />
                                    <span>Solo si permite contacto</span>
                                </label>
                            </div>
                        </div>

                        {/* Fila 2 de Segmentos Avanzados */}
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 border-t border-slate-800 pt-4">
                            <div>
                                <label className="block text-xs text-slate-400 mb-1">Filtro por Edad</label>
                                <select
                                    value={targetAgeRange}
                                    onChange={(e) => setTargetAgeRange(e.target.value as any)}
                                    className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-lg text-xs text-white focus:outline-none focus:border-purple-500"
                                >
                                    <option value="all">🎂 Todas las edades</option>
                                    <option value="under30">🎂 Menores de 30 años</option>
                                    <option value="30to50">🎂 Entre 30 y 50 años</option>
                                    <option value="over50">🎂 Mayores de 50 años</option>
                                </select>
                            </div>

                            <div className="flex items-end">
                                <label className="flex items-center gap-2 cursor-pointer bg-slate-800 px-3 py-2 rounded-lg border border-slate-700 text-xs text-slate-300 w-full">
                                    <input
                                        type="checkbox"
                                        checked={targetBirthday}
                                        onChange={(e) => setTargetBirthday(e.target.checked)}
                                        className="rounded text-purple-600 focus:ring-purple-500 bg-slate-900 border-slate-700"
                                    />
                                    <span>🎂 Cumpleaños hoy</span>
                                </label>
                            </div>

                            <div className="flex items-end">
                                <label className="flex items-center gap-2 cursor-pointer bg-slate-800 px-3 py-2 rounded-lg border border-slate-700 text-xs text-slate-300 w-full">
                                    <input
                                        type="checkbox"
                                        checked={targetUnclaimedPrizes}
                                        onChange={(e) => {
                                            const val = e.target.checked;
                                            setTargetUnclaimedPrizes(val);
                                            if (val) {
                                                setTitle("¡Tienes un beneficio esperándote! 🎁");
                                                setBody("¡Hola {name}! Este fin de semana tenemos show de música en vivo a las 22:00. {pending_prize}¡Te esperamos!");
                                            }
                                        }}
                                        className="rounded text-purple-600 focus:ring-purple-500 bg-slate-900 border-slate-700"
                                    />
                                    <span>🎁 Con premios sin cobrar</span>
                                </label>
                            </div>
                        </div>
                    </div>

                    {/* Vincular Publicación */}
                    <div>
                        <label className="block text-slate-300 font-medium mb-2 text-sm">Vincular a Publicación Existente (Opcional)</label>
                        <select
                            value={selectedPostId}
                            onChange={(e) => {
                                const val = e.target.value;
                                setSelectedPostId(val);
                                if (val) {
                                    const post = posts.find(p => p.id === val);
                                    if (post) {
                                        setTitle(post.title);
                                        setBody(post.body || '');
                                    }
                                }
                            }}
                            className="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white focus:outline-none focus:border-purple-500"
                        >
                            <option value="">-- Ninguna (Notificación estándar) --</option>
                            {posts.map(p => (
                                <option key={p.id} value={p.id}>{p.title}</option>
                            ))}
                        </select>
                        <p className="mt-1 text-[10px] text-slate-500">
                            Si vinculas una publicación, cuando el usuario toque la notificación push en su celular, la app le abrirá directamente ese post.
                        </p>
                    </div>

                    {/* Título y Mensaje */}
                    <div>
                        <label className="block text-slate-300 font-medium mb-2 text-sm">Título de la Notificación</label>
                        <input
                            type="text"
                            required
                            value={title}
                            onChange={(e) => setTitle(e.target.value)}
                            placeholder="Ej: ¡Hoy noche de giros dobles!"
                            className="w-full px-4 py-2.5 bg-slate-900 border border-slate-700 rounded-xl text-white placeholder-slate-500 focus:outline-none focus:border-purple-500 text-sm"
                        />
                    </div>

                    <div>
                        <label className="block text-slate-300 font-medium mb-2 text-sm">Mensaje de la Notificación</label>
                        <textarea
                            required
                            rows={3}
                            value={body}
                            onChange={(e) => setBody(e.target.value)}
                            placeholder="Mensaje... (Usa {name} para el nombre del cliente, y {pending_prize} para mencionar su premio pendiente si tiene uno)"
                            className="w-full px-4 py-2.5 bg-slate-900 border border-slate-700 rounded-xl text-white placeholder-slate-500 focus:outline-none focus:border-purple-500 text-sm resize-none"
                        />
                    </div>

                    {/* Imagen */}
                    <div>
                        <label className="block text-slate-300 font-medium mb-2 text-sm">Imagen Adicional (Opcional)</label>
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <input
                                type="url"
                                value={imageUrl}
                                onChange={(e) => setImageUrl(e.target.value)}
                                placeholder="https://..."
                                className="w-full px-4 py-2.5 bg-slate-900 border border-slate-700 rounded-xl text-white placeholder-slate-500 focus:outline-none focus:border-purple-500 text-sm"
                            />
                            <input
                                type="file"
                                accept="image/*"
                                onChange={handleFileChange}
                                className="w-full px-4 py-2 bg-slate-900 border border-slate-700 rounded-xl text-xs text-slate-400 file:mr-4 file:py-1 file:px-3 file:rounded-lg file:border-0 file:text-xs file:font-semibold file:bg-purple-600 file:text-white hover:file:bg-purple-500"
                            />
                        </div>
                    </div>

                    <button
                        type="submit"
                        disabled={sending}
                        className="w-full py-3.5 px-6 rounded-xl bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-500 hover:to-pink-500 text-white font-semibold transition-all shadow-lg shadow-purple-500/25 hover:shadow-purple-500/40 disabled:opacity-50 flex items-center justify-center gap-2"
                    >
                        {sending ? (
                            <>
                                <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                                Enviando...
                            </>
                        ) : (
                            `🚀 Enviar Notificación a (${targetUserCount} Usuarios)`
                        )}
                    </button>
                </form>
            </div>

            {/* Programación de Campañas Automáticas */}
            <div className="bg-slate-800 rounded-2xl border border-slate-700 p-8 shadow-xl">
                <h3 className="text-xl font-bold text-white mb-6 flex items-center gap-2">
                    <span>⏰</span> Campañas Automáticas y Crons
                </h3>

                <form onSubmit={handleAddScheduledCampaign} className="space-y-4 mb-8 p-6 bg-slate-900 rounded-xl border border-slate-700">
                    <p className="text-xs font-semibold text-purple-400 uppercase">Nueva Campaña Programada / Recurrente</p>
                    
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                        <div>
                            <label className="block text-xs text-slate-400 mb-1">Tipo de Campaña</label>
                            <select
                                value={schedType}
                                onChange={(e) => setSchedType(e.target.value as any)}
                                className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-lg text-xs text-white focus:outline-none focus:border-purple-500"
                            >
                                <option value="birthday">🎂 Felicitación de Cumpleaños Diaria (10:00 AM)</option>
                                <option value="prize_reminder">🎁 Recordatorio de Premios por Vencer (Diaria)</option>
                                <option value="custom">📅 Notificación Especial en Fecha Única</option>
                            </select>
                        </div>

                        <div className="md:col-span-2">
                            <label className="block text-xs text-slate-400 mb-1">Título del Push</label>
                            <input
                                type="text"
                                required
                                value={schedTitle}
                                onChange={(e) => setSchedTitle(e.target.value)}
                                placeholder="Ej: ¡Feliz cumpleaños, {name}! 🎉"
                                className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-lg text-xs text-white focus:outline-none focus:border-purple-500"
                            />
                        </div>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                        <div className="md:col-span-2">
                            <label className="block text-xs text-slate-400 mb-1">Mensaje (Usa {"{name}"} para personalizar el nombre del cliente)</label>
                            <input
                                type="text"
                                required
                                value={schedBody}
                                onChange={(e) => setSchedBody(e.target.value)}
                                placeholder="Ej: Hola {name}, te deseamos lo mejor. Pasa hoy a cobrar tu regalo."
                                className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-lg text-xs text-white focus:outline-none focus:border-purple-500"
                            />
                        </div>

                        {schedType === 'custom' && (
                            <div>
                                <label className="block text-xs text-slate-400 mb-1">Fecha de Envío (AAAA-MM-DD)</label>
                                <input
                                    type="date"
                                    required
                                    value={schedDate}
                                    onChange={(e) => setSchedDate(e.target.value)}
                                    className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-lg text-xs text-white focus:outline-none focus:border-purple-500"
                                />
                            </div>
                        )}
                    </div>

                    <button
                        type="submit"
                        className="px-4 py-2 bg-purple-600 hover:bg-purple-500 text-white rounded-lg text-xs font-semibold"
                    >
                        Programar Campaña
                    </button>
                </form>

                {scheduledCampaigns.length === 0 ? (
                    <p className="text-slate-500 text-center py-4 text-xs">No hay campañas programadas activas.</p>
                ) : (
                    <div className="space-y-3">
                        {scheduledCampaigns.map((camp) => (
                            <div key={camp.id} className="p-4 bg-slate-900 border border-slate-700 rounded-xl flex items-center justify-between gap-4">
                                <div className="space-y-1">
                                    <div className="flex items-center gap-2">
                                        <span className="px-2 py-0.5 rounded text-[10px] uppercase font-bold bg-pink-500/20 text-pink-300 border border-pink-500/30">
                                            {camp.type === 'birthday' ? '🎂 Cumpleaños' : camp.type === 'prize_reminder' ? '🎁 Recordatorio' : '📅 Especial'}
                                        </span>
                                        <h4 className="font-semibold text-white text-sm">{camp.title}</h4>
                                    </div>
                                    <p className="text-slate-400 text-xs">{camp.body}</p>
                                    {camp.targetDate && (
                                        <p className="text-[10px] text-slate-500">📅 Programada para: {camp.targetDate}</p>
                                    )}
                                </div>

                                <button
                                    onClick={() => handleDeleteScheduledCampaign(camp.id)}
                                    className="text-slate-500 hover:text-red-400 p-1 text-xs"
                                    title="Eliminar"
                                >
                                    ❌
                                </button>
                            </div>
                        ))}
                    </div>
                )}
            </div>

            {/* Historial de Notificaciones */}
            <div className="bg-slate-800 rounded-2xl border border-slate-700 p-8 shadow-xl">
                <h3 className="text-xl font-bold text-white mb-6 flex items-center gap-2">
                    <span>📜</span> Historial de Notificaciones
                </h3>

                {history.length === 0 ? (
                    <p className="text-slate-500 text-center py-8">No hay notificaciones enviadas recientemente.</p>
                ) : (
                    <div className="space-y-4">
                        {history.map((item) => (
                            <div key={item.id} className="p-4 bg-slate-900 border border-slate-700 rounded-xl flex items-start justify-between gap-4">
                                <div className="space-y-1">
                                    <div className="flex items-center gap-2">
                                        <span className="px-2 py-0.5 rounded text-[10px] uppercase font-bold bg-purple-500/20 text-purple-300 border border-purple-500/30">
                                            {item.type || 'promo'}
                                        </span>
                                        <h4 className="font-semibold text-white text-sm">{item.title}</h4>
                                    </div>
                                    <p className="text-slate-400 text-xs">{item.body}</p>
                                    {item.targetSegment && (
                                        <div className="pt-1 flex flex-wrap gap-2 text-[10px] text-slate-500">
                                            <span>🎯 Racha: {item.targetSegment.streak || 'Todas'}</span>
                                            <span>• Presencia: {item.targetSegment.presence || 'Todas'}</span>
                                            <span>• Alcance: {item.targetSegment.estimatedReach || 0} usuarios</span>
                                        </div>
                                    )}
                                </div>

                                <button
                                    onClick={() => handleDelete(item)}
                                    className="text-slate-500 hover:text-red-400 p-1 text-xs"
                                    title="Eliminar"
                                >
                                    ❌
                                </button>
                            </div>
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
}
