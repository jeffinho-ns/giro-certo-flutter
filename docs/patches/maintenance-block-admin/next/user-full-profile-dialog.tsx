'use client';

import { useCallback, useEffect, useState } from 'react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { ScrollArea } from '@/components/ui/scroll-area';
import { apiClient } from '@/lib/api';
import type { User, UserType } from '@/lib/types';
import {
  Ban,
  CheckCircle2,
  Loader2,
  MapPin,
  Wallet,
  Package,
  Shield,
  Wrench,
} from 'lucide-react';

interface WalletTransaction {
  id: string;
  type?: string;
  amount: number;
  description?: string;
  status?: string;
  createdAt?: string;
  deliveryOrderId?: string;
}

interface WalletData {
  id: string;
  userId: string;
  balance: number;
  totalEarned: number;
  totalWithdrawn: number;
  transactions: WalletTransaction[];
}

interface AdminBike {
  id: string;
  userId: string;
  model: string;
  brand: string;
  plate: string | null;
  currentKm: number;
  vehicleType?: string;
  oilType?: string | null;
  photoUrl?: string | null;
  vehiclePhotoUrl?: string | null;
  platePhotoUrl?: string | null;
  nickname?: string | null;
  accessories?: string[];
  maintenanceLogs: Array<{
    id: string;
    partName: string;
    category: string;
    status: string;
    wearPercentage?: number;
    lastChangeKm?: number;
    currentKm?: number;
    recommendedChangeKm?: number;
    createdAt: string;
  }>;
}

interface DeliveryRegistrationRow {
  id: string;
  userId: string;
  status: string;
  vehicleType?: 'MOTORCYCLE' | 'BICYCLE';
  cpfCnh: string;
  selfieWithDocData?: string;
  motoWithPlateData?: string;
  platePlateCloseupData?: string;
  cnhPhotoData?: string;
  crlvPhotoData?: string;
  plateLicense: string;
  currentKilometers: number;
  lastOilChangeDate?: string;
  lastOilChangeKm?: number;
  emergencyPhone?: string;
  equipments?: string[];
  bikeOptionalReceiptData?: string;
  consentImages: boolean;
  approvedAt?: string;
  approvedBy?: string;
  rejectionReason?: string;
  adminNotes?: string;
  createdAt: string;
  updatedAt: string;
}

function B64Img({ data, label }: { data?: string; label: string }) {
  if (!data) {
    return <p className="text-xs text-muted-foreground">{label}: não enviada</p>;
  }
  return (
    <div className="space-y-1">
      <p className="text-xs font-medium">{label}</p>
      {/* eslint-disable-next-line @next/next/no-img-element -- base64 admin preview */}
      <img
        src={`data:image/jpeg;base64,${data}`}
        alt={label}
        className="w-full max-h-48 object-contain rounded border bg-muted/30"
      />
    </div>
  );
}

type Props = {
  user: User | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  isAdmin: boolean;
  onRiderBlockToggled?: () => void;
  getUserTypeLabel: (t: UserType | null) => string;
  resolveUserType: (u: User) => UserType | null;
  currentUserId?: string;
  followRequestLoading?: boolean;
  followRequestSent?: boolean;
  onFollowRequest?: (userId: string) => void;
};

export function UserFullProfileDialog({
  user,
  open,
  onOpenChange,
  isAdmin,
  onRiderBlockToggled,
  getUserTypeLabel,
  resolveUserType,
  currentUserId,
  followRequestLoading = false,
  followRequestSent = false,
  onFollowRequest,
}: Props) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [detail, setDetail] = useState<User & { wallet?: WalletData; bikes?: unknown[] } | null>(null);
  const [bikes, setBikes] = useState<AdminBike[]>([]);
  const [deliveryRegs, setDeliveryRegs] = useState<DeliveryRegistrationRow[]>([]);
  const [blocking, setBlocking] = useState(false);
  const [overrideLoading, setOverrideLoading] = useState(false);

  const userId = user?.id;

  const load = useCallback(async () => {
    if (!userId) return;
    setLoading(true);
    setError(null);
    try {
      const [uRes, bRes, dRes] = await Promise.all([
        apiClient.get<{ user: User & { wallet?: WalletData } }>(`/api/users/${userId}`),
        apiClient.get<{ bikes: AdminBike[] }>(`/api/bikes/admin/user/${userId}`).catch(() => ({ bikes: [] })),
        apiClient
          .get<{ registrations: DeliveryRegistrationRow[] }>(
            `/api/delivery-registration/admin/by-user/${userId}`
          )
          .catch(() => ({ registrations: [] })),
      ]);
      setDetail(uRes.user);
      setBikes(bRes.bikes || []);
      setDeliveryRegs(dRes.registrations || []);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Falha ao carregar o perfil completo.');
    } finally {
      setLoading(false);
    }
  }, [userId]);

  useEffect(() => {
    if (open && userId) {
      void load();
    } else if (!open) {
      setDetail(null);
      setBikes([]);
      setDeliveryRegs([]);
      setError(null);
    }
  }, [open, userId, load]);

  const wallet = detail?.wallet;
  const blocked = detail?.deliveryRiderBlocked === true;
  const maintenanceOverride = detail?.maintenanceBlockOverride === true;

  const latestMaintenanceByPart = (logs: AdminBike['maintenanceLogs']) => {
    const map = new Map<string, AdminBike['maintenanceLogs'][number]>();
    for (const log of logs) {
      if (!map.has(log.partName)) map.set(log.partName, log);
    }
    return Array.from(map.values());
  };

  const bikeHasActiveCritical = (bike: AdminBike) =>
    latestMaintenanceByPart(bike.maintenanceLogs || []).some(
      (m) =>
        m.status === 'CRITICO' ||
        (typeof m.wearPercentage === 'number' && m.wearPercentage >= 0.9)
    );

  const handleToggleRiderBlock = async () => {
    if (!userId || !isAdmin) return;
    const next = !blocked;
    if (
      !window.confirm(
        next
          ? 'Bloquear este utilizador de receber e aceitar corridas? (ex.: inadimplência de taxas)'
          : 'Remover o bloqueio de corridas deste utilizador?'
      )
    ) {
      return;
    }
    setBlocking(true);
    try {
      await apiClient.put(`/api/users/${userId}/delivery-rider-block`, { blocked: next });
      await load();
      onRiderBlockToggled?.();
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Não foi possível atualizar o bloqueio.');
    } finally {
      setBlocking(false);
    }
  };

  const handleToggleMaintenanceOverride = async () => {
    if (!userId || !isAdmin) return;
    const next = !maintenanceOverride;
    if (
      !window.confirm(
        next
          ? 'Liberar temporariamente este entregador para aceitar corridas mesmo com manutenção crítica? (override de suporte)'
          : 'Remover o override? O bloqueio por manutenção crítica volta a aplicar-se se ainda houver peça crítica.'
      )
    ) {
      return;
    }
    setOverrideLoading(true);
    try {
      await apiClient.put(`/api/users/${userId}/maintenance-block-override`, {
        override: next,
      });
      await load();
      onRiderBlockToggled?.();
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Não foi possível atualizar o override de manutenção.');
    } finally {
      setOverrideLoading(false);
    }
  };

  if (!user) return null;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="flex max-h-[92vh] max-w-[calc(100%-2rem)] flex-col gap-0 p-0 sm:max-w-4xl">
        <DialogHeader className="shrink-0 border-b px-4 pb-2 pt-6 sm:px-6">
          <DialogTitle className="text-xl">Perfil completo</DialogTitle>
          <DialogDescription>
            Dados de cadastro, documentos, garagem e ações administrativas.
          </DialogDescription>
        </DialogHeader>

        {loading && (
          <div className="flex items-center justify-center gap-2 py-12 text-muted-foreground">
            <Loader2 className="h-5 w-5 animate-spin" />
            A carregar dados da API…
          </div>
        )}

        {error && (
          <p className="px-4 py-4 text-sm text-destructive sm:px-6">{error}</p>
        )}

        {!loading && !error && (
          <ScrollArea className="h-[min(70vh,720px)] px-4 sm:px-6">
            <div className="space-y-6 py-4 pr-3">
              {/* Resumo + ações */}
              <section className="flex flex-col sm:flex-row gap-4 sm:items-start sm:justify-between">
                <div className="flex items-start gap-4">
                  <div className="h-20 w-20 rounded-full bg-primary/10 flex items-center justify-center overflow-hidden shrink-0">
                    {(detail?.photoUrl || user.photoUrl) ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img
                        src={detail?.photoUrl || user.photoUrl}
                        alt={user.name}
                        className="h-20 w-20 object-cover"
                      />
                    ) : (
                      <span className="text-2xl font-medium text-primary">
                        {user.name.charAt(0).toUpperCase()}
                      </span>
                    )}
                  </div>
                  <div className="space-y-1 min-w-0">
                    <h3 className="text-lg font-semibold">{detail?.name ?? user.name}</h3>
                    <p className="text-sm text-muted-foreground break-all">{detail?.email ?? user.email}</p>
                    <p className="text-xs text-muted-foreground font-mono break-all">ID: {user.id}</p>
                    <div className="flex flex-wrap gap-1.5 pt-1">
                      <Badge variant="secondary">{detail?.role ?? user.role}</Badge>
                      <Badge variant="outline">
                        {getUserTypeLabel(resolveUserType(detail ?? user))}
                      </Badge>
                      {detail?.hasVerifiedDocuments && (
                        <Badge className="bg-emerald-600/90">Docs verificados</Badge>
                      )}
                      {blocked && <Badge variant="destructive">Corridas bloqueadas</Badge>}
                      {bikes.some(bikeHasActiveCritical) && !maintenanceOverride && (
                        <Badge variant="destructive">Manutenção crítica ativa</Badge>
                      )}
                      {maintenanceOverride && (
                        <Badge className="bg-amber-600/90">Override manutenção</Badge>
                      )}
                      {detail?.verificationBadge && <Badge>Verificado</Badge>}
                    </div>
                  </div>
                </div>

                {isAdmin && (
                  <div className="flex flex-col gap-2 sm:items-end">
                    <Button
                      type="button"
                      variant={blocked ? 'secondary' : 'destructive'}
                      size="sm"
                      className="gap-2"
                      onClick={handleToggleRiderBlock}
                      disabled={blocking}
                    >
                      {blocking ? <Loader2 className="h-4 w-4 animate-spin" /> : <Ban className="h-4 w-4" />}
                      {blocked ? 'Desbloquear corridas' : 'Bloquear corridas (inadimplência)'}
                    </Button>
                    <Button
                      type="button"
                      variant={maintenanceOverride ? 'secondary' : 'outline'}
                      size="sm"
                      className="gap-2"
                      onClick={handleToggleMaintenanceOverride}
                      disabled={overrideLoading}
                    >
                      {overrideLoading ? (
                        <Loader2 className="h-4 w-4 animate-spin" />
                      ) : (
                        <Wrench className="h-4 w-4" />
                      )}
                      {maintenanceOverride
                        ? 'Remover liberação (manutenção)'
                        : 'Liberar apesar da manutenção'}
                    </Button>
                    <p className="text-xs text-muted-foreground max-w-[260px] text-left sm:text-right">
                      Ideal: o piloto regista a manutenção na Garagem e libera sozinho. O
                      override é só para suporte emergencial.
                    </p>
                  </div>
                )}
              </section>

              {/* Conta e localização */}
              <section>
                <h4 className="text-sm font-semibold flex items-center gap-2 mb-2">
                  <Shield className="h-4 w-4" />
                  Conta
                </h4>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-sm">
                  <div>
                    <p className="text-muted-foreground">Idade</p>
                    <p>{detail?.age ?? user.age} anos</p>
                  </div>
                  <div>
                    <p className="text-muted-foreground">Criado em</p>
                    <p>
                      {detail?.createdAt
                        ? new Date(detail.createdAt as unknown as string).toLocaleString('pt-BR')
                        : '—'}
                    </p>
                  </div>
                  <div>
                    <p className="text-muted-foreground">Piloto (API)</p>
                    <p className="font-mono text-xs">{detail?.pilotProfile ?? user.pilotProfile}</p>
                  </div>
                  <div>
                    <p className="text-muted-foreground">Subscrição</p>
                    <p>
                      {detail?.isSubscriber ? `${detail.subscriptionType}` : 'Não assinante'}
                    </p>
                  </div>
                  <div>
                    <p className="text-muted-foreground">Pontos fidelidade</p>
                    <p>{detail?.loyaltyPoints ?? user.loyaltyPoints}</p>
                  </div>
                  <div>
                    <p className="text-muted-foreground flex items-center gap-1">
                      <MapPin className="h-3.5 w-3.5" />
                      Última posição
                    </p>
                    <p>
                      {detail?.currentLat != null && detail?.currentLng != null
                        ? `${Number(detail.currentLat).toFixed(5)}, ${Number(detail.currentLng).toFixed(5)}`
                        : 'Não reportada'}
                    </p>
                  </div>
                </div>
                {detail?.maintenanceBlockOverride && (
                  <p className="text-xs text-amber-600 dark:text-amber-500 mt-2">
                    Manutenção: override manual ativo (entregador pode contornar bloqueio por manutenção crítica).
                  </p>
                )}
              </section>

              {/* Carteira */}
              {wallet && (
                <section>
                  <h4 className="text-sm font-semibold flex items-center gap-2 mb-2">
                    <Wallet className="h-4 w-4" />
                    Carteira
                  </h4>
                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-2 text-sm mb-3">
                    <div className="rounded border p-2">
                      <p className="text-muted-foreground text-xs">Saldo</p>
                      <p className="font-medium">R$ {Number(wallet.balance).toFixed(2)}</p>
                    </div>
                    <div className="rounded border p-2">
                      <p className="text-muted-foreground text-xs">Total ganho</p>
                      <p className="font-medium">R$ {Number(wallet.totalEarned).toFixed(2)}</p>
                    </div>
                    <div className="rounded border p-2">
                      <p className="text-muted-foreground text-xs">Levantado</p>
                      <p className="font-medium">R$ {Number(wallet.totalWithdrawn).toFixed(2)}</p>
                    </div>
                  </div>
                  {Array.isArray(wallet.transactions) && (wallet.transactions?.length ?? 0) > 0 && (
                    <div className="overflow-x-auto rounded-md border text-xs">
                      <table className="w-full min-w-[280px]">
                        <thead className="bg-muted/50">
                          <tr>
                            <th className="text-left p-2">Data</th>
                            <th className="text-left p-2">Tipo</th>
                            <th className="text-right p-2">Valor</th>
                          </tr>
                        </thead>
                        <tbody>
                          {wallet.transactions.slice(0, 15).map((t) => (
                            <tr key={t.id} className="border-t">
                              <td className="p-2 text-muted-foreground">
                                {t.createdAt
                                  ? new Date(t.createdAt).toLocaleString('pt-BR')
                                  : '—'}
                              </td>
                              <td className="p-2">{t.type ?? t.description ?? '—'}</td>
                              <td className="p-2 text-right">R$ {Number(t.amount).toFixed(2)}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  )}
                </section>
              )}

              {/* Garagem */}
              <section>
                <h4 className="text-sm font-semibold flex items-center gap-2 mb-2">
                  <Wrench className="h-4 w-4" />
                  Garagem / veículos
                </h4>
                {bikes.length === 0 ? (
                  <p className="text-sm text-muted-foreground">Nenhum veículo registado.</p>
                ) : (
                  <div className="space-y-4">
                    {bikes.map((b) => (
                      <div key={b.id} className="border rounded-lg p-3 space-y-2">
                        <div className="flex flex-wrap items-center gap-2">
                          <p className="font-medium">
                            {b.brand} {b.model}
                          </p>
                          <Badge variant="outline" className="text-xs">
                            {b.vehicleType === 'BICYCLE' ? 'Bicicleta' : 'Moto'}
                          </Badge>
                          {b.nickname && (
                            <span className="text-sm text-muted-foreground">&ldquo;{b.nickname}&rdquo;</span>
                          )}
                        </div>
                        <div className="text-sm grid sm:grid-cols-2 gap-2">
                          <p>
                            <span className="text-muted-foreground">Identificador:</span>{' '}
                            {b.plate || 'S/N'}
                          </p>
                          <p>
                            <span className="text-muted-foreground">Quilometragem:</span>{' '}
                            {b.currentKm} km
                          </p>
                        </div>
                        {b.accessories && b.accessories.length > 0 && (
                          <p className="text-xs text-muted-foreground">
                            Acessórios: {b.accessories.join(', ')}
                          </p>
                        )}
                        <div className="grid grid-cols-1 sm:grid-cols-3 gap-2">
                          {b.vehiclePhotoUrl ? (
                            <div className="sm:col-span-1">
                              <p className="text-xs font-medium mb-1">Foto do veículo</p>
                              {/* eslint-disable-next-line @next/next/no-img-element -- URLs da garagem (Firebase) */}
                              <img
                                src={b.vehiclePhotoUrl}
                                alt="Veículo"
                                className="w-full max-h-40 object-cover rounded border"
                              />
                            </div>
                          ) : null}
                          {b.platePhotoUrl ? (
                            <div className="sm:col-span-1">
                              <p className="text-xs font-medium mb-1">Foto da placa</p>
                              {/* eslint-disable-next-line @next/next/no-img-element */}
                              <img
                                src={b.platePhotoUrl}
                                alt="Placa"
                                className="w-full max-h-40 object-cover rounded border"
                              />
                            </div>
                          ) : null}
                          {b.photoUrl && b.photoUrl !== b.vehiclePhotoUrl ? (
                            <div className="sm:col-span-1">
                              <p className="text-xs font-medium mb-1">Foto geral</p>
                              {/* eslint-disable-next-line @next/next/no-img-element */}
                              <img
                                src={b.photoUrl}
                                alt="Veículo"
                                className="w-full max-h-40 object-cover rounded border"
                              />
                            </div>
                          ) : null}
                        </div>
                        {b.maintenanceLogs && b.maintenanceLogs.length > 0 && (
                          <div className="space-y-2">
                            <p className="text-xs font-medium">Estado atual por peça</p>
                            <div className="overflow-x-auto rounded-md border text-xs">
                              <table className="w-full min-w-[320px]">
                                <thead className="bg-muted/50">
                                  <tr>
                                    <th className="text-left p-2">Peça</th>
                                    <th className="text-left p-2">Status</th>
                                    <th className="text-right p-2">Desgaste</th>
                                    <th className="text-left p-2">Atualizado</th>
                                  </tr>
                                </thead>
                                <tbody>
                                  {latestMaintenanceByPart(b.maintenanceLogs).map((m) => {
                                    const critical =
                                      m.status === 'CRITICO' ||
                                      (typeof m.wearPercentage === 'number' &&
                                        m.wearPercentage >= 0.9);
                                    return (
                                      <tr key={m.id} className="border-t">
                                        <td className="p-2">{m.partName}</td>
                                        <td className="p-2">
                                          <Badge
                                            variant={critical ? 'destructive' : 'outline'}
                                            className="text-[10px]"
                                          >
                                            {m.status}
                                          </Badge>
                                        </td>
                                        <td className="p-2 text-right">
                                          {typeof m.wearPercentage === 'number'
                                            ? `${Math.round(m.wearPercentage * 100)}%`
                                            : '—'}
                                        </td>
                                        <td className="p-2 text-muted-foreground">
                                          {m.createdAt
                                            ? new Date(m.createdAt).toLocaleString('pt-BR')
                                            : '—'}
                                        </td>
                                      </tr>
                                    );
                                  })}
                                </tbody>
                              </table>
                            </div>
                            <p className="text-xs font-medium pt-1">Histórico (últimos 12)</p>
                            <ul className="text-xs space-y-1 list-disc pl-4">
                              {b.maintenanceLogs.slice(0, 12).map((m) => (
                                <li key={`${m.id}-hist`}>
                                  {m.createdAt
                                    ? new Date(m.createdAt).toLocaleString('pt-BR')
                                    : '—'}{' '}
                                  — {m.partName}: {m.status}
                                  {typeof m.wearPercentage === 'number'
                                    ? ` (${Math.round(m.wearPercentage * 100)}%)`
                                    : ''}
                                  {typeof m.lastChangeKm === 'number'
                                    ? ` · última troca ${m.lastChangeKm} km`
                                    : ''}
                                </li>
                              ))}
                            </ul>
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                )}
              </section>

              {/* Delivery: cadastro */}
              <section>
                <h4 className="text-sm font-semibold flex items-center gap-2 mb-2">
                  <Package className="h-4 w-4" />
                  Cadastro de entregador (delivery)
                </h4>
                {deliveryRegs.length === 0 ? (
                  <p className="text-sm text-muted-foreground">Sem registo de entregador.</p>
                ) : (
                  <div className="space-y-6">
                    {deliveryRegs.map((reg) => (
                      <div key={reg.id} className="border rounded-lg p-3 space-y-3">
                        <div className="flex flex-wrap gap-2 items-center">
                          <Badge>{reg.status}</Badge>
                          {reg.vehicleType === 'BICYCLE' && (
                            <Badge variant="secondary" className="text-xs">Bicicleta</Badge>
                          )}
                          <span className="text-xs text-muted-foreground">
                            Criado: {new Date(reg.createdAt).toLocaleString('pt-BR')}
                          </span>
                        </div>
                        <div className="grid sm:grid-cols-2 gap-2 text-sm">
                          <p>
                            <span className="text-muted-foreground">CPF / documento</span>
                            <br />
                            {reg.cpfCnh}
                          </p>
                          <p>
                            <span className="text-muted-foreground">
                              {reg.vehicleType === 'BICYCLE' ? 'Nº identificação' : 'Placa / CRLV'}
                            </span>
                            <br />
                            <span className="font-mono font-medium">{reg.plateLicense}</span>
                          </p>
                          <p>
                            <span className="text-muted-foreground">Quilometragem declarada</span>
                            <br />
                            {reg.currentKilometers} km
                          </p>
                          {reg.emergencyPhone && (
                            <p>
                              <span className="text-muted-foreground">Emergência</span>
                              <br />
                              {reg.emergencyPhone}
                            </p>
                          )}
                        </div>
                        {reg.equipments && reg.equipments.length > 0 && (
                          <div className="flex flex-wrap gap-1">
                            {reg.equipments.map((e) => (
                              <Badge key={e} variant="outline" className="text-xs">
                                {e}
                              </Badge>
                            ))}
                          </div>
                        )}
                        {reg.bikeOptionalReceiptData && (
                          <B64Img data={reg.bikeOptionalReceiptData} label="Comprovante (nota / canhoto)" />
                        )}
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                          <B64Img data={reg.selfieWithDocData} label="Selfie com documento" />
                          <B64Img data={reg.cnhPhotoData} label="CNH" />
                          <B64Img data={reg.crlvPhotoData} label="CRLV" />
                          <B64Img data={reg.motoWithPlateData} label="Veículo (com identificação)" />
                          <B64Img data={reg.platePlateCloseupData} label="Placa (close-up)" />
                        </div>
                        <p className="text-xs text-muted-foreground">
                          Consentiu uso de imagens: {reg.consentImages ? 'sim' : 'não'}
                        </p>
                        {reg.status === 'REJECTED' && reg.rejectionReason && (
                          <p className="text-sm text-destructive">Motivo rejeição: {reg.rejectionReason}</p>
                        )}
                        {reg.adminNotes && (
                          <p className="text-xs text-muted-foreground">Notas admin: {reg.adminNotes}</p>
                        )}
                        {reg.status === 'APPROVED' && reg.approvedAt && (
                          <p className="text-xs text-emerald-700 dark:text-emerald-400 flex items-center gap-1">
                            <CheckCircle2 className="h-3.5 w-3.5" />
                            Aprovado em {new Date(reg.approvedAt).toLocaleString('pt-BR')}{' '}
                            {reg.approvedBy ? `por ${reg.approvedBy}` : ''}
                          </p>
                        )}
                      </div>
                    ))}
                  </div>
                )}
              </section>
            </div>
          </ScrollArea>
        )}

        <div className="flex shrink-0 flex-wrap justify-between gap-2 border-t px-4 py-3 sm:px-6">
          {userId && onFollowRequest && currentUserId && currentUserId !== userId && (
            <Button
              type="button"
              variant="secondary"
              disabled={followRequestSent || followRequestLoading}
              onClick={() => onFollowRequest(userId)}
            >
              {followRequestSent ? 'Solicitação enviada' : followRequestLoading ? 'Enviando...' : 'Solicitar seguir'}
            </Button>
          )}
          <div className="ml-auto">
            <Button type="button" variant="secondary" onClick={() => onOpenChange(false)}>
              Fechar
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
