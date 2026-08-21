import React, { useState, useEffect } from 'react';

// Tipos básicos para la Cartelera
interface CarteleraItem {
  id: string;
  title: string;
  imageUrl: string;
  casino: string;
  isActive: boolean;
  order: number;
}

export default function CarteleraManager() {
  const [items, setItems] = useState<CarteleraItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({
    title: '',
    imageUrl: '',
    casino: 'Coyhaique',
    order: 0,
  });

  // En un entorno real, aquí se importaría la app de Firebase e inicializaría Firestore
  useEffect(() => {
    // Simular carga inicial desde Firebase
    setLoading(true);
    setTimeout(() => {
      setItems([
        { id: '1', title: 'Gran Sorteo Coyhaique', imageUrl: 'https://picsum.photos/1080/1920', casino: 'Coyhaique', isActive: true, order: 1 },
        { id: '2', title: 'Torneo de Poker', imageUrl: 'https://picsum.photos/1080/1921', casino: 'Coyhaique', isActive: true, order: 2 },
      ]);
      setLoading(false);
    }, 1000);
  }, []);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Simular añadir a Firebase
    const newItem: CarteleraItem = {
      id: Math.random().toString(36).substr(2, 9),
      ...formData,
      isActive: true,
    };
    setItems([...items, newItem]);
    setShowForm(false);
    setFormData({ title: '', imageUrl: '', casino: 'Coyhaique', order: 0 });
  };

  return (
    <div className="space-y-6">
      {/* Botón Nueva Cartelera */}
      <div className="flex justify-end">
        <button 
          onClick={() => setShowForm(!showForm)}
          className="bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded-lg font-medium transition-colors"
        >
          {showForm ? 'Cancelar' : '+ Nuevo Banner'}
        </button>
      </div>

      {/* Formulario */}
      {showForm && (
        <div className="bg-slate-800 p-6 rounded-xl border border-slate-700">
          <h3 className="text-xl font-bold text-white mb-4">Añadir Banner a Cartelera</h3>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-slate-400 mb-1">Título</label>
                <input 
                  type="text" 
                  value={formData.title}
                  onChange={(e) => setFormData({...formData, title: e.target.value})}
                  className="w-full bg-slate-900 border border-slate-700 rounded-lg px-4 py-2 text-white focus:border-purple-500 focus:outline-none" 
                  required 
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-400 mb-1">Sucursal</label>
                <select 
                  value={formData.casino}
                  onChange={(e) => setFormData({...formData, casino: e.target.value})}
                  className="w-full bg-slate-900 border border-slate-700 rounded-lg px-4 py-2 text-white focus:border-purple-500 focus:outline-none"
                >
                  <option value="Coyhaique">Coyhaique</option>
                  <option value="Punta Arenas">Punta Arenas</option>
                  <option value="Temuco">Temuco</option>
                </select>
              </div>
              <div className="md:col-span-2">
                <label className="block text-sm font-medium text-slate-400 mb-1">URL de la Imagen / Video</label>
                <input 
                  type="url" 
                  value={formData.imageUrl}
                  onChange={(e) => setFormData({...formData, imageUrl: e.target.value})}
                  className="w-full bg-slate-900 border border-slate-700 rounded-lg px-4 py-2 text-white focus:border-purple-500 focus:outline-none" 
                  required 
                />
              </div>
            </div>
            <div className="flex justify-end pt-4">
              <button type="submit" className="bg-green-600 hover:bg-green-700 text-white px-6 py-2 rounded-lg font-medium transition-colors">
                Guardar Banner
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Lista de Carteleras */}
      <div className="bg-slate-800 rounded-xl border border-slate-700 overflow-hidden">
        {loading ? (
          <div className="p-8 text-center text-slate-400">Cargando datos...</div>
        ) : (
          <table className="w-full text-left text-sm text-slate-300">
            <thead className="bg-slate-900/50 text-xs uppercase font-semibold text-slate-400">
              <tr>
                <th className="px-6 py-4">Orden</th>
                <th className="px-6 py-4">Imagen</th>
                <th className="px-6 py-4">Título</th>
                <th className="px-6 py-4">Sucursal</th>
                <th className="px-6 py-4">Estado</th>
                <th className="px-6 py-4 text-right">Acciones</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-700/50">
              {items.map((item) => (
                <tr key={item.id} className="hover:bg-slate-700/20 transition-colors">
                  <td className="px-6 py-4">{item.order}</td>
                  <td className="px-6 py-4">
                    <img src={item.imageUrl} alt={item.title} className="w-16 h-16 object-cover rounded border border-slate-600" />
                  </td>
                  <td className="px-6 py-4 font-medium text-white">{item.title}</td>
                  <td className="px-6 py-4">
                    <span className="bg-purple-900/50 text-purple-300 px-2 py-1 rounded text-xs font-medium border border-purple-800/50">
                      {item.casino}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`px-2 py-1 rounded text-xs font-medium ${item.isActive ? 'bg-green-900/50 text-green-300 border border-green-800/50' : 'bg-slate-800 text-slate-400 border border-slate-700'}`}>
                      {item.isActive ? 'Activo' : 'Inactivo'}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-right">
                    <button className="text-blue-400 hover:text-blue-300 mr-3">Editar</button>
                    <button className="text-red-400 hover:text-red-300">Ocultar</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
