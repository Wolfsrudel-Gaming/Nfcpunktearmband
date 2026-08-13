'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { api, Event } from '@/lib/api';

const STATUS_LABELS: Record<string, { label: string; cls: string }> = {
  active: { label: 'Aktiv', cls: 'bg-green-100 text-green-700' },
  draft: { label: 'Entwurf', cls: 'bg-yellow-100 text-yellow-700' },
  paused: { label: 'Pausiert', cls: 'bg-gray-100 text-gray-600' },
  archived: { label: 'Archiviert', cls: 'bg-gray-100 text-gray-500' },
};

export default function EventsPage() {
  const [events, setEvents] = useState<Event[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get<Event[]>('/api/events')
      .then(setEvents)
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  return (
    <div>
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold tracking-tight">Events</h1>
        <Link
          href="/dashboard/events/new"
          className="rounded-lg bg-brand-500 px-4 py-2 text-sm font-semibold text-white hover:bg-brand-600"
        >
          Neues Event
        </Link>
      </div>

      {loading ? (
        <p className="mt-6 text-sm text-gray-400">Laden...</p>
      ) : events.length === 0 ? (
        <div className="mt-12 text-center">
          <p className="text-gray-400">Noch keine Events vorhanden.</p>
          <Link href="/dashboard/events/new" className="mt-2 inline-block text-sm font-medium text-brand-500 hover:underline">
            Erstes Event erstellen
          </Link>
        </div>
      ) : (
        <div className="mt-4 overflow-x-auto rounded-lg border border-gray-200 bg-white">
          <table className="w-full text-left text-sm">
            <thead className="border-b border-gray-200 bg-gray-50 text-xs font-medium uppercase tracking-wider text-gray-500">
              <tr>
                <th className="px-4 py-3">Name</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3">Zeitraum</th>
                <th className="px-4 py-3">Ort</th>
                <th className="px-4 py-3">Code</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {events.map((event) => {
                const s = STATUS_LABELS[event.status] || { label: event.status, cls: 'bg-gray-100 text-gray-500' };
                return (
                  <tr key={event.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3">
                      <Link href={`/dashboard/events/${event.id}`} className="font-medium text-gray-900 hover:text-brand-600">
                        {event.name}
                      </Link>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`inline-block rounded-full px-2 py-0.5 text-xs font-semibold ${s.cls}`}>
                        {s.label}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-gray-500">
                      {event.startDate || '—'}{event.endDate ? ` – ${event.endDate}` : ''}
                    </td>
                    <td className="px-4 py-3 text-gray-500">{event.location || '—'}</td>
                    <td className="px-4 py-3">
                      <code className="rounded bg-gray-100 px-1.5 py-0.5 text-xs font-mono">{event.joinCode}</code>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
