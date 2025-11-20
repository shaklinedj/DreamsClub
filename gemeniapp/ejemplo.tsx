import React, { useState, useEffect, useRef } from 'react';
import {
    MapPin,
    Gift,
    User,
    QrCode,
    ChevronRight,
    Star,
    Coffee,
    Bed,
    Gamepad2,
    Bell,
    Settings,
    Camera,
    Navigation,
    LogOut,
    Check,
    Loader2,
    ChevronLeft,
    Sparkles,
    MessageSquare,
    Send,
    Bot,
    Utensils,
    Calendar,
    Users,
    Heart,
    Share2,
    PartyPopper,
    X,
    ThumbsUp,
    MessageCircle,
    MoreHorizontal
} from 'lucide-react';

// --- CONFIGURACIÓN Y DATOS ---

// MOCK DATA
const CASINO_NEWS = [
    {
        id: 1,
        casinoId: 'monticello',
        casinoName: "Dreams Monticello",
        title: "¡Este viernes sorteamos un BMW! 🚗",
        content: "No te pierdas la oportunidad de ganar el auto de tus sueños. Sorteo a las 23:00 hrs en el escenario principal. ¿Quién se lo lleva?",
        image: "car",
        time: "Hace 2 horas",
        likes: 124,
        shares: 15,
        isLiked: false,
        comments: [
            { user: "Carlos M.", text: "Yo voy fijo! 🍀", time: "1h" },
            { user: "Ana R.", text: "Ojalá tenga suerte esta vez 🙏", time: "30m" }
        ]
    },
    {
        id: 2,
        casinoId: 'valdivia',
        casinoName: "Dreams Valdivia",
        title: "Noche de Salsa en Sky Bar 💃",
        content: "Ven a disfrutar de los mejores ritmos latinos con banda en vivo y 2x1 en mojitos hasta la medianoche.",
        time: "Hace 5 horas",
        likes: 56,
        shares: 4,
        isLiked: false,
        comments: []
    },
    {
        id: 3,
        casinoId: 'monticello',
        casinoName: "Dreams Monticello",
        title: "Nuevo Buffet de Postres en El Capataz 🍰",
        content: "Hemos renovado nuestra estación dulce. ¡Ven a probar el nuevo Cheesecake de Maracuyá!",
        time: "Ayer",
        likes: 89,
        shares: 12,
        isLiked: false,
        comments: [
            { user: "Pedro P.", text: "Se ve buenísimo 😋", time: "1d" }
        ]
    },
];

const CASINOS = [
    {
        id: 'monticello',
        name: 'Monticello',
        city: 'San Fco. de Mostazal',
        region: 'Región de O\'Higgins',
        desc: 'El centro de entretención más grande de Latinoamérica.',
        features: ['Arena Monticello', 'Hotel 5 Estrellas', 'Paseo Murano', 'Zona VIP'],
        restaurants: [
            { name: 'Yann Yvin Brasserie', type: 'Francesa', desc: 'La calidez de Francia.' },
            { name: 'Olivera Pastas', type: 'Italiana', desc: 'Pastas de autor.' },
        ],
        events: [{ name: 'Gran Arena: Luis Miguel', date: '15 Nov', type: 'Concierto' }],
        hotel: { rooms: ['Suite Presidencial'], amenities: ['Piscina Temperada', 'Spa de Lujo'] }
    },
    {
        id: 'iquique',
        name: 'Dreams Iquique',
        city: 'Iquique',
        region: 'Región de Tarapacá',
        desc: 'A pasos de playa Cavancha, diversión frente al mar.',
        features: ['Playa Cavancha', 'Shows en Vivo', 'Gastronomía'],
        restaurants: [
            { name: 'Bar Lucky 7', type: 'Bar & Shows', desc: 'Coctelería de autor.' },
        ],
        events: [{ name: 'Noche de Tributos: Queen', date: 'Viernes', type: 'Música' }],
        hotel: { rooms: ['Ocean View King'], amenities: ['Acceso directo a Playa'] }
    },
    {
        id: 'temuco',
        name: 'Dreams Temuco',
        city: 'Temuco',
        region: 'Región de La Araucanía',
        desc: 'En el corazón de la Araucanía, lujo y cultura.',
        features: ['Spa Hydra', 'Centro de Eventos', 'Hotel Dreams'],
        restaurants: [{ name: 'In', type: 'Buffet', desc: 'Variedad de sabores del sur.' }],
        events: [{ name: 'Los Jaivas: Gira Nacional', date: '25 Abril', type: 'Concierto' }],
        hotel: { rooms: ['Suite Araucanía'], amenities: ['Hydra Spa'] }
    },
    {
        id: 'valdivia',
        name: 'Dreams Valdivia',
        city: 'Valdivia',
        region: 'Región de Los Ríos',
        desc: 'Ubicación privilegiada con vista al Río Calle-Calle.',
        features: ['Sky Bar', 'Vista al Río', 'Museo'],
        restaurants: [{ name: 'Sky Bar', type: 'Bar Panorámico', desc: 'La mejor vista.' }],
        events: [{ name: 'Luis Slimming', date: '08 Nov', type: 'Humor' }],
        hotel: { rooms: ['River View Suite'], amenities: ['Museo Subterráneo'] }
    }
];

const OFFERS = [
    { id: 1, title: '30% Dcto. en Bar Lucky 7', type: 'Gastronomía', icon: <Coffee size={20} />, validity: 'Vence en 3 días', pointsCost: 0 },
    { id: 2, title: 'Noche Gratis - Hotel Dreams', type: 'Hotel', icon: <Bed size={20} />, validity: 'Válido todo el año', pointsCost: 60000 },
    { id: 3, title: '$10.000 Créditos Promocionales', type: 'Juego', icon: <Gamepad2 size={20} />, validity: 'Vence hoy', pointsCost: 5000 }
];

// --- COMPONENTS ---

const TabButton = ({ active, icon, label, onClick, notification }) => (
    <button
        onClick={onClick}
        className={`flex flex-col items-center justify-center w-full py-3 transition-colors duration-300 relative ${active ? 'text-[#D4AF37]' : 'text-gray-400 hover:text-gray-200'
            }`}
    >
        {notification && (
            <span className="absolute top-2 right-4 w-2 h-2 bg-red-500 rounded-full animate-pulse"></span>
        )}
        {icon}
        <span className="text-[10px] mt-1 font-medium">{label}</span>
    </button>
);

const StatusBadge = ({ tier }) => {
    const colors = {
        'Gold': 'bg-yellow-600 text-white',
        'Platinum': 'bg-slate-300 text-slate-800',
        'Black': 'bg-gray-900 text-white border border-gray-700',
        'One': 'bg-white text-black border border-yellow-500'
    };

    return (
        <span className={`px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider ${colors[tier] || colors['Gold']}`}>
            {tier} Member
        </span>
    );
};

const ToggleSwitch = ({ checked, onChange, loading }) => (
    <button
        onClick={!loading ? onChange : undefined}
        className={`w-12 h-6 rounded-full p-1 transition-colors duration-300 relative ${checked ? 'bg-[#D4AF37]' : 'bg-gray-700'}`}
    >
        {loading ? (
            <div className="absolute inset-0 flex items-center justify-center">
                <Loader2 size={12} className="animate-spin text-black" />
            </div>
        ) : (
            <div className={`w-4 h-4 bg-white rounded-full shadow-md transform transition-transform duration-300 ${checked ? 'translate-x-6' : 'translate-x-0'}`} />
        )}
    </button>
);

// --- MOCK API ---
const callGeminiMock = async (prompt) => {
    return new Promise(resolve => {
        setTimeout(() => resolve(`¡Hola! Soy el Concierge IA. Veo que te interesa: "${prompt}". Te recomiendo visitar el Bar Lucky 7 hoy.`), 1000);
    });
};

// --- COMPONENTE PRINCIPAL ---

export default function DreamsLoyaltyApp() {
    const [activeTab, setActiveTab] = useState('home');
    const [selectedCasino, setSelectedCasino] = useState(null);

    const [user, setUser] = useState({
        name: 'Juan Pérez',
        tier: 'Platinum',
        points: 45250,
        nextTierPoints: 60000,
        favoriteCasinoId: 'monticello',
        birthDate: new Date().toISOString().slice(0, 10)
    });

    // Modals State
    const [showQR, setShowQR] = useState(false);
    const [showChat, setShowChat] = useState(false);
    const [showNotificationsPanel, setShowNotificationsPanel] = useState(false);
    const [settings, setSettings] = useState({ gps: false, camera: false, notifications: true });

    // Data State
    const [newsFeed, setNewsFeed] = useState(CASINO_NEWS);
    const [notifications, setNotifications] = useState([]);
    const [commentInput, setCommentInput] = useState("");
    const [activeCommentBox, setActiveCommentBox] = useState(null);

    // Chat State
    const [chatMessages, setChatMessages] = useState([{ role: 'model', text: `¡Hola ${user.name}! ✨ Soy tu Concierge Dreams.` }]);
    const [chatInput, setChatInput] = useState('');
    const [isTyping, setIsTyping] = useState(false);
    const chatEndRef = useRef(null);

    useEffect(() => {
        chatEndRef.current?.scrollIntoView({ behavior: "smooth" });
    }, [chatMessages, showChat]);

    // Simulación Inicial
    useEffect(() => {
        const today = new Date().toISOString().slice(0, 10);
        if (user.birthDate === today) {
            setNotifications(prev => [{
                id: 'bday', type: 'birthday', title: '¡Feliz Cumpleaños Juan! 🎂',
                message: 'Te regalamos una Cena Doble + $20.000 jugables.',
                action: 'Canjear Ahora', icon: <PartyPopper className="text-pink-500" />
            }, ...prev]);
        }

        const timer = setTimeout(() => {
            const nearestCasino = CASINOS.find(c => c.city === 'Valdivia');
            if (nearestCasino) {
                setNotifications(prev => [{
                    id: `geo-${Date.now()}`, type: 'location', title: '¡Estás en Valdivia! 📍',
                    message: `Detectamos que estás cerca de ${nearestCasino.name}. ¿Quieres ver qué hay hoy?`,
                    action: 'Ver Casino', icon: <MapPin className="text-blue-400" />, data: nearestCasino
                }, ...prev]);
            }
        }, 6000);

        return () => clearTimeout(timer);
    }, []);

    const handleSendChat = async () => {
        if (!chatInput.trim()) return;
        const userMsg = { role: 'user', text: chatInput };
        setChatMessages(prev => [...prev, userMsg]);
        setChatInput('');
        setIsTyping(true);
        const responseText = await callGeminiMock(userMsg.text);
        setChatMessages(prev => [...prev, { role: 'model', text: responseText }]);
        setIsTyping(false);
    };

    const toggleLike = (postId) => {
        setNewsFeed(prev => prev.map(post => {
            if (post.id === postId) {
                const isLiked = !post.isLiked;
                return { ...post, isLiked, likes: isLiked ? post.likes + 1 : post.likes - 1 };
            }
            return post;
        }));
    };

    const handlePostComment = (postId) => {
        if (!commentInput.trim()) return;
        setNewsFeed(prev => prev.map(post => {
            if (post.id === postId) {
                return { ...post, comments: [...post.comments, { user: "Tú", text: commentInput, time: "Ahora" }] };
            }
            return post;
        }));
        setCommentInput("");
    };

    const handleNotificationClick = (notif) => {
        if (notif.type === 'location' && notif.data) {
            setSelectedCasino(notif.data);
            setShowNotificationsPanel(false);
        }
        setNotifications(prev => prev.filter(n => n.id !== notif.id));
    };

    // --- RENDERS ---

    const renderHome = () => (
        <div className="space-y-6 pb-20 animate-fade-in">
            {/* Header Card */}
            <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-[#1a1a1a] to-[#000] border border-[#D4AF37]/30 shadow-2xl shadow-[#D4AF37]/10 p-6 mx-4 mt-4">
                <div className="absolute top-0 right-0 -mt-4 -mr-4 w-32 h-32 bg-[#D4AF37] rounded-full blur-3xl opacity-20"></div>
                <div className="flex justify-between items-start mb-6 relative z-10">
                    <div>
                        <p className="text-gray-400 text-sm">Bienvenido de nuevo,</p>
                        <h2 className="text-2xl font-bold text-white">{user.name}</h2>
                    </div>
                    <div className="flex gap-3 items-center">
                        <button onClick={() => setShowNotificationsPanel(true)} className="relative p-2 bg-white/5 rounded-full hover:bg-white/10 border border-gray-700">
                            <Bell size={20} className="text-white" />
                            {notifications.length > 0 && <span className="absolute top-0 right-0 w-3 h-3 bg-red-500 border-2 border-black rounded-full"></span>}
                        </button>
                        <StatusBadge tier={user.tier} />
                    </div>
                </div>
                <div className="relative z-10">
                    <p className="text-gray-400 text-xs uppercase tracking-widest mb-1">Puntos Dreams</p>
                    <div className="flex items-baseline gap-2">
                        <span className="text-4xl font-bold text-[#D4AF37]">{user.points.toLocaleString()}</span>
                        <span className="text-sm text-gray-400">pts</span>
                    </div>
                </div>
                <div className="mt-6 relative z-10">
                    <div className="flex justify-between text-xs text-gray-400 mb-2">
                        <span>Progreso a nivel One</span>
                        <span>{user.nextTierPoints.toLocaleString()} pts</span>
                    </div>
                    <div className="h-2 bg-gray-800 rounded-full overflow-hidden">
                        <div className="h-full bg-gradient-to-r from-[#D4AF37] to-[#FFD700]" style={{ width: '75%' }}></div>
                    </div>
                </div>
            </div>

            <div className="px-4">
                <button onClick={() => setShowChat(true)} className="w-full bg-gradient-to-r from-indigo-900 via-purple-900 to-indigo-900 p-1 rounded-xl shadow-lg group relative overflow-hidden text-left">
                    <div className="bg-[#121212] rounded-[10px] p-4 flex items-center justify-between relative z-10">
                        <div className="flex items-center gap-3">
                            <Sparkles size={20} className="text-indigo-400 animate-pulse" />
                            <div>
                                <h3 className="text-white font-bold text-sm">Dreams Concierge AI</h3>
                                <p className="text-xs text-indigo-300">Tu asistente personal 24/7</p>
                            </div>
                        </div>
                        <ChevronRight className="text-indigo-400" size={20} />
                    </div>
                </button>
            </div>

            <div className="grid grid-cols-2 gap-4 px-4">
                <button onClick={() => setShowQR(true)} className="flex items-center justify-center gap-3 bg-[#2a2a2a] hover:bg-[#333] text-white p-4 rounded-xl border border-gray-800 transition-all active:scale-95">
                    <QrCode className="text-[#D4AF37]" />
                    <span className="font-medium">Tarjeta Digital</span>
                </button>
                <button onClick={() => setActiveTab('rewards')} className="flex items-center justify-center gap-3 bg-[#2a2a2a] hover:bg-[#333] text-white p-4 rounded-xl border border-gray-800 transition-all active:scale-95">
                    <Gift className="text-[#D4AF37]" />
                    <span className="font-medium">Mis Canjes</span>
                </button>
            </div>

            {/* Destacado */}
            <div className="px-4">
                <h3 className="text-lg font-bold text-white mb-4 flex items-center gap-2">Destacado para ti</h3>
                <div className="bg-[#1a1a1a] rounded-xl p-4 border border-gray-800 flex gap-4 items-center">
                    <div className="bg-[#D4AF37]/20 p-3 rounded-lg text-[#D4AF37]"><PartyPopper size={24} /></div>
                    <div className="flex-1">
                        <h4 className="text-white font-bold">Sorteo BMW</h4>
                        <p className="text-sm text-gray-400">Viernes en Monticello</p>
                    </div>
                    <ChevronRight className="text-gray-600" />
                </div>
            </div>
        </div>
    );

    const renderSocialTab = () => {
        const filteredNews = newsFeed.filter(news => news.casinoId === user.favoriteCasinoId);
        return (
            <div className="pb-20 animate-fade-in pt-4 bg-[#121212] min-h-screen">
                <div className="px-4 mb-4">
                    <h2 className="text-2xl font-bold text-white mb-1">Muro de Novedades</h2>
                    <p className="text-xs text-gray-400 flex items-center gap-1">
                        Viendo novedades de <span className="text-[#D4AF37] font-bold">Dreams {CASINOS.find(c => c.id === user.favoriteCasinoId)?.name}</span>
                        <ChevronRight size={12} />
                    </p>
                </div>

                <div className="space-y-4 px-4">
                    {filteredNews.map((post) => (
                        <div key={post.id} className="bg-[#1a1a1a] rounded-xl overflow-hidden border border-gray-800">
                            <div className="p-3 flex items-center justify-between">
                                <div className="flex items-center gap-2">
                                    <div className="w-10 h-10 rounded-full bg-[#D4AF37] flex items-center justify-center text-black font-bold border-2 border-white/10">D</div>
                                    <div>
                                        <h3 className="text-white font-bold text-sm leading-tight">{post.casinoName}</h3>
                                        <p className="text-xs text-gray-400 flex items-center gap-1">{post.time} • <MapPin size={10} /></p>
                                    </div>
                                </div>
                                <button className="text-gray-400 hover:bg-white/10 p-2 rounded-full"><MoreHorizontal size={20} /></button>
                            </div>

                            <div className="px-3 pb-2">
                                <h4 className="text-white font-bold mb-1">{post.title}</h4>
                                <p className="text-white text-sm leading-relaxed">{post.content}</p>
                            </div>

                            <div className="px-3 py-2 flex justify-between items-center text-xs text-gray-400 border-b border-gray-700 mx-3">
                                <div className="flex items-center gap-1">
                                    <div className="bg-blue-500 p-1 rounded-full"><ThumbsUp size={8} className="text-white fill-white" /></div>
                                    <span>{post.likes}</span>
                                </div>
                                <div className="flex gap-3">
                                    <span>{post.comments.length} comentarios</span>
                                    <span>{post.shares} veces compartido</span>
                                </div>
                            </div>

                            <div className="flex px-2 py-1">
                                <button onClick={() => toggleLike(post.id)} className={`flex-1 flex items-center justify-center gap-2 py-2 rounded-lg hover:bg-white/10 transition-colors ${post.isLiked ? 'text-blue-400' : 'text-gray-400'}`}>
                                    <ThumbsUp size={18} className={post.isLiked ? "fill-blue-400" : ""} />
                                    <span className="text-xs font-bold">Me gusta</span>
                                </button>
                                <button onClick={() => setActiveCommentBox(activeCommentBox === post.id ? null : post.id)} className="flex-1 flex items-center justify-center gap-2 py-2 rounded-lg hover:bg-white/10 transition-colors text-gray-400">
                                    <MessageCircle size={18} />
                                    <span className="text-xs font-bold">Comentar</span>
                                </button>
                                <button className="flex-1 flex items-center justify-center gap-2 py-2 rounded-lg hover:bg-white/10 transition-colors text-gray-400">
                                    <Share2 size={18} />
                                    <span className="text-xs font-bold">Compartir</span>
                                </button>
                            </div>

                            {activeCommentBox === post.id && (
                                <div className="bg-[#222] p-3 border-t border-gray-800 animate-fade-in">
                                    {post.comments.map((comment, idx) => (
                                        <div key={idx} className="flex gap-2 mb-3">
                                            <div className="w-8 h-8 rounded-full bg-gray-600 flex-shrink-0 flex items-center justify-center text-xs font-bold text-white">{comment.user.charAt(0)}</div>
                                            <div>
                                                <div className="bg-[#333] px-3 py-2 rounded-2xl rounded-tl-none inline-block">
                                                    <p className="text-white text-xs font-bold">{comment.user}</p>
                                                    <p className="text-gray-200 text-sm">{comment.text}</p>
                                                </div>
                                                <div className="flex gap-3 ml-2 mt-1">
                                                    <span className="text-[10px] text-gray-500 font-bold hover:underline cursor-pointer">Me gusta</span>
                                                    <span className="text-[10px] text-gray-500 font-bold hover:underline cursor-pointer">Responder</span>
                                                    <span className="text-[10px] text-gray-500">{comment.time}</span>
                                                </div>
                                            </div>
                                        </div>
                                    ))}
                                    <div className="flex gap-2 items-center mt-2">
                                        <div className="w-8 h-8 rounded-full bg-gray-700 flex-shrink-0 flex items-center justify-center text-xs text-white">Y</div>
                                        <div className="flex-1 bg-[#333] rounded-full flex items-center px-3 py-1 border border-gray-600">
                                            <input type="text" value={commentInput} onChange={(e) => setCommentInput(e.target.value)} onKeyPress={(e) => e.key === 'Enter' && handlePostComment(post.id)} placeholder="Escribe un comentario..." className="bg-transparent text-white text-sm w-full outline-none placeholder-gray-500 py-1" />
                                            <button onClick={() => handlePostComment(post.id)} className="text-blue-400 p-1 disabled:opacity-50" disabled={!commentInput.trim()}><Send size={16} /></button>
                                        </div>
                                    </div>
                                </div>
                            )}
                        </div>
                    ))}
                </div>
            </div>
        );
    };

    const renderCasinosList = () => (
        <div className="pb-20 px-4 pt-4 space-y-4">
            <h2 className="text-2xl font-bold text-white mb-6">Casinos</h2>
            {CASINOS.map(c => (
                <div key={c.id} onClick={() => setSelectedCasino(c)} className="bg-[#1a1a1a] p-4 rounded-xl border border-gray-800 flex justify-between items-center cursor-pointer hover:bg-[#222]">
                    <div>
                        <h3 className="text-white font-bold">{c.name}</h3>
                        <p className="text-gray-400 text-sm">{c.city}</p>
                    </div>
                    <ChevronRight className="text-gray-600" />
                </div>
            ))}
        </div>
    );

    const renderRewards = () => (
        <div className="pb-20 animate-fade-in px-4 pt-4">
            <div className="flex justify-between items-center mb-6">
                <h2 className="text-2xl font-bold text-white">Beneficios</h2>
                <div className="bg-gray-800 px-3 py-1 rounded-full text-xs text-[#D4AF37] font-mono">Saldo: {user.points.toLocaleString()}</div>
            </div>
            <div className="space-y-4">
                {OFFERS.map((offer) => (
                    <div key={offer.id} className="bg-[#1a1a1a] p-4 rounded-xl border border-gray-800 flex gap-4">
                        <div className="bg-gray-800 h-16 w-16 rounded-lg flex items-center justify-center flex-shrink-0 text-[#D4AF37]">{offer.icon}</div>
                        <div className="flex-1">
                            <div className="flex justify-between items-start">
                                <h4 className="text-white font-bold">{offer.title}</h4>
                                {offer.pointsCost > 0 ? (
                                    <span className="text-xs font-bold text-[#D4AF37] bg-[#D4AF37]/10 px-2 py-1 rounded">{offer.pointsCost.toLocaleString()} pts</span>
                                ) : (
                                    <span className="text-xs font-bold text-green-400 bg-green-400/10 px-2 py-1 rounded">GRATIS</span>
                                )}
                            </div>
                            <p className="text-xs text-gray-500 mt-1">{offer.type}</p>
                            <p className="text-xs text-gray-400 mt-2 flex items-center gap-1"><Bell size={10} /> {offer.validity}</p>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );

    const renderProfile = () => (
        <div className="flex flex-col items-center justify-center h-full pt-20 pb-20 text-center px-6 animate-fade-in">
            <div className="w-24 h-24 bg-gray-800 rounded-full flex items-center justify-center mb-4 border-2 border-[#D4AF37] relative">
                <User size={40} className="text-[#D4AF37]" />
                <div className="absolute bottom-0 right-0 bg-black border border-gray-700 p-1.5 rounded-full"><Settings size={12} className="text-gray-400" /></div>
            </div>
            <h2 className="text-2xl text-white font-bold">{user.name}</h2>
            <p className="text-gray-500">{user.tier} Member</p>
            <div className="w-full mt-8 space-y-2 text-left">
                <button className="w-full p-4 bg-[#1a1a1a] hover:bg-[#222] rounded-lg flex justify-between items-center border border-gray-800 transition-colors">
                    <div className="flex items-center gap-3"><User size={18} className="text-gray-400" /><span className="text-white">Editar Perfil</span></div>
                    <ChevronRight size={16} className="text-gray-500" />
                </button>
                <button className="w-full p-4 bg-[#1a1a1a] hover:bg-[#222] rounded-lg flex justify-between items-center border border-gray-800 transition-colors">
                    <div className="flex items-center gap-3"><Gamepad2 size={18} className="text-gray-400" /><span className="text-white">Historial de Juego</span></div>
                    <ChevronRight size={16} className="text-gray-500" />
                </button>
                <button className="w-full p-4 bg-[#1a1a1a] hover:bg-[#222] rounded-lg flex justify-between items-center border border-gray-800 transition-colors">
                    <div className="flex items-center gap-3"><Settings size={18} className="text-gray-400" /><span className="text-white">Configuración</span></div>
                    <ChevronRight size={16} className="text-gray-500" />
                </button>
                <button className="w-full p-4 bg-red-900/10 hover:bg-red-900/20 text-red-400 rounded-lg flex justify-between items-center border border-red-900/30 mt-4 transition-colors">
                    <div className="flex items-center gap-3"><LogOut size={18} /><span>Cerrar Sesión</span></div>
                </button>
            </div>
        </div>
    );

    const renderCasinoDetail = () => (
        <div className="pb-20 bg-[#121212] min-h-screen flex flex-col">
            <div className="h-48 bg-gray-800 relative">
                <button onClick={() => setSelectedCasino(null)} className="absolute top-4 left-4 bg-black/50 p-2 rounded-full text-white hover:bg-black/70 z-10"><ChevronLeft /></button>
                <div className="absolute bottom-4 left-4 z-10">
                    <h2 className="text-3xl font-bold text-white">{selectedCasino.name}</h2>
                    <p className="text-[#D4AF37]">{selectedCasino.city}</p>
                </div>
                <div className="absolute inset-0 bg-gradient-to-t from-[#121212] to-transparent"></div>
            </div>
            <div className="p-6 space-y-6">
                <p className="text-gray-300 leading-relaxed">{selectedCasino.desc}</p>
                <div>
                    <h3 className="text-lg font-bold text-white mb-3 flex items-center gap-2"><Utensils size={18} className="text-[#D4AF37]" /> Gastronomía</h3>
                    {selectedCasino.restaurants.length > 0 ? selectedCasino.restaurants.map((r, i) => (
                        <div key={i} className="bg-[#1a1a1a] p-4 rounded-xl border border-gray-800 mb-2">
                            <h4 className="font-bold text-white">{r.name}</h4>
                            <p className="text-sm text-gray-400">{r.desc}</p>
                        </div>
                    )) : <p className="text-gray-500">Información no disponible</p>}
                </div>
                <div>
                    <h3 className="text-lg font-bold text-white mb-3 flex items-center gap-2"><Calendar size={18} className="text-[#D4AF37]" /> Eventos</h3>
                    {selectedCasino.events.length > 0 ? selectedCasino.events.map((e, i) => (
                        <div key={i} className="bg-[#1a1a1a] p-3 rounded-xl border border-gray-800 flex items-center gap-4 mb-2">
                            <div className="bg-indigo-900/30 p-2 rounded text-center min-w-[50px]"><span className="text-xs font-bold text-indigo-400 uppercase">{e.date}</span></div>
                            <div><h4 className="font-bold text-white text-sm">{e.name}</h4><p className="text-xs text-gray-400">{e.type}</p></div>
                        </div>
                    )) : <p className="text-gray-500">No hay eventos próximos.</p>}
                </div>
            </div>
        </div>
    );

    // --- MODALES ---

    const renderQRModal = () => (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/90 backdrop-blur-sm p-6 animate-fade-in">
            <div className="bg-white rounded-3xl w-full max-w-sm overflow-hidden shadow-2xl relative">
                <button onClick={() => setShowQR(false)} className="absolute top-4 right-4 bg-gray-100 p-2 rounded-full text-gray-600 hover:bg-gray-200">✕</button>
                <div className="bg-[#1a1a1a] p-6 text-center"><h3 className="text-[#D4AF37] text-xl font-bold tracking-widest uppercase">Dreams Club</h3><p className="text-gray-400 text-sm mt-1">Tarjeta de Socio Digital</p></div>
                <div className="p-8 flex flex-col items-center">
                    <div className="border-4 border-black p-2 rounded-xl mb-4"><QrCode size={200} className="text-black" /></div>
                    <p className="text-2xl font-mono font-bold text-gray-800 tracking-widest">7784 9920 1123</p>
                    <p className="text-gray-500 text-sm mt-2">{user.name}</p>
                    <div className="mt-4 px-4 py-1 bg-black text-[#D4AF37] rounded-full text-xs font-bold uppercase">Nivel {user.tier}</div>
                </div>
            </div>
        </div>
    );

    const renderChatModal = () => (
        <div className="fixed inset-0 z-50 flex flex-col bg-[#121212] animate-fade-in">
            <div className="bg-[#1a1a1a] p-4 flex items-center justify-between border-b border-gray-800 shadow-md">
                <div className="flex items-center gap-3">
                    <div className="bg-indigo-600 p-2 rounded-full"><Bot size={20} className="text-white" /></div>
                    <div><h3 className="text-white font-bold">Dreams Concierge ✨</h3><p className="text-xs text-green-400 flex items-center gap-1"><span className="w-2 h-2 bg-green-400 rounded-full"></span> En línea</p></div>
                </div>
                <button onClick={() => setShowChat(false)} className="text-gray-400 hover:text-white p-2">✕</button>
            </div>
            <div className="flex-1 overflow-y-auto p-4 space-y-4">
                {chatMessages.map((msg, idx) => (
                    <div key={idx} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
                        <div className={`max-w-[80%] p-3 rounded-2xl ${msg.role === 'user' ? 'bg-[#D4AF37] text-black rounded-tr-none' : 'bg-gray-800 text-gray-200 rounded-tl-none border border-gray-700'}`}>
                            <p className="text-sm">{msg.text}</p>
                        </div>
                    </div>
                ))}
                {isTyping && <div className="flex justify-start"><div className="bg-gray-800 p-3 rounded-2xl rounded-tl-none border border-gray-700 flex gap-1"><span className="w-2 h-2 bg-gray-500 rounded-full animate-bounce"></span><span className="w-2 h-2 bg-gray-500 rounded-full animate-bounce delay-75"></span><span className="w-2 h-2 bg-gray-500 rounded-full animate-bounce delay-150"></span></div></div>}
                <div ref={chatEndRef} />
            </div>
            <div className="p-4 bg-[#1a1a1a] border-t border-gray-800">
                <div className="flex items-center gap-2 bg-black rounded-full px-4 py-2 border border-gray-700">
                    <MessageSquare size={20} className="text-gray-500" />
                    <input type="text" value={chatInput} onChange={(e) => setChatInput(e.target.value)} onKeyPress={(e) => e.key === 'Enter' && handleSendChat()} placeholder="Escribe tu consulta..." className="flex-1 bg-transparent text-white outline-none text-sm placeholder-gray-500" />
                    <button onClick={handleSendChat} disabled={!chatInput.trim() || isTyping} className="text-[#D4AF37] disabled:opacity-50 hover:scale-110 transition-transform"><Send size={20} /></button>
                </div>
            </div>
        </div>
    );

    const renderNotificationsPanel = () => (
        <div className="fixed inset-0 z-50 bg-black/95 backdrop-blur-md flex justify-end animate-fade-in">
            <div className="w-full max-w-xs bg-[#121212] h-full shadow-2xl border-l border-gray-800 flex flex-col">
                <div className="p-4 border-b border-gray-800 flex justify-between items-center">
                    <h3 className="text-white font-bold text-lg">Notificaciones</h3>
                    <button onClick={() => setShowNotificationsPanel(false)} className="p-2 hover:bg-gray-800 rounded-full"><X className="text-gray-400" /></button>
                </div>
                <div className="flex-1 overflow-y-auto p-4 space-y-3">
                    {notifications.length === 0 ? (
                        <div className="text-center py-10 text-gray-500"><Bell size={40} className="mx-auto mb-4 opacity-20" /><p>No tienes notificaciones nuevas</p></div>
                    ) : (
                        notifications.map(notif => (
                            <div key={notif.id} onClick={() => handleNotificationClick(notif)} className="bg-[#1a1a1a] p-4 rounded-xl border border-gray-800 hover:bg-[#222] cursor-pointer transition-colors relative overflow-hidden">
                                {notif.type === 'birthday' && <div className="absolute left-0 top-0 bottom-0 w-1 bg-pink-500"></div>}
                                {notif.type === 'location' && <div className="absolute left-0 top-0 bottom-0 w-1 bg-blue-500"></div>}
                                <div className="flex gap-3 mb-2">
                                    <div className="mt-1">{notif.icon}</div>
                                    <div><h4 className="text-white font-bold text-sm">{notif.title}</h4><p className="text-gray-400 text-xs leading-relaxed">{notif.message}</p></div>
                                </div>
                                {notif.action && <div className="mt-2 flex justify-end"><span className="text-[#D4AF37] text-xs font-bold flex items-center gap-1">{notif.action} <ChevronRight size={12} /></span></div>}
                            </div>
                        ))
                    )}
                </div>
            </div>
        </div>
    );

    return (
        <div className="min-h-screen bg-black text-gray-200 font-sans selection:bg-[#D4AF37] selection:text-black">
            <main className="max-w-md mx-auto min-h-screen bg-[#121212] relative shadow-2xl shadow-black overflow-hidden">
                {showQR && renderQRModal()}
                {showChat && renderChatModal()}
                {showNotificationsPanel && renderNotificationsPanel()}

                {selectedCasino ? renderCasinoDetail() : (
                    <>
                        {activeTab === 'home' && renderHome()}
                        {activeTab === 'social' && renderSocialTab()}
                        {activeTab === 'casinos' && renderCasinosList()}
                        {activeTab === 'rewards' && renderRewards()}
                        {activeTab === 'profile' && renderProfile()}
                    </>
                )}

                {!selectedCasino && activeTab !== 'settings' && !showChat && (
                    <div className="fixed bottom-0 left-0 right-0 bg-[#0a0a0a]/95 backdrop-blur-md border-t border-gray-800 z-40 max-w-md mx-auto">
                        <div className="flex justify-between items-center px-6 pb-safe">
                            <TabButton active={activeTab === 'home'} onClick={() => setActiveTab('home')} icon={<Star size={24} />} label="Inicio" />
                            <TabButton active={activeTab === 'social'} onClick={() => setActiveTab('social')} icon={<Users size={24} />} label="Social" />
                            <div className="relative -top-6"><button onClick={() => setShowQR(true)} className="bg-[#D4AF37] hover:bg-[#b5952f] text-black p-4 rounded-full shadow-lg shadow-[#D4AF37]/20 transition-transform active:scale-95 border-4 border-[#121212]"><QrCode size={28} /></button></div>
                            <TabButton active={activeTab === 'casinos'} onClick={() => setActiveTab('casinos')} icon={<MapPin size={24} />} label="Casinos" notification={false} />
                            <TabButton active={activeTab === 'profile'} onClick={() => setActiveTab('profile')} icon={<User size={24} />} label="Perfil" />
                        </div>
                    </div>
                )}
            </main>
            <style>{`
        @keyframes fade-in { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
        .animate-fade-in { animation: fade-in 0.3s ease-out forwards; }
        .pb-safe { padding-bottom: env(safe-area-inset-bottom, 20px); }
      `}</style>
        </div>
    );
}