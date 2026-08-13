const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

class ApiClient {
  private token: string | null = null;

  setToken(token: string | null) {
    this.token = token;
    if (token) {
      localStorage.setItem('qb_token', token);
    } else {
      localStorage.removeItem('qb_token');
    }
  }

  getToken(): string | null {
    if (!this.token && typeof window !== 'undefined') {
      this.token = localStorage.getItem('qb_token');
    }
    return this.token;
  }

  private async request<T>(path: string, options: RequestInit = {}): Promise<T> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...((options.headers as Record<string, string>) || {}),
    };

    const token = this.getToken();
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const res = await fetch(`${API_URL}${path}`, { ...options, headers });

    if (!res.ok) {
      const body = await res.json().catch(() => ({}));
      throw new ApiError(res.status, body.error || 'Request failed', body.code);
    }

    return res.json();
  }

  get<T>(path: string) {
    return this.request<T>(path);
  }

  post<T>(path: string, body: unknown) {
    return this.request<T>(path, { method: 'POST', body: JSON.stringify(body) });
  }

  patch<T>(path: string, body: unknown) {
    return this.request<T>(path, { method: 'PATCH', body: JSON.stringify(body) });
  }

  delete<T>(path: string) {
    return this.request<T>(path, { method: 'DELETE' });
  }
}

export class ApiError extends Error {
  constructor(
    public status: number,
    message: string,
    public code?: string,
  ) {
    super(message);
  }
}

export const api = new ApiClient();

export interface User {
  id: string;
  name: string;
  role: string;
}

export interface Event {
  id: string;
  name: string;
  description: string | null;
  status: string;
  startDate: string | null;
  endDate: string | null;
  location: string | null;
  joinCode: string;
  config: Record<string, unknown>;
  createdAt: string;
  participants?: Participant[];
  rewards?: Reward[];
}

export interface Participant {
  id: string;
  displayName: string;
  firstName: string | null;
  lastName: string | null;
  age: number | null;
  group: string | null;
  balance: number;
  active: boolean;
  eventId: string;
  nfcTag?: { id: string; tagUid: string } | null;
  createdAt: string;
}

export interface PointTransaction {
  id: string;
  amount: number;
  balanceAfter: number;
  reason: string;
  note: string | null;
  pointType: string | null;
  givenBy: string | null;
  participantId: string;
  participant?: Participant;
  createdAt: string;
}

export interface Reward {
  id: string;
  name: string;
  description: string | null;
  cost: number;
  stock: number | null;
  redeemed: number;
  category: string | null;
  limitPerParticipant: number | null;
  available: boolean;
  eventId: string;
}
