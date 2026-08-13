'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import { api, Event, Participant, Reward } from '@/lib/api';

export default function EventDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [event, setEvent] = useState<Event | null>(null);
  const [loading, setLoading] = useState(true);
  const [tab, setTab] = useState<'info' | 'participants' | 'rewards'>('info');

  useEffect(() => {
    api.get<Event>(`/api/events/${id}`)
      .then(setEvent)
      .catch(() => router.push('/dashboard/events'))
      .finally(() => setLoading(false));
  }, [id, router]);

  if (loading || !event) {
    return <p className="text-sm text-gray-400">Laden...</p>;
  }

  const participants = event.participants || [];
  const rewards = event.rewards || [];

  return (
    <div>
      <div className="flex items-start justify-between">
        <div>
          <Link href="/dashboard/events" className="text-xs text-gray-400 hover:text-gray-600">← Events</Link>
          <h1 className="text-2xl font-bold tracking-tight">{event.name}</h1>
          {event.description && <p className="mt-1 text-sm text-gray-500">{event.description}</p>}
        </div>
        <div className="flex gap-2">
          <span className="rounded-full bg-green-100 px-3 py-1 text-xs font-semibold text-green-700">{event.status}</span>
          <code className="rounded bg-gray-100 px-2 py-1 text-xs font-mono">{event.joinCode}</code>
        </div>
      </div>

      <div className="mt-4 grid gap-3 sm:grid-cols-4">
        <Stat label="Teilnehmer" value={participants.length} />
        <Stat label="Prämien" value={rewards.length} />
        <Stat label="Start" value={event.startDate || '—'} />
        <Stat label="Ort" value={event.location || '—'} />
      </div>

      <div className="mt-6 flex gap-1 border-b border-gray-200">
        {(['info', 'participants', 'rewards'] as const).map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`border-b-2 px-4 py-2 text-sm font-medium transition ${
              tab === t ? 'border-brand-500 text-brand-600' : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            {{ info: 'Info', participants: `Teilnehmer (${participants.length})`, rewards: `Prämien (${rewards.length})` }[t]}
          </button>
        ))}
      </div>

      <div className="mt-4">
        {tab === 'info' && <EventInfo event={event} />}
        {tab === 'participants' && <ParticipantList participants={participants} eventId={event.id} />}
        {tab === 'rewards' && <RewardList rewards={rewards} />}
      </div>
    </div>
  );
}

function Stat({ label, value }: { label: string; value: string | number }) {
  return (
    <div className="rounded-lg border border-gray-200 bg-white px-4 py-3">
      <div className="text-xs text-gray-500">{label}</div>
      <div className="mt-0.5 font-semibold">{value}</div>
    </div>
  );
}

function EventInfo({ event }: { event: Event }) {
  return (
    <div className="space-y-3 text-sm">
      <div><span className="text-gray-500">Zeitraum:</span> {event.startDate || '—'} – {event.endDate || '—'}</div>
      <div><span className="text-gray-500">Ort:</span> {event.location || '—'}</div>
      <div>
        <span className="text-gray-500">Konfiguration:</span>
        <pre className="mt-1 overflow-x-auto rounded bg-gray-50 p-3 text-xs">{JSON.stringify(event.config, null, 2)}</pre>
      </div>
    </div>
  );
}

function ParticipantList({ participants, eventId }: { participants: Participant[]; eventId: string }) {
  return (
    <div>
      <div className="mb-3 flex justify-end">
        <Link
          href={`/dashboard/participants?eventId=${eventId}`}
          className="text-sm font-medium text-brand-500 hover:underline"
        >
          Alle verwalten →
        </Link>
      </div>
      {participants.length === 0 ? (
        <p className="text-sm text-gray-400">Keine Teilnehmer registriert.</p>
      ) : (
        <div className="overflow-x-auto rounded-lg border border-gray-200 bg-white">
          <table className="w-full text-left text-sm">
            <thead className="border-b border-gray-200 bg-gray-50 text-xs font-medium uppercase tracking-wider text-gray-500">
              <tr>
                <th className="px-4 py-2">Name</th>
                <th className="px-4 py-2">Gruppe</th>
                <th className="px-4 py-2 text-right">Punkte</th>
                <th className="px-4 py-2">NFC</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {participants.sort((a, b) => b.balance - a.balance).map((p) => (
                <tr key={p.id} className="hover:bg-gray-50">
                  <td className="px-4 py-2 font-medium">{p.displayName}</td>
                  <td className="px-4 py-2 text-gray-500">{p.group || '—'}</td>
                  <td className="px-4 py-2 text-right tabular-nums font-semibold">{p.balance}</td>
                  <td className="px-4 py-2">{p.nfcTag ? '✓' : '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

function RewardList({ rewards }: { rewards: Reward[] }) {
  return rewards.length === 0 ? (
    <p className="text-sm text-gray-400">Keine Prämien konfiguriert.</p>
  ) : (
    <div className="grid gap-3 sm:grid-cols-2">
      {rewards.map((r) => (
        <div key={r.id} className="rounded-lg border border-gray-200 bg-white p-4">
          <div className="flex items-center justify-between">
            <div className="font-semibold">{r.name}</div>
            <div className="font-bold tabular-nums text-brand-600">{r.cost} P</div>
          </div>
          {r.description && <p className="mt-1 text-xs text-gray-500">{r.description}</p>}
          <div className="mt-2 flex gap-3 text-xs text-gray-400">
            {r.stock !== null && <span>Bestand: {r.stock - r.redeemed}/{r.stock}</span>}
            {r.category && <span>{r.category}</span>}
            <span className={r.available ? 'text-green-600' : 'text-red-500'}>{r.available ? 'Verfügbar' : 'Deaktiviert'}</span>
          </div>
        </div>
      ))}
    </div>
  );
}
