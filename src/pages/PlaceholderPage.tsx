import React from 'react';

export default function PlaceholderPage({ title, description }: { title: string, description: string }) {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">{title}</h1>
        <p className="text-gray-500">{description}</p>
      </div>
      <div className="bg-white shadow rounded-lg border border-gray-100 p-8 text-center">
        <p className="text-gray-500">This module is currently under development.</p>
      </div>
    </div>
  );
}
