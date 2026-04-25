import React from 'react';

interface RiskMatrixProps {
  probability: number;
  severity: number;
}

export default function RiskMatrix({ probability, severity }: RiskMatrixProps) {
  const getCellColor = (p: number, s: number) => {
    const score = p * s;
    if (score >= 15) return 'bg-red-500';
    if (score >= 8) return 'bg-amber-400';
    return 'bg-green-400';
  };

  return (
    <div className="flex flex-col items-center">
      <div className="text-xs font-bold text-gray-500 mb-2 uppercase tracking-wider">Risk Matrix</div>
      <div className="flex">
        {/* Y-axis label */}
        <div className="flex flex-col justify-center items-center mr-2">
          <span className="text-xs font-medium text-gray-500 -rotate-90 whitespace-nowrap w-4">Probability</span>
        </div>
        
        <div className="relative">
          <div className="grid grid-cols-5 gap-1 bg-gray-200 p-1 rounded">
            {[5, 4, 3, 2, 1].map((p) => (
              <React.Fragment key={`row-${p}`}>
                {[1, 2, 3, 4, 5].map((s) => {
                  const isSelected = p === probability && s === severity;
                  return (
                    <div
                      key={`${p}-${s}`}
                      className={`w-6 h-6 sm:w-8 sm:h-8 flex items-center justify-center text-[10px] sm:text-xs font-bold rounded-sm transition-all ${getCellColor(p, s)} ${
                        isSelected ? 'ring-2 ring-blue-600 ring-offset-1 scale-110 shadow-md z-10' : 'opacity-60'
                      }`}
                      title={`P:${p} x S:${s} = ${p * s}`}
                    >
                      {p * s}
                    </div>
                  );
                })}
              </React.Fragment>
            ))}
          </div>
          {/* X-axis label */}
          <div className="text-center mt-2">
            <span className="text-xs font-medium text-gray-500">Severity</span>
          </div>
        </div>
      </div>
    </div>
  );
}
