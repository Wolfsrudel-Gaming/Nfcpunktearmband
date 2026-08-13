'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { api, Event } from '@/lib/api';

export default function DashboardPage() {
  const [events, setEvents] = useState<Event[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get<Event[]>('/api/events')
      .then(setEvents)
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const active = events.filter((e) => e.status === 'active');
  const draft = events.filter((e) => e.status === 'draft');

  return (
    <div>
      <h1 className="text-2xl font-bold tracking-tight">Dashboard</h1>
      <p className="mt-1 text-sm text-gray-500">Willkommen bei QuestBand.</p>

      <div className="mt-6 grid gap-4 sm:grid-cols-3">
        <StatCard label="Aktive Events" value={active.length} color="text-green-600" />
        <StatCard label="Entwürfe" value={draft.length} color="text-yellow-600" />
        <StatCard label="Gesamt" value={events.length} color="text-brand-600" />
      </div>

      <div className="mt-8">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-semibold">Aktive Events</h2>
          <Link
            href="/dashboard/events/new"
            className="rounded-lg bg-brand-500 px-3 py-1.5 text-sm font-semibold text-white hover:bg-brand-600"
          >
            Neues Event
          </Link>
        </div>

        {loading ? (
          <p className="mt-4 text-sm text-gray-400">Laden...</p>
        ) : active.length === 0 ? (
          <p className="mt-4 text-sm text-gray-400">Keine aktiven Events.</p>
        ) : (
          <div className="mt-3 space-y-2">
            {active.map((event) => (
              <Link
                key={event.id}
                href={`/dashboard/events/${event.id}`}
                className="block rounded-lg border border-gray-200 bg-white p-4 transition hover:border-brand-300 hover:shadow-sm"
              >
                <div className="flex items-center justify-between">
                  <div>
                    <div className="font-semibold">{event.name}</div>
                    <div className="text-xs text-gray-500">
                      {event.location}{event.startDate && ` · ${event.startDate}`}
                    </div>
                  </div>
                  <span className="rounded-full bg-green-100 px-2.5 py-0.5 text-xs font-semibold text-green-700">
                    Aktiv
                  </span>
                </div>
              </Link>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

function StatCard({ label, value, color }: { label: string; value: number; color: string }) {
  return (
    <div className="rounded-lg border border-gray-200 bg-white p-4">
      <div className="text-xs font-medium text-gray-500">{label}</div>
      <div className={`mt-1 text-2xl font-bold tabular-nums ${color}`}>{value}</div>
    </div>
  );
}
