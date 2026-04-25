import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, query, where, orderBy } from 'firebase/firestore';
import { db, auth, handleFirestoreError } from '../lib/firebase';
import { 
  Phone, 
  User, 
  Search, 
  ShieldCheck, 
  Heart, 
  Building2, 
  Mail,
  Smartphone,
  ExternalLink
} from 'lucide-react';

interface EmergencyContact {
  id: string;
  personName: string;
  company: string;
  type: 'Staff' | 'Contractor' | 'Visitor';
  nokName: string;
  nokRelationship: string;
  nokPhone: string;
  medicalNotes?: string;
}

export default function EmergencyContacts() {
  const [contacts, setContacts] = useState<EmergencyContact[]>([]);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    // In a real app, this would pull from the main personnel/contractor collections
    // For this module, we'll use a dedicated emergency view
    const q = query(collection(db, 'emergency_contacts'), orderBy('personName', 'asc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setContacts(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as EmergencyContact[]);
    }, (error) => handleFirestoreError(error, 'list' as any, 'emergency_contacts'));

    return () => unsubscribe();
  }, []);

  const filteredContacts = contacts.filter(c => 
    c.personName.toLowerCase().includes(searchTerm.toLowerCase()) ||
    c.company.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row justify-between items-center gap-4">
        <div className="flex items-center gap-3">
          <div className="bg-red-50 p-2 rounded-lg text-red-600">
            <Heart size={24} />
          </div>
          <div>
            <h2 className="text-xl font-bold text-slate-900">Emergency Contact & NOK Directory</h2>
            <p className="text-sm text-slate-500">Secure access to critical contact information for all personnel</p>
          </div>
        </div>
        <div className="relative w-full md:w-96">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
          <input 
            type="text"
            placeholder="Search by name or company..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 border border-slate-200 rounded-xl focus:ring-2 focus:ring-red-500"
          />
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredContacts.map(contact => (
          <div key={contact.id} className="bg-white border border-slate-200 rounded-2xl p-5 shadow-sm hover:shadow-md transition-all group">
            <div className="flex justify-between items-start mb-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-slate-100 flex items-center justify-center font-bold text-slate-600">
                  {contact.personName.charAt(0)}
                </div>
                <div>
                  <h3 className="font-bold text-slate-900 group-hover:text-red-600 transition-colors">{contact.personName}</h3>
                  <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">{contact.company}</p>
                </div>
              </div>
              <span className={`text-[10px] font-bold px-2 py-0.5 rounded uppercase ${
                contact.type === 'Staff' ? 'bg-blue-50 text-blue-600' : 
                contact.type === 'Contractor' ? 'bg-amber-50 text-amber-600' : 'bg-slate-100 text-slate-600'
              }`}>
                {contact.type}
              </span>
            </div>

            <div className="bg-slate-50 rounded-xl p-4 space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-[10px] font-bold text-slate-400 uppercase">Next of Kin</span>
                <span className="text-[10px] font-bold text-red-500 uppercase">{contact.nokRelationship}</span>
              </div>
              <p className="text-sm font-bold text-slate-900">{contact.nokName}</p>
              <a 
                href={`tel:${contact.nokPhone}`}
                className="flex items-center gap-2 text-sm text-blue-600 font-bold hover:underline"
              >
                <Smartphone size={14} />
                {contact.nokPhone}
              </a>
            </div>

            {contact.medicalNotes && (
              <div className="mt-4 pt-4 border-t border-slate-50">
                <div className="flex items-center gap-1.5 text-amber-600 mb-1">
                  <ShieldCheck size={14} />
                  <span className="text-[10px] font-bold uppercase">Medical Alert</span>
                </div>
                <p className="text-xs text-slate-600 italic leading-relaxed">
                  {contact.medicalNotes}
                </p>
              </div>
            )}
          </div>
        ))}
        {filteredContacts.length === 0 && (
          <div className="col-span-full py-12 text-center bg-slate-50 rounded-2xl border-2 border-dashed border-slate-200">
            <User className="mx-auto text-slate-300 mb-3" size={40} />
            <p className="text-slate-500 font-medium">No personnel records found matching your search.</p>
          </div>
        )}
      </div>

      <div className="bg-slate-900 rounded-2xl p-6 text-white flex flex-col md:flex-row justify-between items-center gap-6">
        <div className="flex items-center gap-4">
          <div className="bg-red-600 p-3 rounded-xl">
            <Phone size={24} />
          </div>
          <div>
            <h3 className="font-bold">Emergency Services Quick-Dial</h3>
            <p className="text-xs text-slate-400">Direct links to local emergency response units</p>
          </div>
        </div>
        <div className="flex flex-wrap gap-3">
          <button className="flex items-center gap-2 bg-white/10 hover:bg-white/20 px-4 py-2 rounded-lg text-sm font-bold transition-all border border-white/10">
            Fire Brigade (10111) <ExternalLink size={14} />
          </button>
          <button className="flex items-center gap-2 bg-white/10 hover:bg-white/20 px-4 py-2 rounded-lg text-sm font-bold transition-all border border-white/10">
            Ambulance (10177) <ExternalLink size={14} />
          </button>
          <button className="flex items-center gap-2 bg-white/10 hover:bg-white/20 px-4 py-2 rounded-lg text-sm font-bold transition-all border border-white/10">
            Police (10111) <ExternalLink size={14} />
          </button>
        </div>
      </div>
    </div>
  );
}
