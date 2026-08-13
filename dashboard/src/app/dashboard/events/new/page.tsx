'use client';

import { useState, FormEvent } from 'react';
import { useRouter } from 'next/navigation';
import { api, Event } from '@/lib/api';

export default function NewEventPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    const fd = new FormData(e.currentTarget);
    try {
      const event = await api.post<Event>('/api/events', {
        name: fd.get('name'),
        description: fd.get('description') || undefined,
        startDate: fd.get('startDate') || undefined,
        endDate: fd.get('endDate') || undefined,
        location: fd.get('location') || undefined,
      });
      router.push(`/dashboard/events/${event.id}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Fehler beim Erstellen');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-lg">
      <h1 className="text-2xl font-bold tracking-tight">Neues Event</h1>

      <form onSubmit={handleSubmit} className="mt-6 space-y-4">
        {error && <div className="rounded-lg bg-red-50 px-4 py-2 text-sm text-red-700">{error}</div>}

        <Field label="Name" name="name" required placeholder="Sommercamp 2026" />
        <Field label="Beschreibung" name="description" placeholder="Kurze Beschreibung..." textarea />
        <div className="grid grid-cols-2 gap-4">
          <Field label="Startdatum" name="startDate" type="date" />
          <Field label="Enddatum" name="endDate" type="date" />
        </div>
        <Field label="Ort" name="location" placeholder="Schwarzwald, Deutschland" />

        <div className="flex gap-3 pt-2">
          <button
            type="submit"
            disabled={loading}
            className="rounded-lg bg-brand-500 px-4 py-2 text-sm font-semibold text-white hover:bg-brand-600 disabled:opacity-50"
          >
            {loading ? 'Erstellen...' : 'Event erstellen'}
          </button>
          <button type="button" onClick={() => router.back()} className="px-4 py-2 text-sm text-gray-500 hover:text-gray-700">
            Abbrechen
          </button>
        </div>
      </form>
    </div>
  );
}

function Field({ label, name, type = 'text', required, placeholder, textarea }: {
  label: string; name: string; type?: string; required?: boolean; placeholder?: string; textarea?: boolean;
}) {
  const cls = 'w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500';
  return (
    <div>
      <label htmlFor={name} className="mb-1 block text-sm font-medium text-gray-700">{label}</label>
      {textarea ? (
        <textarea id={name} name={name} rows={3} className={cls} placeholder={placeholder} />
      ) : (
        <input id={name} name={name} type={type} required={required} className={cls} placeholder={placeholder} />
      )}
    </div>
  );
}
