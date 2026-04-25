import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, query, addDoc, doc, updateDoc, orderBy } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { 
  Package, 
  AlertTriangle, 
  CheckCircle2, 
  Plus, 
  X, 
  History, 
  Search, 
  ArrowUpRight, 
  ArrowDownRight,
  ShieldAlert,
  Droplets,
  HeartPulse,
  Flame
} from 'lucide-react';

interface EmergencyResource {
  id: string;
  name: string;
  category: 'Medical' | 'Fire' | 'Spill' | 'PPE' | 'Rescue';
  quantity: number;
  unit: string;
  minThreshold: number;
  expiryDate?: string;
  location: string;
  lastUpdated: string;
}

export default function ResourceInventory() {
  const [resources, setResources] = useState<EmergencyResource[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');

  // Form State
  const [name, setName] = useState('');
  const [category, setCategory] = useState<EmergencyResource['category']>('Medical');
  const [quantity, setQuantity] = useState(0);
  const [unit, setUnit] = useState('Units');
  const [minThreshold, setMinThreshold] = useState(5);
  const [location, setLocation] = useState('');
  const [expiryDate, setExpiryDate] = useState('');

  useEffect(() => {
    const q = query(collection(db, 'emergency_resources'), orderBy('name', 'asc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setResources(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as EmergencyResource[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'emergency_resources'));

    return () => unsubscribe();
  }, []);

  const handleAddResource = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;

    try {
      await addDoc(collection(db, 'emergency_resources'), {
        name,
        category,
        quantity,
        unit,
        minThreshold,
        location,
        expiryDate: expiryDate || null,
        lastUpdated: new Date().toISOString()
      });
      setIsAdding(false);
      setName('');
      setQuantity(0);
      setLocation('');
      setExpiryDate('');
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'emergency_resources');
    }
  };

  const updateQuantity = async (id: string, current: number, delta: number) => {
    const newQty = Math.max(0, current + delta);
    try {
      await updateDoc(doc(db, 'emergency_resources', id), { 
        quantity: newQty,
        lastUpdated: new Date().toISOString()
      });
    } catch (error) {
      handleFirestoreError(error, 'update' as any, 'emergency_resources');
    }
  };

  const filteredResources = resources.filter(r => 
    r.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    r.location.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const getCategoryIcon = (cat: string) => {
    switch (cat) {
      case 'Medical': return <HeartPulse size={18} className="text-red-500" />;
      case 'Fire': return <Flame size={18} className="text-orange-500" />;
      case 'Spill': return <Droplets size={18} className="text-blue-500" />;
      case 'Rescue': return <ShieldAlert size={18} className="text-amber-500" />;
      default: return <Package size={18} className="text-slate-500" />;
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row justify-between items-center gap-4">
        <div className="flex items-center gap-3">
          <div className="bg-blue-50 p-2 rounded-lg text-blue-600">
            <Package size={24} />
          </div>
          <div>
            <h2 className="text-xl font-bold text-slate-900">Emergency Resource Inventory (ERI)</h2>
            <p className="text-sm text-slate-500">Logistics management for critical safety and response supplies</p>
          </div>
        </div>
        <div className="flex gap-3 w-full md:w-auto">
          <div className="relative flex-1 md:w-64">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
            <input 
              type="text"
              placeholder="Search resources..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <button 
            onClick={() => setIsAdding(true)}
            className="p-2.5 bg-slate-900 text-white rounded-xl hover:bg-slate-800 transition-colors"
          >
            <Plus size={24} />
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* Critical Alerts */}
        <div className="lg:col-span-1 space-y-4">
          <div className="bg-red-50 border border-red-100 rounded-2xl p-6">
            <h3 className="font-bold text-red-900 mb-4 flex items-center gap-2 text-sm">
              <AlertTriangle size={18} />
              Low Stock Alerts
            </h3>
            <div className="space-y-3">
              {resources.filter(r => r.quantity <= r.minThreshold).map(r => (
                <div key={r.id} className="flex items-center justify-between text-xs">
                  <span className="text-red-800 font-medium">{r.name}</span>
                  <span className="font-bold text-red-600">{r.quantity} {r.unit} left</span>
                </div>
              ))}
              {resources.filter(r => r.quantity <= r.minThreshold).length === 0 && (
                <p className="text-xs text-red-700 italic">All critical resource levels are satisfactory.</p>
              )}
            </div>
          </div>

          <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm">
            <h3 className="font-bold text-slate-900 mb-4 flex items-center gap-2 text-sm">
              <History size={18} className="text-blue-600" />
              Recent Updates
            </h3>
            <div className="space-y-3">
              {resources.slice(0, 4).map(r => (
                <div key={r.id} className="flex flex-col gap-0.5">
                  <span className="text-[10px] font-bold text-slate-400 uppercase">{new Date(r.lastUpdated).toLocaleTimeString()}</span>
                  <span className="text-xs text-slate-700 font-medium">{r.name} updated to {r.quantity} {r.unit}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Resource Grid */}
        <div className="lg:col-span-3 grid grid-cols-1 md:grid-cols-2 gap-4">
          {filteredResources.map(resource => {
            const isLow = resource.quantity <= resource.minThreshold;
            const isExpired = resource.expiryDate && new Date(resource.expiryDate) < new Date();
            
            return (
              <div key={resource.id} className={`bg-white border rounded-2xl p-5 shadow-sm hover:shadow-md transition-all ${
                isLow ? 'border-red-200' : 'border-slate-200'
              }`}>
                <div className="flex justify-between items-start mb-4">
                  <div className="flex items-center gap-3">
                    <div className="bg-slate-50 p-2.5 rounded-xl">
                      {getCategoryIcon(resource.category)}
                    </div>
                    <div>
                      <h3 className="font-bold text-slate-900">{resource.name}</h3>
                      <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">{resource.location}</p>
                    </div>
                  </div>
                  <div className="flex flex-col items-end">
                    <span className={`text-2xl font-black ${isLow ? 'text-red-600' : 'text-slate-900'}`}>
                      {resource.quantity}
                    </span>
                    <span className="text-[10px] font-bold text-slate-400 uppercase">{resource.unit}</span>
                  </div>
                </div>

                <div className="flex items-center gap-2 mb-6">
                  <button 
                    onClick={() => updateQuantity(resource.id, resource.quantity, -1)}
                    className="flex-1 flex items-center justify-center gap-1 py-1.5 bg-slate-50 text-slate-600 rounded-lg hover:bg-slate-100 transition-colors text-xs font-bold"
                  >
                    <ArrowDownRight size={14} /> Use
                  </button>
                  <button 
                    onClick={() => updateQuantity(resource.id, resource.quantity, 1)}
                    className="flex-1 flex items-center justify-center gap-1 py-1.5 bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-100 transition-colors text-xs font-bold"
                  >
                    <ArrowUpRight size={14} /> Restock
                  </button>
                </div>

                <div className="pt-4 border-t border-slate-50 flex items-center justify-between">
                  <div className="flex items-center gap-1.5">
                    {isLow ? (
                      <AlertTriangle size={14} className="text-red-500" />
                    ) : (
                      <CheckCircle2 size={14} className="text-green-500" />
                    )}
                    <span className={`text-[10px] font-bold uppercase ${isLow ? 'text-red-600' : 'text-slate-500'}`}>
                      {isLow ? 'Low Stock' : 'Stock Level OK'}
                    </span>
                  </div>
                  {resource.expiryDate && (
                    <div className={`flex items-center gap-1 text-[10px] font-bold uppercase ${isExpired ? 'text-red-600' : 'text-slate-400'}`}>
                      Exp: {new Date(resource.expiryDate).toLocaleDateString()}
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Add Resource Modal */}
      {isAdding && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <h2 className="text-xl font-bold text-slate-900">Add Emergency Resource</h2>
              <button onClick={() => setIsAdding(false)} className="text-slate-400 hover:text-slate-600">
                <X size={24} />
              </button>
            </div>
            <form onSubmit={handleAddResource} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Resource Name</label>
                <input 
                  type="text" 
                  required
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="e.g., Trauma Bandages, Spill Absorbent"
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Category</label>
                  <select 
                    value={category}
                    onChange={(e) => setCategory(e.target.value as any)}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="Medical">Medical</option>
                    <option value="Fire">Fire</option>
                    <option value="Spill">Spill</option>
                    <option value="PPE">PPE</option>
                    <option value="Rescue">Rescue</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Location</label>
                  <input 
                    type="text" 
                    required
                    value={location}
                    onChange={(e) => setLocation(e.target.value)}
                    placeholder="e.g., First Aid Room"
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>
              <div className="grid grid-cols-3 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Qty</label>
                  <input 
                    type="number" 
                    required
                    value={quantity}
                    onChange={(e) => setQuantity(parseInt(e.target.value))}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Unit</label>
                  <input 
                    type="text" 
                    required
                    value={unit}
                    onChange={(e) => setUnit(e.target.value)}
                    placeholder="e.g., Boxes"
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Min</label>
                  <input 
                    type="number" 
                    required
                    value={minThreshold}
                    onChange={(e) => setMinThreshold(parseInt(e.target.value))}
                    className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Expiry Date (Optional)</label>
                <input 
                  type="date" 
                  value={expiryDate}
                  onChange={(e) => setExpiryDate(e.target.value)}
                  className="w-full p-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <div className="pt-4 flex justify-end gap-3">
                <button 
                  type="button"
                  onClick={() => setIsAdding(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-bold"
                >
                  Save Resource
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
