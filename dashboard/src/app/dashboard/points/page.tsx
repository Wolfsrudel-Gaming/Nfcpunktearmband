'use client';

import { useEffect, useState, FormEvent } from 'react';
import { api, Event, Participant, PointTransaction } from '@/lib/api';

export default function PointsPage() {
  const [events, setEvents] = useState<Event[]>([]);
  const [eventId, setEventId] = useState('');
  const [participants, setParticipants] = useState<Participant[]>([]);
  const [transactions, setTransactions] = useState<PointTransaction[]>([]);
  const [leaderboard, setLeaderboard] = useState<Participant[]>([]);
  const [tab, setTab] = useState<'book' | 'history' | 'leaderboard'>('book');
  const [bookError, setBookError] = useState('');
  const [bookSuccess, setBookSuccess] = useState('');

  useEffect(() => {
    api.get<Event[]>('/api/events').then(setEvents).catch(() => {});
  }, []);

  useEffect(() => {
    if (!eventId) return;
    api.get<Participant[]>(`/api/participants/event/${eventId}`).then(setParticipants).catch(() => {});
    api.get<PointTransaction[]>(`/api/points/event/${eventId}`).then(setTransactions).catch(() => {});
    api.get<Participant[]>(`/api/points/leaderboard/${eventId}`).then(setLeaderboard).catch(() => {});
  }, [eventId]);

  const handleBook = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setBookError('');
    setBookSuccess('');
    const fd = new FormData(e.currentTarget);
    try {
      const result = await api.post<{ transaction: PointTransaction; balance: number }>('/api/points', {
        participantId: fd.get('participantId'),
        eventId,
        amount: Number(fd.get('amount')),
        reason: fd.get('reason') || 'manual',
        note: fd.get('note') || undefined,
      });
      setBookSuccess(`${result.transaction.amount > 0 ? '+' : ''}${result.transaction.amount} Punkte gebucht. Neuer Stand: ${result.balance}`);
      api.get<PointTransaction[]>(`/api/points/event/${eventId}`).then(setTransactions).catch(() => {});
      api.get<Participant[]>(`/api/points/leaderboard/${eventId}`).then(setLeaderboard).catch(() => {});
      api.get<Participant[]>(`/api/participants/event/${eventId}`).then(setParticipants).catch(() => {});
    } catch (err) {
      setBookError(err instanceof Error ? err.message : 'Fehler');
    }
  };

  return (
    <div>
      <h1 className="text-2xl font-bold tracking-tight">Punkte</h1>

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

      {!eventId ? (
        <p className="mt-8 text-center text-sm text-gray-400">Bitte ein Event wählen.</p>
      ) : (
        <>
          <div className="mt-6 flex gap-1 border-b border-gray-200">
            {([['book', 'Buchen'], ['history', 'Verlauf'], ['leaderboard', 'Rangliste']] as const).map(([key, label]) => (
              <button
                key={key}
                onClick={() => setTab(key)}
                className={`border-b-2 px-4 py-2 text-sm font-medium transition ${
                  tab === key ? 'border-brand-500 text-brand-600' : 'border-transparent text-gray-500 hover:text-gray-700'
                }`}
              >
                {label}
              </button>
            ))}
          </div>

          <div className="mt-4">
            {tab === 'book' && (
              <form onSubmit={handleBook} className="max-w-md space-y-3">
                {bookError && <div className="rounded bg-red-50 px-3 py-2 text-sm text-red-700">{bookError}</div>}
                {bookSuccess && <div className="rounded bg-green-50 px-3 py-2 text-sm text-green-700">{bookSuccess}</div>}
                <div>
                  <label className="mb-1 block text-sm font-medium text-gray-700">Teilnehmer</label>
                  <select name="participantId" required className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm">
                    <option value="">Wählen...</option>
                    {participants.map((p) => <option key={p.id} value={p.id}>{p.displayName} ({p.balance} P)</option>)}
                  </select>
                </div>
                <div>
                  <label className="mb-1 block text-sm font-medium text-gray-700">Punkte</label>
                  <div className="flex gap-2">
                    {[1, 2, 5, 10].map((v) => (
                      <button key={v} type="button" onClick={(e) => {
                        const input = (e.currentTarget.closest('form')!.querySelector('[name=amount]') as HTMLInputElement);
                        input.value = String(v);
                      }} className="rounded border border-gray-300 px-3 py-1.5 text-sm font-medium hover:bg-gray-100">
                        +{v}
                      </button>
                    ))}
                  </div>
                  <input name="amount" type="number" required className="mt-2 w-full rounded-lg border border-gray-300 px-3 py-2 text-sm" placeholder="Anzahl (negativ = Abzug)" />
                </div>
                <div>
                  <label className="mb-1 block text-sm font-medium text-gray-700">Grund</label>
                  <select name="reason" className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm">
                    <option value="manual">Manuell</option>
                    <option value="quick_select">Schnellwahl</option>
                    <option value="quest">Quest</option>
                    <option value="badge">Badge</option>
                  </select>
                </div>
                <input name="note" placeholder="Notiz (optional)" className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm" />
                <button type="submit" className="rounded-lg bg-brand-500 px-4 py-2 text-sm font-semibold text-white hover:bg-brand-600">
                  Punkte buchen
                </button>
              </form>
            )}

            {tab === 'history' && (
              <div className="overflow-x-auto rounded-lg border border-gray-200 bg-white">
                <table className="w-full text-left text-sm">
                  <thead className="border-b border-gray-200 bg-gray-50 text-xs font-medium uppercase tracking-wider text-gray-500">
                    <tr>
                      <th className="px-4 py-2">Zeit</th>
                      <th className="px-4 py-2">Teilnehmer</th>
                      <th className="px-4 py-2 text-right">Betrag</th>
                      <th className="px-4 py-2 text-right">Stand</th>
                      <th className="px-4 py-2">Grund</th>
                      <th className="px-4 py-2">Notiz</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100">
                    {transactions.map((tx) => (
                      <tr key={tx.id} className="hover:bg-gray-50">
                        <td className="px-4 py-2 text-xs text-gray-500">{new Date(tx.createdAt).toLocaleString('de-DE')}</td>
                        <td className="px-4 py-2 font-medium">{tx.participant?.displayName || tx.participantId.slice(0, 8)}</td>
                        <td className={`px-4 py-2 text-right tabular-nums font-semibold ${tx.amount >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                          {tx.amount > 0 ? '+' : ''}{tx.amount}
                        </td>
                        <td className="px-4 py-2 text-right tabular-nums">{tx.balanceAfter}</td>
                        <td className="px-4 py-2 text-gray-500">{tx.reason}</td>
                        <td className="px-4 py-2 text-gray-400">{tx.note || '—'}</td>
                      </tr>
                    ))}
                    {transactions.length === 0 && (
                      <tr><td colSpan={6} className="px-4 py-8 text-center text-gray-400">Keine Buchungen vorhanden.</td></tr>
                    )}
                  </tbody>
                </table>
              </div>
            )}

            {tab === 'leaderboard' && (
              <div className="max-w-md overflow-x-auto rounded-lg border border-gray-200 bg-white">
                <table className="w-full text-left text-sm">
                  <thead className="border-b border-gray-200 bg-gray-50 text-xs font-medium uppercase tracking-wider text-gray-500">
                    <tr>
                      <th className="px-4 py-2 w-12">#</th>
                      <th className="px-4 py-2">Name</th>
                      <th className="px-4 py-2">Gruppe</th>
                      <th className="px-4 py-2 text-right">Punkte</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100">
                    {leaderboard.map((p, i) => (
                      <tr key={p.id} className={i < 3 ? 'bg-brand-50/50' : 'hover:bg-gray-50'}>
                        <td className="px-4 py-2 font-bold text-gray-400">{i + 1}</td>
                        <td className="px-4 py-2 font-medium">{p.displayName}</td>
                        <td className="px-4 py-2 text-gray-500">{p.group || '—'}</td>
                        <td className="px-4 py-2 text-right tabular-nums font-bold text-brand-600">{p.balance}</td>
                      </tr>
                    ))}
                    {leaderboard.length === 0 && (
                      <tr><td colSpan={4} className="px-4 py-8 text-center text-gray-400">Keine Daten.</td></tr>
                    )}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </>
      )}
    </div>
  );
}
