import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { defineRpcContract, type BbPluginApi } from "@get-bb/plugin-sdk";
import { z } from "zod";

const windowSchema = z.object({
  label: z.string(),
  usedPercent: z.number(),
  resetsAt: z.string().nullable(),
});
export type QuotaWindow = z.infer<typeof windowSchema>;

const quotaSchema = z
  .object({ plan: z.string().nullable(), windows: z.array(windowSchema).min(1) })
  .nullable();
export type Quota = z.infer<typeof quotaSchema>;

// OpenRouter reports a dollar balance, not a percent window, so it stays out
// of `Quota` and the sidebar icons. It is only shown inside an open panel.
const creditsSchema = z
  .object({
    remaining: z.number(),
    total: z.number().nullable(),
    usage: z.number().nullable(),
  })
  .nullable();
export type Credits = z.infer<typeof creditsSchema>;

const quotasSchema = z.object({ anthropic: quotaSchema, openai: quotaSchema, openrouter: creditsSchema });
export type Quotas = z.infer<typeof quotasSchema>;

export const rpcContract = defineRpcContract({
  quota: {
    input: z.object({ force: z.boolean() }),
    output: quotasSchema,
  },
});

const usageSchema = z.object({
  machines: z.array(
    z.object({
      providers: z.array(
        z.object({
          providerId: z.string(),
          usage: z
            .object({
              status: z.string(),
              planLabel: z.string().nullish(),
              windows: z.array(windowSchema).optional(),
            })
            .nullable(),
        }),
      ),
    }),
  ),
});

const PROVIDER_IDS = { anthropic: "claude-code", openai: "codex" } as const;

const OPENROUTER_CREDITS_URL = "https://openrouter.ai/api/v1/credits";
const OPENROUTER_KEY_URL = "https://openrouter.ai/api/v1/key";
const CREDITS_TTL_MS = 60_000;

let creditsCache: { at: number; value: Credits } | null = null;

/**
 * Read the OpenRouter credential Pi is authenticated with: an explicit env
 * override first, then Pi's own auth store (OAuth access token or API key) at
 * ~/.pi/agent/auth.json. This mirrors what Pi shows in its footer.
 */
async function readPiOpenRouterKey(): Promise<string | null> {
  const fromEnv = process.env.OPENROUTER_API_KEY?.trim();
  if (fromEnv) return fromEnv;
  try {
    const raw = await readFile(join(homedir(), ".pi", "agent", "auth.json"), "utf8");
    const parsed = JSON.parse(raw) as { openrouter?: Record<string, unknown> };
    const entry = parsed.openrouter;
    if (entry === undefined || entry === null) return null;
    for (const field of ["access", "key", "apiKey"]) {
      const value = entry[field];
      if (typeof value === "string" && value.trim().length > 0) return value.trim();
    }
  } catch {
    // No Pi auth file, or it is unreadable/not JSON: report no credits.
  }
  return null;
}

async function fetchOpenRouterCredits(signal: AbortSignal): Promise<Credits> {
  const apiKey = await readPiOpenRouterKey();
  if (apiKey === null) return null;
  const headers = { authorization: `Bearer ${apiKey}` };
  try {
    const response = await fetch(OPENROUTER_CREDITS_URL, { headers, signal });
    if (response.ok) {
      const body = (await response.json()) as {
        data?: { total_credits?: unknown; total_usage?: unknown };
      };
      const total = body.data?.total_credits;
      const usage = body.data?.total_usage;
      if (typeof total === "number" && typeof usage === "number") {
        return { remaining: total - usage, total, usage };
      }
    }
  } catch {
    // Fall through to the key-level endpoint below.
  }
  try {
    const response = await fetch(OPENROUTER_KEY_URL, { headers, signal });
    if (!response.ok) return null;
    const body = (await response.json()) as { data?: { limit_remaining?: unknown } };
    const remaining = body.data?.limit_remaining;
    if (typeof remaining === "number") return { remaining, total: null, usage: null };
  } catch {
    // Ignore: the panel reports credits as unavailable.
  }
  return null;
}

async function openRouterCredits(force: boolean): Promise<Credits> {
  const now = Date.now();
  if (!force && creditsCache !== null && now - creditsCache.at < CREDITS_TTL_MS) {
    return creditsCache.value;
  }
  const value = await fetchOpenRouterCredits(AbortSignal.timeout(15_000));
  creditsCache = { at: now, value };
  return value;
}

export default async function plugin(bb: BbPluginApi) {
  bb.rpc.register(rpcContract, {
    async quota({ force }) {
      // Credits come from OpenRouter directly and must not take the panel down
      // when the key is missing or the request fails.
      const creditsPromise = openRouterCredits(force).catch((cause: unknown) => {
        bb.log.warn(
          `OpenRouter credits unavailable: ${cause instanceof Error ? cause.message : String(cause)}`,
        );
        return null;
      });
      const { machines } = await bb.sdk.plugins.callRpc({
        pluginId: "bb--provider-usage",
        method: "getUsage",
        input: {
          force,
          machineIds: null,
          providerIds: Object.values(PROVIDER_IDS),
          maxAgeMs: 60_000,
        },
        outputSchema: usageSchema,
        signal: AbortSignal.timeout(45_000),
      });
      // getUsage lists the primary host first, so the first ok entry wins.
      const quotaFor = (providerId: string): Quota => {
        for (const machine of machines) {
          for (const provider of machine.providers) {
            const usage = provider.usage;
            if (provider.providerId !== providerId || usage?.status !== "ok" || !usage.windows?.length) continue;
            return { plan: usage.planLabel ?? null, windows: usage.windows };
          }
        }
        return null;
      };
      return {
        anthropic: quotaFor(PROVIDER_IDS.anthropic),
        openai: quotaFor(PROVIDER_IDS.openai),
        openrouter: await creditsPromise,
      };
    },
  });
}
