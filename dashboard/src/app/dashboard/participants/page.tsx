'use client';

import { useEffect, useState, FormEvent } from 'react';
import { useSearchParams } from 'next/navigation';
import { api, Event, Participant } from '@/lib/api';

export default function ParticipantsPage() {
  const searchParams = useSearchParams();
  const [events, setEvents] = useState<Event[]>([]);
  const [eventId, setEventId] = useState(searchParams.get('eventId') || '');
  const [participants, setParticipants] = useState<Participant[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(false);
  const [showForm, setShowForm] = useState(false);
  const [formError, setFormError] = useState('');

  useEffect(() => {
    api.get<Event[]>('/api/events').then(setEvents).catch(() => {});
  }, []);

  useEffect(() => {
    if (!eventId) return;
    setLoading(true);
    const q = search ? `?search=${encodeURIComponent(search)}` : '';
    api.get<Participant[]>(`/api/participants/event/${eventId}${q}`)
      .then(setParticipants)
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [eventId, search]);

  const handleRegister = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setFormError('');
    const fd = new FormData(e.currentTarget);
    try {
      const p = await api.post<Participant>('/api/participants', {
        eventId,
        displayName: fd.get('displayName'),
        firstName: fd.get('firstName') || undefined,
        lastName: fd.get('lastName') || undefined,
        age: fd.get('age') ? Number(fd.get('age')) : undefined,
        group: fd.get('group') || undefined,
      });
      setParticipants((prev) => [...prev, p]);
      setShowForm(false);
      e.currentTarget.reset();
    } catch (err) {
      setFormError(err instanceof Error ? err.message : 'Fehler');
    }
  };

  return (
    <div>
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold tracking-tight">Teilnehmer</h1>
        {eventId && (
          <button
            onClick={() => setShowForm(!showForm)}
            className="rounded-lg bg-brand-500 px-4 py-2 text-sm font-semibold text-white hover:bg-brand-600"
          >
            {showForm ? 'Abbrechen' : 'Registrieren'}
          </button>
        )}
      </div>

      <div className="mt-4 flex gap-3">
        <select
          value={eventId}
          onChange={(e) => setEventId(e.target.value)}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-brand-500 focus:outline-none"
        >
          <option value="">Event wählen...</option>
          {events.map((e) => <option key={e.id} value={e.id}>{e.name}</option>)}
        </select>
        {eventId && (
          <input
            type="search"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Suchen..."
            className="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-brand-500 focus:outline-none"
          />
        )}
      </div>

      {showForm && (
        <form onSubmit={handleRegister} className="mt-4 rounded-lg border border-gray-200 bg-white p-4">
          {formError && <div className="mb-3 rounded bg-red-50 px-3 py-2 text-sm text-red-700">{formError}</div>}
          <div className="grid gap-3 sm:grid-cols-3">
            <input name="displayName" required placeholder="Anzeigename *" className="rounded border border-gray-300 px-3 py-2 text-sm" />
            <input name="firstName" placeholder="Vorname" className="rounded border border-gray-300 px-3 py-2 text-sm" />
            <input name="lastName" placeholder="Nachname" className="rounded border border-gray-300 px-3 py-2 text-sm" />
            <input name="age" type="number" min="0" max="99" placeholder="Alter" className="rounded border border-gray-300 px-3 py-2 text-sm" />
            <input name="group" placeholder="Gruppe" className="rounded border border-gray-300 px-3 py-2 text-sm" />
            <button type="submit" className="rounded bg-brand-500 px-4 py-2 text-sm font-semibold text-white hover:bg-brand-600">
              Hinzufügen
            </button>
          </div>
        </form>
      )}

      {!eventId ? (
        <p className="mt-8 text-center text-sm text-gray-400">Bitte ein Event wählen.</p>
      ) : loading ? (
        <p className="mt-6 text-sm text-gray-400">Laden...</p>
      ) : participants.length === 0 ? (
        <p className="mt-8 text-center text-sm text-gray-400">Keine Teilnehmer gefunden.</p>
      ) : (
        <div className="mt-4 overflow-x-auto rounded-lg border border-gray-200 bg-white">
          <table className="w-full text-left text-sm">
            <thead className="border-b border-gray-200 bg-gray-50 text-xs font-medium uppercase tracking-wider text-gray-500">
              <tr>
                <th className="px-4 py-2">Name</th>
                <th className="px-4 py-2">Alter</th>
                <th className="px-4 py-2">Gruppe</th>
                <th className="px-4 py-2 text-right">Punkte</th>
                <th className="px-4 py-2">NFC</th>
                <th className="px-4 py-2">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {participants.map((p) => (
                <tr key={p.id} className="hover:bg-gray-50">
                  <td className="px-4 py-2">
                    <div className="font-medium">{p.displayName}</div>
                    {(p.firstName || p.lastName) && (
                      <div className="text-xs text-gray-400">{[p.firstName, p.lastName].filter(Boolean).join(' ')}</div>
                    )}
                  </td>
                  <td className="px-4 py-2 text-gray-500">{p.age ?? '—'}</td>
                  <td className="px-4 py-2 text-gray-500">{p.group || '—'}</td>
                  <td className="px-4 py-2 text-right tabular-nums font-semibold">{p.balance}</td>
                  <td className="px-4 py-2">{p.nfcTag ? <span className="text-green-600">✓</span> : '—'}</td>
                  <td className="px-4 py-2">
                    <span className={`text-xs font-medium ${p.active ? 'text-green-600' : 'text-red-500'}`}>
                      {p.active ? 'Aktiv' : 'Inaktiv'}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
