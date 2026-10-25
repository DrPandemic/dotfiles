import { useEffect, useState } from "react";
import { definePluginApp, useRpc } from "@get-bb/plugin-sdk/app";
import type { Credits, Quota, QuotaWindow, Quotas, rpcContract } from "./server";

type ProviderKey = "anthropic" | "openai";

const PROVIDERS: Record<ProviderKey, { id: string; name: string; icon: string; color: string }> = {
  anthropic: { id: "anthropic", name: "Claude", icon: "Asterisk", color: "#D97757" },
  openai: { id: "openai", name: "Codex", icon: "Aperture", color: "#10A37F" },
};

const POLL_MS = 60_000;
const DANGER_PERCENT = 80;
const DANGER_COLOR = "#EF4444";
const LOW_BALANCE_USD = 5;
const OPENROUTER_COLOR = "#8B5CF6";
const BADGE_ATTR = "data-quota-bar-badge";

function formatReset(resetsAt: string | null): string {
  if (resetsAt === null) return "";
  const minutes = Math.max(0, Math.round((Date.parse(resetsAt) - Date.now()) / 60_000));
  const span = minutes >= 60 ? `${Math.floor(minutes / 60)}h ${minutes % 60}m` : `${minutes}m`;
  return `resets in ${span}`;
}

function shortWindow(quota: Quota): QuotaWindow | null {
  if (quota === null) return null;
  return quota.windows.find((w) => /five-hour|5-hour|5h/i.test(w.label)) ?? quota.windows[0];
}

function WindowRow({ window, color }: { window: QuotaWindow; color: string }) {
  const percent = Math.min(100, Math.max(0, window.usedPercent));
  return (
    <div className="flex flex-col gap-1">
      <div className="flex items-baseline justify-between gap-2 text-muted-foreground">
        <span>
          {window.label}
          {window.resetsAt ? ` · ${formatReset(window.resetsAt)}` : ""}
        </span>
        <span className="tabular-nums text-foreground">{Math.round(window.usedPercent)}%</span>
      </div>
      <div className="h-1.5 overflow-hidden rounded-full bg-muted">
        <div
          className="h-full rounded-full"
          style={{ width: `${percent}%`, backgroundColor: percent >= DANGER_PERCENT ? DANGER_COLOR : color }}
        />
      </div>
    </div>
  );
}

function ProviderQuota({ provider, quota }: { provider: ProviderKey; quota: Quota }) {
  const { name, color } = PROVIDERS[provider];
  return (
    <div className="flex flex-col gap-2">
      <span className="font-medium text-foreground">
        {name}
        {quota?.plan ? <span className="text-muted-foreground"> · {quota.plan}</span> : null}
      </span>
      {quota === null ? (
        <span className="text-muted-foreground">No usage reported. Is {name} signed in?</span>
      ) : (
        quota.windows.map((window) => <WindowRow key={window.label} window={window} color={color} />)
      )}
    </div>
  );
}

function OpenRouterCredits({ credits }: { credits: Credits }) {
  const low = credits !== null && credits.remaining <= LOW_BALANCE_USD;
  const usedPercent =
    credits !== null && credits.total !== null && credits.usage !== null && credits.total > 0
      ? Math.min(100, Math.max(0, (credits.usage / credits.total) * 100))
      : null;
  return (
    <div className="flex flex-col gap-2">
      <span className="font-medium text-foreground">
        OpenRouter <span className="text-muted-foreground">· pi credits</span>
      </span>
      {credits === null ? (
        <span className="text-muted-foreground">No credits reported. Is OpenRouter signed in to pi?</span>
      ) : (
        <div className="flex flex-col gap-1">
          <div className="flex items-baseline justify-between gap-2 text-muted-foreground">
            <span>Credits left</span>
            <span className={`tabular-nums ${low ? "text-destructive" : "text-foreground"}`}>
              ${credits.remaining.toFixed(2)}
            </span>
          </div>
          {usedPercent !== null ? (
            <div className="h-1.5 overflow-hidden rounded-full bg-muted">
              <div
                className="h-full rounded-full"
                style={{ width: `${usedPercent}%`, backgroundColor: low ? DANGER_COLOR : OPENROUTER_COLOR }}
              />
            </div>
          ) : null}
        </div>
      )}
    </div>
  );
}

function QuotaDetails({ provider }: { provider: ProviderKey }) {
  const rpc = useRpc<typeof rpcContract>();
  const [quotas, setQuotas] = useState<Quotas | null>(null);
  const [error, setError] = useState<string | null>(null);
  useEffect(() => {
    rpc.call("quota", { force: true }).then(setQuotas, (cause: unknown) =>
      setError(cause instanceof Error ? cause.message : String(cause)),
    );
  }, [rpc]);
  const order = [provider, ...(Object.keys(PROVIDERS) as ProviderKey[]).filter((key) => key !== provider)];
  return (
    <div className="flex flex-col gap-3 px-3 py-2 text-xs">
      {error !== null ? (
        <span className="text-destructive">{error}</span>
      ) : quotas === null ? (
        <span className="text-muted-foreground">Loading…</span>
      ) : (
        <>
          {order.map((key) => (
            <ProviderQuota key={key} provider={key} quota={quotas[key]} />
          ))}
          <div className="border-t border-border" />
          <OpenRouterCredits credits={quotas.openrouter} />
        </>
      )}
    </div>
  );
}

function ringSvg(percent: number, color: string): string {
  const radius = 9;
  const circumference = 2 * Math.PI * radius;
  const filled = (Math.min(100, Math.max(0, percent)) / 100) * circumference;
  return `<svg width="22" height="22" viewBox="0 0 22 22" aria-hidden="true" style="position:absolute;inset:0;margin:auto;transform:rotate(-90deg)"><circle cx="11" cy="11" r="${radius}" fill="none" stroke="currentColor" stroke-opacity="0.2" stroke-width="2"/><circle cx="11" cy="11" r="${radius}" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-dasharray="${filled} ${circumference}"/></svg>`;
}

function badgeHtml(provider: ProviderKey, quota: Quota): string {
  const window = shortWindow(quota);
  if (window === null) return "";
  const percent = Math.round(window.usedPercent);
  const color = percent >= DANGER_PERCENT ? DANGER_COLOR : PROVIDERS[provider].color;
  const fontSize = percent >= 100 ? 7 : 9;
  return `${ringSvg(percent, color)}<span style="position:relative;font-size:${fontSize}px;font-weight:600;line-height:1;font-variant-numeric:tabular-nums">${percent}</span>`;
}

export default definePluginApp((app) => {
  for (const provider of Object.keys(PROVIDERS) as ProviderKey[]) {
    const { id, name, icon } = PROVIDERS[provider];
    app.experimental_sidebarFooter.register({
      kind: "disclosure",
      id,
      label: `${name} usage`,
      icon,
      component: () => <QuotaDetails provider={provider} />,
    });
  }

  app.contentScripts.register({
    id: "footer-badges",
    mount({ pluginId, signal }) {
      let quotas: Quotas | null = null;
      let frame: number | null = null;

      const decorate = () => {
        frame = null;
        for (const provider of Object.keys(PROVIDERS) as ProviderKey[]) {
          const button = document.querySelector<HTMLElement>(
            `[data-testid="plugin-sidebar-footer-item-${pluginId}-${PROVIDERS[provider].id}"]`,
          );
          if (button === null) continue;
          const html = quotas === null ? "" : badgeHtml(provider, quotas[provider]);
          let badge = button.querySelector<HTMLElement>(`[${BADGE_ATTR}]`);
          const icon = button.querySelector<HTMLElement>(":scope > [data-icon-root]");
          if (html === "") {
            badge?.remove();
            if (icon) icon.style.display = "";
            continue;
          }
          if (badge === null) {
            badge = document.createElement("span");
            badge.setAttribute(BADGE_ATTR, "");
            badge.style.cssText =
              "position:relative;display:inline-flex;align-items:center;justify-content:center;width:22px;height:22px;pointer-events:none";
            button.append(badge);
          }
          if (badge.dataset.html !== html) {
            badge.innerHTML = html;
            badge.dataset.html = html;
          }
          if (icon && icon.style.display !== "none") icon.style.display = "none";
        }
      };
      const schedule = () => {
        if (frame === null) frame = requestAnimationFrame(decorate);
      };

      const refresh = async () => {
        try {
          const response = await fetch(`/api/v1/plugins/${encodeURIComponent(pluginId)}/rpc/quota`, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: JSON.stringify({ force: false }),
            signal,
          });
          const body = (await response.json()) as { ok?: boolean; result?: Quotas };
          quotas = response.ok && body.ok === true && body.result ? body.result : null;
        } catch {
          if (signal.aborted) return;
          quotas = null;
        }
        schedule();
      };

      const observer = new MutationObserver(schedule);
      observer.observe(document.body, { childList: true, subtree: true });
      const timer = window.setInterval(() => {
        if (document.visibilityState === "visible") void refresh();
      }, POLL_MS);
      const onVisible = () => {
        if (document.visibilityState === "visible") void refresh();
      };
      document.addEventListener("visibilitychange", onVisible);
      const firstRefresh = requestIdleCallback(() => void refresh(), { timeout: 5_000 });

      return () => {
        cancelIdleCallback(firstRefresh);
        observer.disconnect();
        window.clearInterval(timer);
        document.removeEventListener("visibilitychange", onVisible);
        if (frame !== null) cancelAnimationFrame(frame);
        quotas = null;
        decorate();
      };
    },
  });
});
