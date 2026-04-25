import React, { useState, useEffect } from 'react';
import { collection, addDoc, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { handleFirestoreError } from '../lib/firebase';
import { Package, Plus, AlertCircle, CheckCircle2, Settings } from 'lucide-react';

interface InventoryItem {
  id: string;
  itemName: string;
  category: 'Medication' | 'Supply' | 'Equipment' | 'PPE';
  quantity: number;
  minThreshold: number;
  expiryDate?: string;
  calibrationDate?: string;
  status: 'In Stock' | 'Low Stock' | 'Expired' | 'Calibration Due';
  createdAt: string;
}

export default function OccHealthInventory() {
  const [items, setItems] = useState<InventoryItem[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [formData, setFormData] = useState({
    itemName: '',
    category: 'Medication' as InventoryItem['category'],
    quantity: 0,
    minThreshold: 5,
    expiryDate: '',
    calibrationDate: ''
  });

  useEffect(() => {
    if (!auth.currentUser) return;
    const q = query(collection(db, 'occhealth_inventory'), orderBy('itemName', 'asc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as InventoryItem[];
      setItems(data);
    }, (error) => handleFirestoreError(error, 'list' as any, 'occhealth_inventory'));
    return () => unsubscribe();
  }, []);

  const getStatus = (item: any): InventoryItem['status'] => {
    if (item.expiryDate && new Date(item.expiryDate) < new Date()) return 'Expired';
    if (item.calibrationDate && new Date(item.calibrationDate) < new Date()) return 'Calibration Due';
    if (item.quantity <= item.minThreshold) return 'Low Stock';
    return 'In Stock';
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    try {
      const status = getStatus(formData);
      await addDoc(collection(db, 'occhealth_inventory'), {
        ...formData,
        status,
        authorId: auth.currentUser.uid,
        createdAt: new Date().toISOString()
      });
      setIsAdding(false);
      setFormData({ itemName: '', category: 'Medication', quantity: 0, minThreshold: 5, expiryDate: '', calibrationDate: '' });
    } catch (error) {
      handleFirestoreError(error, 'create' as any, 'occhealth_inventory');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold text-slate-900">Clinic Inventory & Equipment</h2>
          <p className="text-sm text-slate-500">Track medical supplies, medications, and equipment calibration.</p>
        </div>
        <button onClick={() => setIsAdding(true)} className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
          <Plus size={18} /> Add Item
        </button>
      </div>

      {isAdding && (
        <div className="bg-slate-50 p-4 rounded-lg border border-slate-200 mb-6">
          <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Item Name</label>
              <input type="text" required placeholder="e.g., Paracetamol, Audiometer" value={formData.itemName} onChange={e => setFormData({...formData, itemName: e.target.value})} className="w-full p-2 border rounded-lg" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Category</label>
              <select value={formData.category} onChange={e => setFormData({...formData, category: e.target.value as any})} className="w-full p-2 border rounded-lg">
                <option value="Medication">Medication</option>
                <option value="Supply">Supply (Consumables)</option>
                <option value="Equipment">Equipment (Medical)</option>
                <option value="PPE">PPE (Medical)</option>
              </select>
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Quantity</label>
                <input type="number" required value={formData.quantity} onChange={e => setFormData({...formData, quantity: parseInt(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Min Threshold</label>
                <input type="number" required value={formData.minThreshold} onChange={e => setFormData({...formData, minThreshold: parseInt(e.target.value) || 0})} className="w-full p-2 border rounded-lg" />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Expiry Date (if med.)</label>
                <input type="date" value={formData.expiryDate} onChange={e => setFormData({...formData, expiryDate: e.target.value})} className="w-full p-2 border rounded-lg" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Calibration Due (if equip.)</label>
                <input type="date" value={formData.calibrationDate} onChange={e => setFormData({...formData, calibrationDate: e.target.value})} className="w-full p-2 border rounded-lg" />
              </div>
            </div>
            <div className="md:col-span-2 flex justify-end gap-2 mt-2">
              <button type="button" onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">Cancel</button>
              <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Save Item</button>
            </div>
          </form>
        </div>
      )}

      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 text-sm">
              <th className="p-4 font-medium">Item Name</th>
              <th className="p-4 font-medium">Category</th>
              <th className="p-4 font-medium">Stock Level</th>
              <th className="p-4 font-medium">Expiry / Calibration</th>
              <th className="p-4 font-medium">Status</th>
            </tr>
          </thead>
          <tbody>
            {items.map(item => (
              <tr key={item.id} className="border-b border-slate-100 hover:bg-slate-50">
                <td className="p-4 font-medium text-slate-900">{item.itemName}</td>
                <td className="p-4 text-slate-600 text-sm">{item.category}</td>
                <td className="p-4">
                  <div className="flex items-center gap-2">
                    <span className={`font-bold ${item.quantity <= item.minThreshold ? 'text-red-600' : 'text-slate-900'}`}>{item.quantity}</span>
                    <span className="text-xs text-slate-400">/ min {item.minThreshold}</span>
                  </div>
                </td>
                <td className="p-4 text-slate-600 text-xs">
                  {item.expiryDate && <p className="mb-1">Exp: {new Date(item.expiryDate).toLocaleDateString()}</p>}
                  {item.calibrationDate && <p>Cal: {new Date(item.calibrationDate).toLocaleDateString()}</p>}
                  {!item.expiryDate && !item.calibrationDate && '-'}
                </td>
                <td className="p-4">
                  {item.status === 'In Stock' && <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800"><CheckCircle2 size={12}/> In Stock</span>}
                  {item.status === 'Low Stock' && <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-800"><Package size={12}/> Low Stock</span>}
                  {item.status === 'Expired' && <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800"><AlertCircle size={12}/> Expired</span>}
                  {item.status === 'Calibration Due' && <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-purple-100 text-purple-800"><Settings size={12}/> Cal. Due</span>}
                </td>
              </tr>
            ))}
            {items.length === 0 && !isAdding && (
              <tr>
                <td colSpan={5} className="p-8 text-center text-slate-500">No inventory items found.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
