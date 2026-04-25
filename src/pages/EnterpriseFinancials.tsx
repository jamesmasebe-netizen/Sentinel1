import React, { useState, useEffect } from 'react';
import { 
  DollarSign, 
  Calendar, 
  PieChart, 
  TrendingUp, 
  AlertCircle, 
  Building2,
  ArrowUpRight,
  ArrowDownRight,
  Filter,
  Download,
  FileText,
  Search
} from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';

// Mock Data for Leases
const leaseData = [
  { id: 'LSE-001', siteId: 'LDN-01', siteName: 'London HQ', landlord: 'British Land', expiryDate: '2026-12-31', annualRent: 2400000, currency: '£', status: 'Active', type: 'Headquarters' },
  { id: 'LSE-002', siteId: 'NYC-02', siteName: 'New York Tower', landlord: 'Vornado', expiryDate: '2026-08-15', annualRent: 3500000, currency: '$', status: 'Expiring Soon', type: 'Regional Hub' },
  { id: 'LSE-003', siteId: 'SGP-03', siteName: 'Singapore Hub', landlord: 'CapitaLand', expiryDate: '2030-03-31', annualRent: 1800000, currency: '$', status: 'Active', type: 'Regional Hub' },
  { id: 'LSE-004', siteId: 'FRA-04', siteName: 'Frankfurt Data Center', landlord: 'Digital Realty', expiryDate: '2028-11-30', annualRent: 4200000, currency: '€', status: 'Active', type: 'Data Center' },
  { id: 'LSE-005', siteId: 'TOK-05', siteName: 'Tokyo Office', landlord: 'Mitsubishi Estate', expiryDate: '2026-05-31', annualRent: 2100000, currency: '$', status: 'Critical', type: 'Branch' },
];

// Mock Data for Financials (CAPEX/OPEX)
const financialData = [
  { siteId: 'LDN-01', siteName: 'London HQ', capexBudget: 1500000, capexSpent: 1200000, opexBudget: 3000000, opexSpent: 1400000 },
  { siteId: 'NYC-02', siteName: 'New York Tower', capexBudget: 800000, capexSpent: 200000, opexBudget: 4500000, opexSpent: 2100000 },
  { siteId: 'SGP-03', siteName: 'Singapore Hub', capexBudget: 500000, capexSpent: 450000, opexBudget: 2200000, opexSpent: 1100000 },
  { siteId: 'FRA-04', siteName: 'Frankfurt Data Center', capexBudget: 5000000, capexSpent: 4800000, opexBudget: 8000000, opexSpent: 4200000 },
];

// Mock Data for Cost Allocation
const allocationData = [
  { unit: 'Retail Banking', percentage: 35, cost: 12500000 },
  { unit: 'Investment Banking', percentage: 40, cost: 14200000 },
  { unit: 'Wealth Management', percentage: 15, cost: 5300000 },
  { unit: 'Corporate Functions', percentage: 10, cost: 3500000 },
];

export default function EnterpriseFinancials() {
  const { profile } = useAuth();
  const [activeTab, setActiveTab] = useState<'leases' | 'capex' | 'allocation'>('leases');
  const [searchTerm, setSearchTerm] = useState('');

  const formatCurrency = (amount: number, currency: string = '$') => {
    return `${currency}${amount.toLocaleString()}`;
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Active': return 'bg-emerald-100 text-emerald-800 border-emerald-200';
      case 'Expiring Soon': return 'bg-amber-100 text-amber-800 border-amber-200';
      case 'Critical': return 'bg-red-100 text-red-800 border-red-200';
      default: return 'bg-slate-100 text-slate-800 border-slate-200';
    }
  };

  return (
    <div className="min-h-[calc(100vh-4rem)] bg-[#f5f5f5] text-slate-900 p-8 font-sans">
      
      {/* Header */}
      <header className="mb-8 flex flex-col md:flex-row justify-between items-start md:items-end gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-slate-900">Strategic Asset Management</h1>
          <p className="text-slate-500 mt-2">Financials, Lease Administration, and Cost Allocation</p>
        </div>
        <div className="flex gap-3">
          <button className="flex items-center gap-2 bg-white border border-slate-200 px-4 py-2 text-sm font-medium rounded-lg hover:bg-slate-50 transition-colors shadow-sm">
            <Download size={16} />
            Export Report
          </button>
        </div>
      </header>

      {/* KPI Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-200">
          <div className="flex justify-between items-start mb-4">
            <div className="text-sm font-medium text-slate-500">Total Annual Rent</div>
            <div className="p-2 bg-blue-50 text-blue-600 rounded-lg"><DollarSign size={20} /></div>
          </div>
          <div className="text-3xl font-light tracking-tight">$14.2M</div>
          <div className="flex items-center text-emerald-600 text-sm mt-2 font-medium">
            <ArrowDownRight size={16} className="mr-1" />
            <span>2.1% vs last year</span>
          </div>
        </div>

        <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-200">
          <div className="flex justify-between items-start mb-4">
            <div className="text-sm font-medium text-slate-500">Upcoming Renewals (12m)</div>
            <div className="p-2 bg-amber-50 text-amber-600 rounded-lg"><Calendar size={20} /></div>
          </div>
          <div className="text-3xl font-light tracking-tight">2</div>
          <div className="flex items-center text-amber-600 text-sm mt-2 font-medium">
            <AlertCircle size={16} className="mr-1" />
            <span>Action required</span>
          </div>
        </div>

        <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-200">
          <div className="flex justify-between items-start mb-4">
            <div className="text-sm font-medium text-slate-500">YTD CAPEX Spend</div>
            <div className="p-2 bg-purple-50 text-purple-600 rounded-lg"><TrendingUp size={20} /></div>
          </div>
          <div className="text-3xl font-light tracking-tight">$6.6M</div>
          <div className="w-full bg-slate-100 h-2 rounded-full mt-3 overflow-hidden">
            <div className="bg-purple-500 h-full rounded-full" style={{ width: '85%' }}></div>
          </div>
          <div className="text-xs text-slate-500 mt-2">85% of $7.8M Budget</div>
        </div>

        <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-200">
          <div className="flex justify-between items-start mb-4">
            <div className="text-sm font-medium text-slate-500">Cost Allocation</div>
            <div className="p-2 bg-emerald-50 text-emerald-600 rounded-lg"><PieChart size={20} /></div>
          </div>
          <div className="text-3xl font-light tracking-tight">100%</div>
          <div className="flex items-center text-emerald-600 text-sm mt-2 font-medium">
            <CheckCircle size={16} className="mr-1" />
            <span>Fully reconciled</span>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex space-x-1 bg-slate-200/50 p-1 rounded-xl w-fit mb-6">
        <button
          onClick={() => setActiveTab('leases')}
          className={`px-6 py-2.5 text-sm font-medium rounded-lg transition-all ${
            activeTab === 'leases' ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-600 hover:text-slate-900'
          }`}
        >
          Lease Management
        </button>
        <button
          onClick={() => setActiveTab('capex')}
          className={`px-6 py-2.5 text-sm font-medium rounded-lg transition-all ${
            activeTab === 'capex' ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-600 hover:text-slate-900'
          }`}
        >
          CAPEX & OPEX
        </button>
        <button
          onClick={() => setActiveTab('allocation')}
          className={`px-6 py-2.5 text-sm font-medium rounded-lg transition-all ${
            activeTab === 'allocation' ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-600 hover:text-slate-900'
          }`}
        >
          Cost Allocation
        </button>
      </div>

      {/* Tab Content */}
      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
        
        {/* Leases Tab */}
        {activeTab === 'leases' && (
          <div>
            <div className="p-4 border-b border-slate-200 flex justify-between items-center bg-slate-50/50">
              <div className="relative w-72">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                <input 
                  type="text"
                  placeholder="Search leases or sites..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 text-sm border border-slate-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <button className="text-sm font-medium text-blue-600 hover:text-blue-800 flex items-center gap-1">
                <Filter size={16} /> Filter
              </button>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-white border-b border-slate-200 text-slate-500 text-xs uppercase tracking-wider">
                    <th className="p-4 font-medium">Lease ID / Site</th>
                    <th className="p-4 font-medium">Landlord</th>
                    <th className="p-4 font-medium">Type</th>
                    <th className="p-4 font-medium text-right">Annual Rent</th>
                    <th className="p-4 font-medium">Expiry Date</th>
                    <th className="p-4 font-medium text-center">Status</th>
                    <th className="p-4 font-medium text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {leaseData.filter(l => l.siteName.toLowerCase().includes(searchTerm.toLowerCase()) || l.id.toLowerCase().includes(searchTerm.toLowerCase())).map(lease => (
                    <tr key={lease.id} className="hover:bg-slate-50 transition-colors">
                      <td className="p-4">
                        <div className="font-semibold text-slate-900">{lease.id}</div>
                        <div className="text-xs text-slate-500 flex items-center gap-1 mt-0.5">
                          <Building2 size={12} /> {lease.siteName}
                        </div>
                      </td>
                      <td className="p-4 text-sm text-slate-700">{lease.landlord}</td>
                      <td className="p-4 text-sm text-slate-700">{lease.type}</td>
                      <td className="p-4 text-sm font-mono text-right font-medium">{formatCurrency(lease.annualRent, lease.currency)}</td>
                      <td className="p-4 text-sm text-slate-700">
                        <div className="flex items-center gap-2">
                          <Calendar size={14} className={lease.status !== 'Active' ? 'text-amber-500' : 'text-slate-400'} />
                          <span className={lease.status !== 'Active' ? 'font-medium text-amber-700' : ''}>{lease.expiryDate}</span>
                        </div>
                      </td>
                      <td className="p-4 text-center">
                        <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${getStatusColor(lease.status)}`}>
                          {lease.status}
                        </span>
                      </td>
                      <td className="p-4 text-right">
                        <button className="p-2 text-slate-400 hover:text-blue-600 transition-colors rounded-lg hover:bg-blue-50">
                          <FileText size={18} />
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* CAPEX/OPEX Tab */}
        {activeTab === 'capex' && (
          <div className="p-6">
            <h2 className="text-lg font-bold text-slate-900 mb-6">Site Financial Performance</h2>
            <div className="space-y-8">
              {financialData.map(data => {
                const capexPercent = (data.capexSpent / data.capexBudget) * 100;
                const opexPercent = (data.opexSpent / data.opexBudget) * 100;
                
                return (
                  <div key={data.siteId} className="border border-slate-200 rounded-xl p-5 bg-slate-50/30">
                    <div className="flex justify-between items-center mb-4">
                      <div className="flex items-center gap-2">
                        <Building2 size={20} className="text-slate-400" />
                        <h3 className="font-bold text-slate-900">{data.siteName} <span className="text-slate-400 font-normal text-sm ml-2">({data.siteId})</span></h3>
                      </div>
                    </div>
                    
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                      {/* CAPEX */}
                      <div>
                        <div className="flex justify-between text-sm mb-2">
                          <span className="font-medium text-slate-700">CAPEX (Capital Expenditure)</span>
                          <span className="font-mono text-slate-500">{formatCurrency(data.capexSpent)} / {formatCurrency(data.capexBudget)}</span>
                        </div>
                        <div className="w-full bg-slate-200 h-2.5 rounded-full overflow-hidden">
                          <div 
                            className={`h-full rounded-full ${capexPercent > 95 ? 'bg-red-500' : capexPercent > 80 ? 'bg-amber-500' : 'bg-purple-500'}`}
                            style={{ width: `${Math.min(capexPercent, 100)}%` }}
                          ></div>
                        </div>
                        <div className="text-right text-xs text-slate-500 mt-1">{capexPercent.toFixed(1)}% Utilized</div>
                      </div>

                      {/* OPEX */}
                      <div>
                        <div className="flex justify-between text-sm mb-2">
                          <span className="font-medium text-slate-700">OPEX (Operational Expenditure)</span>
                          <span className="font-mono text-slate-500">{formatCurrency(data.opexSpent)} / {formatCurrency(data.opexBudget)}</span>
                        </div>
                        <div className="w-full bg-slate-200 h-2.5 rounded-full overflow-hidden">
                          <div 
                            className={`h-full rounded-full ${opexPercent > 95 ? 'bg-red-500' : opexPercent > 80 ? 'bg-amber-500' : 'bg-blue-500'}`}
                            style={{ width: `${Math.min(opexPercent, 100)}%` }}
                          ></div>
                        </div>
                        <div className="text-right text-xs text-slate-500 mt-1">{opexPercent.toFixed(1)}% Utilized</div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* Cost Allocation Tab */}
        {activeTab === 'allocation' && (
          <div className="p-6">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 items-center">
              <div>
                <h2 className="text-lg font-bold text-slate-900 mb-2">Business Unit Allocation</h2>
                <p className="text-slate-500 text-sm mb-6">Automated chargebacks based on occupancy footprint and dedicated services.</p>
                
                <div className="space-y-4">
                  {allocationData.map((item, idx) => {
                    const colors = ['bg-blue-500', 'bg-emerald-500', 'bg-purple-500', 'bg-amber-500'];
                    return (
                      <div key={item.unit} className="flex items-center justify-between p-4 border border-slate-100 rounded-lg bg-slate-50">
                        <div className="flex items-center gap-3">
                          <div className={`w-3 h-3 rounded-full ${colors[idx % colors.length]}`}></div>
                          <span className="font-medium text-slate-700">{item.unit}</span>
                        </div>
                        <div className="flex items-center gap-6">
                          <span className="text-slate-500 text-sm">{item.percentage}%</span>
                          <span className="font-mono font-medium w-24 text-right">{formatCurrency(item.cost)}</span>
                        </div>
                      </div>
                    );
                  })}
                  <div className="flex items-center justify-between p-4 border-t-2 border-slate-200 mt-2">
                    <span className="font-bold text-slate-900">Total Allocated</span>
                    <span className="font-mono font-bold text-lg">{formatCurrency(allocationData.reduce((acc, curr) => acc + curr.cost, 0))}</span>
                  </div>
                </div>
              </div>
              
              <div className="flex justify-center items-center bg-slate-50 rounded-2xl p-8 border border-slate-100 h-full min-h-[300px]">
                {/* Simulated Pie Chart using CSS */}
                <div className="relative w-64 h-64 rounded-full" style={{
                  background: `conic-gradient(
                    #3b82f6 0% 35%, 
                    #10b981 35% 75%, 
                    #a855f7 75% 90%, 
                    #f59e0b 90% 100%
                  )`
                }}>
                  <div className="absolute inset-0 m-auto w-40 h-40 bg-slate-50 rounded-full flex flex-col items-center justify-center shadow-inner">
                    <span className="text-sm text-slate-500 font-medium">Total Cost</span>
                    <span className="text-xl font-bold text-slate-900">$35.5M</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

      </div>
    </div>
  );
}

// Helper icon for CheckCircle since it wasn't imported at top
function CheckCircle(props: any) {
  return (
    <svg
      {...props}
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
      <polyline points="22 4 12 14.01 9 11.01" />
    </svg>
  );
}
