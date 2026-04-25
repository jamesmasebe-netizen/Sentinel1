import React, { useState, useEffect, useRef } from 'react';
import { collection, getDocs, query, limit } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { Search, X, FileText, Wrench, Users, ShieldAlert, ChevronRight, Loader2 } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

interface SearchResult {
  id: string;
  title: string;
  type: 'Incident' | 'Asset' | 'Person' | 'Risk';
  path: string;
  subtitle?: string;
}

export default function GlobalSearch() {
  const [queryStr, setQueryStr] = useState('');
  const [results, setResults] = useState<SearchResult[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const [isOpen, setIsOpen] = useState(false);
  const searchRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const navigate = useNavigate();

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Trigger on Cmd+K (Mac) or Ctrl+K (Windows)
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        inputRef.current?.focus();
        setIsOpen(true);
      }
    };
    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, []);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (searchRef.current && !searchRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  useEffect(() => {
    const delayDebounceFn = setTimeout(() => {
      if (queryStr.length >= 2) {
        performSearch();
      } else {
        setResults([]);
        setIsOpen(false);
      }
    }, 300);

    return () => clearTimeout(delayDebounceFn);
  }, [queryStr]);

  const performSearch = async () => {
    setIsSearching(true);
    setIsOpen(true);
    const searchResults: SearchResult[] = [];

    try {
      const collections = [
        { name: 'incidents', type: 'Incident', path: '/safety?tab=incidents', titleField: 'title' },
        { name: 'assets', type: 'Asset', path: '/assets', titleField: 'name' },
        { name: 'employees', type: 'Person', path: '/people', titleField: 'name' },
        { name: 'enterprise_risks', type: 'Risk', path: '/governance?tab=risk', titleField: 'title' }
      ];

      for (const coll of collections) {
        const q = query(collection(db, coll.name), limit(20));
        const snap = await getDocs(q);
        snap.forEach(doc => {
          const data = doc.data();
          const title = data[coll.titleField] || 'Untitled';
          const subtitle = data.category || data.location || data.role || data.department;
          
          if (title.toLowerCase().includes(queryStr.toLowerCase()) || 
              (subtitle && subtitle.toLowerCase().includes(queryStr.toLowerCase()))) {
            searchResults.push({
              id: doc.id,
              title,
              type: coll.type as any,
              path: coll.path,
              subtitle
            });
          }
        });
      }

      setResults(searchResults.slice(0, 8));
    } catch (error) {
      console.error("Search error:", error);
    } finally {
      setIsSearching(false);
    }
  };

  const handleSelect = (path: string) => {
    navigate(path);
    setIsOpen(false);
    setQueryStr('');
  };

  const getIcon = (type: string) => {
    switch (type) {
      case 'Incident': return <FileText size={16} className="text-red-500" />;
      case 'Asset': return <Wrench size={16} className="text-blue-500" />;
      case 'Person': return <Users size={16} className="text-emerald-500" />;
      case 'Risk': return <ShieldAlert size={16} className="text-amber-500" />;
      default: return <Search size={16} className="text-slate-400" />;
    }
  };

  return (
    <div className="relative max-w-lg w-full" ref={searchRef}>
      <div className="relative group">
        <Search className={`absolute left-3 top-1/2 -translate-y-1/2 transition-colors ${isOpen ? 'text-blue-600' : 'text-slate-400'}`} size={18} />
        <input 
          ref={inputRef}
          type="text" 
          placeholder="Command Palette... (Search records, people, or risks)" 
          value={queryStr}
          onChange={(e) => setQueryStr(e.target.value)}
          onFocus={() => queryStr.length >= 0 && setIsOpen(true)}
          className="w-full bg-slate-50 border border-slate-200 rounded-xl pl-10 pr-24 py-2.5 text-sm font-medium text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all hover:bg-slate-100"
        />
        {!queryStr && !isOpen && (
          <div className="absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none">
            <kbd className="hidden sm:inline-flex items-center gap-1 bg-white border border-slate-200 text-slate-400 px-2 py-0.5 rounded text-[10px] font-bold tracking-widest shadow-sm">
              <span className="text-xs font-sans">⌘</span>K
            </kbd>
          </div>
        )}
        {queryStr && (
          <button 
            onClick={() => { setQueryStr(''); setResults([]); inputRef.current?.focus(); }}
            className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 p-1 bg-slate-100 rounded-md"
          >
            <X size={14} />
          </button>
        )}
      </div>

      {isOpen && (
        <div className="absolute top-full left-0 right-0 mt-2 bg-white rounded-2xl shadow-2xl border border-slate-100 overflow-hidden z-50 animate-in fade-in slide-in-from-top-2 duration-200">
          <div className="p-2 border-b border-slate-50 bg-slate-50/50 flex justify-between items-center">
            <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest px-2">
              {queryStr ? 'Search Results' : 'Quick Navigation'}
            </span>
            {isSearching && <Loader2 size={14} className="animate-spin text-blue-600 mr-2" />}
          </div>
          
          <div className="max-h-[400px] overflow-y-auto py-1">
            {!queryStr ? (
              // Default Command Palette Suggestions
              <>
                <button onClick={() => handleSelect('/portfolio')} className="w-full flex items-center gap-3 px-4 py-3 hover:bg-slate-50 transition-colors group">
                  <div className="w-8 h-8 rounded-lg bg-blue-50 flex items-center justify-center group-hover:bg-blue-100 transition-colors"><Search size={16} className="text-blue-600" /></div>
                  <div className="flex-1 text-left min-w-0">
                    <p className="text-sm font-bold text-slate-900">Go to Global Portfolio</p>
                    <p className="text-[10px] text-slate-500 font-medium uppercase tracking-wider">Navigation</p>
                  </div>
                  <ChevronRight size={14} className="text-slate-300 group-hover:text-blue-600" />
                </button>
                <button onClick={() => handleSelect('/financials')} className="w-full flex items-center gap-3 px-4 py-3 hover:bg-slate-50 transition-colors group">
                  <div className="w-8 h-8 rounded-lg bg-emerald-50 flex items-center justify-center group-hover:bg-emerald-100 transition-colors"><Search size={16} className="text-emerald-600" /></div>
                  <div className="flex-1 text-left min-w-0">
                    <p className="text-sm font-bold text-slate-900">Go to Asset Financials</p>
                    <p className="text-[10px] text-slate-500 font-medium uppercase tracking-wider">Navigation</p>
                  </div>
                  <ChevronRight size={14} className="text-slate-300 group-hover:text-emerald-600" />
                </button>
                <button onClick={() => handleSelect('/safety?tab=incidents')} className="w-full flex items-center gap-3 px-4 py-3 hover:bg-slate-50 transition-colors group">
                  <div className="w-8 h-8 rounded-lg bg-red-50 flex items-center justify-center group-hover:bg-red-100 transition-colors"><FileText size={16} className="text-red-600" /></div>
                  <div className="flex-1 text-left min-w-0">
                    <p className="text-sm font-bold text-slate-900">Report a New Incident</p>
                    <p className="text-[10px] text-slate-500 font-medium uppercase tracking-wider">Action</p>
                  </div>
                  <ChevronRight size={14} className="text-slate-300 group-hover:text-red-600" />
                </button>
              </>
            ) : results.length > 0 ? (
              // Actual Search Results
              results.map((result) => (
                <button
                  key={`${result.type}-${result.id}`}
                  onClick={() => handleSelect(result.path)}
                  className="w-full flex items-center gap-3 px-4 py-3 hover:bg-slate-50 transition-colors group"
                >
                  <div className="w-8 h-8 rounded-lg bg-slate-100 flex items-center justify-center group-hover:bg-white transition-colors">
                    {getIcon(result.type)}
                  </div>
                  <div className="flex-1 text-left min-w-0">
                    <p className="text-sm font-bold text-slate-900 truncate">{result.title}</p>
                    <p className="text-[10px] text-slate-500 font-medium uppercase tracking-wider">{result.type} {result.subtitle && `• ${result.subtitle}`}</p>
                  </div>
                  <ChevronRight size={14} className="text-slate-300 group-hover:text-blue-600 transition-colors" />
                </button>
              ))
            ) : !isSearching ? (
              <div className="p-8 text-center">
                <Search size={32} className="mx-auto text-slate-200 mb-2" />
                <p className="text-sm text-slate-500">No results found for "{queryStr}"</p>
              </div>
            ) : (
              <div className="p-8 text-center">
                <Loader2 size={32} className="mx-auto text-blue-100 animate-spin mb-2" />
                <p className="text-sm text-slate-400">Searching across modules...</p>
              </div>
            )}
          </div>
          
          {queryStr && results.length > 0 && (
            <div className="p-2 border-t border-slate-50 bg-slate-50/50 text-center">
              <p className="text-[10px] text-slate-400 font-bold uppercase tracking-widest">Press Enter to see all results</p>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
