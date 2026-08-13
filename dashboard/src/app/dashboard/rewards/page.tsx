'use client';

import { useEffect, useState, FormEvent } from 'react';
import { api, Event, Participant, Reward } from '@/lib/api';

export default function RewardsPage() {
  const [events, setEvents] = useState<Event[]>([]);
  const [eventId, setEventId] = useState('');
  const [rewards, setRewards] = useState<Reward[]>([]);
  const [participants, setParticipants] = useState<Participant[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [redeemMsg, setRedeemMsg] = useState('');
  const [formError, setFormError] = useState('');

  useEffect(() => {
    api.get<Event[]>('/api/events').then(setEvents).catch(() => {});
  }, []);

  const reload = () => {
    if (!eventId) return;
    api.get<Reward[]>(`/api/rewards/event/${eventId}`).then(setRewards).catch(() => {});
    api.get<Participant[]>(`/api/participants/event/${eventId}`).then(setParticipants).catch(() => {});
  };

  useEffect(reload, [eventId]);

  const handleCreate = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setFormError('');
    const fd = new FormData(e.currentTarget);
    try {
      await api.post('/api/rewards', {
        eventId,
        name: fd.get('name'),
        description: fd.get('description') || undefined,
        cost: Number(fd.get('cost')),
        stock: fd.get('stock') ? Number(fd.get('stock')) : undefined,
        category: fd.get('category') || undefined,
        limitPerParticipant: fd.get('limit') ? Number(fd.get('limit')) : undefined,
      });
      reload();
      setShowForm(false);
      e.currentTarget.reset();
    } catch (err) {
      setFormError(err instanceof Error ? err.message : 'Fehler');
    }
  };

  const handleRedeem = async (rewardId: string, participantId: string) => {
    setRedeemMsg('');
    try {
      const result = await api.post<{ balance: number }>('/api/rewards/redeem', {
        rewardId,
        participantId,
        eventId,
      });
      setRedeemMsg(`Eingelöst! Neuer Punktestand: ${result.balance}`);
      reload();
    } catch (err) {
      setRedeemMsg(err instanceof Error ? err.message : 'Fehler');
    }
  };

  return (
    <div>
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold tracking-tight">Prämien</h1>
        {eventId && (
          <button
            onClick={() => setShowForm(!showForm)}
            className="rounded-lg bg-brand-500 px-4 py-2 text-sm font-semibold text-white hover:bg-brand-600"
          >
            {showForm ? 'Abbrechen' : 'Neue Prämie'}
          </button>
        )}
      </div>

      <div className="mt-4">
        <select
          value={eventId}
          onChange={(e) => setEventId(e.target.value)}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-brand-500 focus:outline-none"
        >
          <option value="">Event wählen...</option>
          {events.map((e) => <option key={e.id} value={e.id}>{e.name}</option>)}
        </select>
      </div>

      {redeemMsg && (
        <div className={`mt-3 rounded-lg px-4 py-2 text-sm ${redeemMsg.startsWith('Eingelöst') ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'}`}>
          {redeemMsg}
        </div>
      )}

      {showForm && (
        <form onSubmit={handleCreate} className="mt-4 rounded-lg border border-gray-200 bg-white p-4">
          {formError && <div className="mb-3 rounded bg-red-50 px-3 py-2 text-sm text-red-700">{formError}</div>}
          <div className="grid gap-3 sm:grid-cols-3">
            <input name="name" required placeholder="Name *" className="rounded border border-gray-300 px-3 py-2 text-sm" />
            <input name="description" placeholder="Beschreibung" className="rounded border border-gray-300 px-3 py-2 text-sm" />
            <input name="cost" type="number" min="0" required placeholder="Kosten (Punkte) *" className="rounded border border-gray-300 px-3 py-2 text-sm" />
            <input name="stock" type="number" min="0" placeholder="Bestand (leer = unbegrenzt)" className="rounded border border-gray-300 px-3 py-2 text-sm" />
            <input name="category" placeholder="Kategorie" className="rounded border border-gray-300 px-3 py-2 text-sm" />
            <input name="limit" type="number" min="1" placeholder="Limit pro Person" className="rounded border border-gray-300 px-3 py-2 text-sm" />
          </div>
          <button type="submit" className="mt-3 rounded bg-brand-500 px-4 py-2 text-sm font-semibold text-white hover:bg-brand-600">
            Erstellen
          </button>
        </form>
      )}

      {!eventId ? (
        <p className="mt-8 text-center text-sm text-gray-400">Bitte ein Event wählen.</p>
      ) : rewards.length === 0 ? (
        <p className="mt-8 text-center text-sm text-gray-400">Keine Prämien konfiguriert.</p>
      ) : (
        <div className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {rewards.map((r) => (
            <div key={r.id} className="rounded-lg border border-gray-200 bg-white p-4">
              <div className="flex items-start justify-between">
                <div>
                  <div className="font-semibold">{r.name}</div>
                  {r.description && <div className="text-xs text-gray-500">{r.description}</div>}
                </div>
                <div className="text-lg font-bold tabular-nums text-brand-600">{r.cost}P</div>
              </div>
              <div className="mt-2 flex flex-wrap gap-2 text-xs text-gray-400">
                {r.stock !== null && <span>Bestand: {r.stock - r.redeemed}/{r.stock}</span>}
                {r.category && <span className="rounded bg-gray-100 px-1.5 py-0.5">{r.category}</span>}
                {r.limitPerParticipant && <span>Max {r.limitPerParticipant}x/Person</span>}
              </div>
              <div className="mt-3 flex gap-2">
                <select id={`redeem-${r.id}`} className="flex-1 rounded border border-gray-300 px-2 py-1.5 text-xs">
                  <option value="">Teilnehmer...</option>
                  {participants.filter((p) => p.balance >= r.cost).map((p) => (
                    <option key={p.id} value={p.id}>{p.displayName} ({p.balance}P)</option>
                  ))}
                </select>
                <button
                  onClick={() => {
                    const sel = document.getElementById(`redeem-${r.id}`) as HTMLSelectElement;
                    if (sel.value) handleRedeem(r.id, sel.value);
                  }}
                  className="rounded bg-green-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-green-700"
                >
                  Einlösen
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
