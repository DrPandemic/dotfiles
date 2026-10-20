import { defineRpcContract, type BbPluginApi, type JsonValue } from "@get-bb/plugin-sdk";
import { z } from "zod";

export const TREE_CHANGED = "tree-changed";
export const MERGE_STATUS = "merge-status";

const ANCHOR_MAX = 4000;
const SUMMARY_TIMEOUT_MS = 15 * 60 * 1000;
const SUMMARY_PROMPT = [
  "We're about to merge this side branch back into the conversation it came from.",
  "Write a concise summary of what this branch established: the conclusions, decisions, and any facts or code worth carrying over.",
  "Reply with only the summary, no preamble.",
].join(" ");

const mergeRecordSchema = z.object({
  intoThreadId: z.string(),
  mode: z.enum(["summary", "last", "message"]),
  at: z.number(),
});
export type MergeRecord = z.infer<typeof mergeRecordSchema>;

const branchMetadataSchema = z.object({
  rootThreadId: z.string(),
  parentThreadId: z.string(),
  anchorText: z.string().default(""),
  merges: z.array(mergeRecordSchema).default([]),
});
type BranchMetadata = z.infer<typeof branchMetadataSchema>;

const treeNodeSchema = z.object({
  id: z.string(),
  parentId: z.string().nullable(),
  title: z.string(),
  status: z.string(),
  anchorText: z.string(),
  createdAt: z.number(),
  updatedAt: z.number(),
  merges: z.array(mergeRecordSchema),
  isBranch: z.boolean(),
});
export type TreeNode = z.infer<typeof treeNodeSchema>;

const mergeModeSchema = z.enum(["summary", "last", "message"]);
export type MergeMode = z.infer<typeof mergeModeSchema>;

export const rpcContract = defineRpcContract({
  createBranch: {
    input: z
      .object({
        sourceThreadId: z.string().trim().min(1),
        sourceSeqEnd: z.number().int().nonnegative().optional(),
        anchorText: z.string(),
      })
      .strict(),
    output: z.object({ threadId: z.string(), rootThreadId: z.string() }),
  },
  tree: {
    input: z.object({ threadId: z.string().trim().min(1) }).strict(),
    output: z.object({ rootThreadId: z.string(), nodes: z.array(treeNodeSchema) }),
  },
  merge: {
    input: z
      .object({
        fromThreadId: z.string().trim().min(1),
        toThreadId: z.string().trim().min(1),
        mode: mergeModeSchema,
        text: z.string().optional(),
      })
      .strict(),
    output: z.object({ started: z.boolean() }),
  },
  archiveBranch: {
    input: z.object({ threadId: z.string().trim().min(1) }).strict(),
    output: z.object({ archived: z.boolean() }),
  },
});

function snippet(text: string, max: number): string {
  const flat = text.replace(/\s+/g, " ").trim();
  return flat.length > max ? `${flat.slice(0, max - 1)}…` : flat;
}

function isSessionUnavailableError(error: unknown): boolean {
  return (
    typeof error === "object" &&
    error !== null &&
    "code" in error &&
    (error as { code: unknown }).code === "fork_source_session_unavailable"
  );
}

export default async function plugin(bb: BbPluginApi) {
  const pendingIdle = new Map<string, (text: string | null) => void>();

  bb.events.on("thread.idle", ({ thread, lastAssistantText }) => {
    const resolve = pendingIdle.get(thread.id);
    if (resolve === undefined) return;
    pendingIdle.delete(thread.id);
    resolve(lastAssistantText);
  });

  async function readBranchMetadata(threadId: string): Promise<BranchMetadata | null> {
    const raw = await bb.sdk.threads.getPluginMetadata({ threadId, pluginId: bb.pluginId });
    const parsed = branchMetadataSchema.safeParse(raw);
    return parsed.success ? parsed.data : null;
  }

  async function resolveRoot(threadId: string): Promise<string> {
    const metadata = await readBranchMetadata(threadId);
    return metadata?.rootThreadId ?? threadId;
  }

  function publishTree(rootThreadId: string): void {
    bb.realtime.publish(TREE_CHANGED, { rootThreadId });
  }

  async function createBranch(input: {
    sourceThreadId: string;
    sourceSeqEnd?: number;
    anchorText: string;
  }): Promise<{ threadId: string; rootThreadId: string }> {
    const rootThreadId = await resolveRoot(input.sourceThreadId);
    const anchorText = input.anchorText.trim().slice(0, ANCHOR_MAX);
    const metadata: { [key: string]: JsonValue } = {
      rootThreadId,
      parentThreadId: input.sourceThreadId,
      anchorText,
      merges: [],
    };
    const base = {
      sourceThreadId: input.sourceThreadId,
      lifecycleOwnerThreadId: rootThreadId,
      visibility: "hidden" as const,
      title: anchorText.length > 0 ? `⑂ ${snippet(anchorText, 48)}` : "⑂ Branch",
      pluginMetadata: metadata,
      ...(anchorText.length > 0
        ? {
            agentContextSeed: [
              {
                type: "text" as const,
                text: `This is a side branch of the conversation. The user branched off to discuss this part of an earlier message:\n\n${anchorText}`,
                mentions: [],
                visibility: "agent-only" as const,
              },
            ],
          }
        : {}),
    };
    let fork;
    try {
      fork = await bb.sdk.threads.fork({
        ...base,
        ...(input.sourceSeqEnd !== undefined ? { sourceSeqEnd: input.sourceSeqEnd } : {}),
      });
    } catch (error) {
      if (input.sourceSeqEnd === undefined || !isSessionUnavailableError(error)) throw error;
      fork = await bb.sdk.threads.fork(base);
    }
    publishTree(rootThreadId);
    return { threadId: fork.id, rootThreadId };
  }

  async function buildTree(threadId: string): Promise<{ rootThreadId: string; nodes: TreeNode[] }> {
    const rootThreadId = await resolveRoot(threadId);
    const root = await bb.sdk.threads.get({ threadId: rootThreadId });
    const nodes: TreeNode[] = [
      {
        id: root.id,
        parentId: null,
        title: root.title ?? root.titleFallback ?? "Main thread",
        status: root.status,
        anchorText: "",
        createdAt: root.createdAt,
        updatedAt: root.updatedAt,
        merges: [],
        isBranch: false,
      },
    ];
    const queue = [rootThreadId];
    const seen = new Set(queue);
    while (queue.length > 0 && nodes.length < 500) {
      const parentId = queue.shift()!;
      const children = await bb.sdk.threads.list({
        sourceThreadId: parentId,
        includeHidden: true,
        archived: false,
        originKind: "fork",
        limit: 200,
      });
      const fresh = children.filter((child) => !seen.has(child.id));
      if (fresh.length === 0) continue;
      const metadataRows = await bb.sdk.threads.experimental_listPluginMetadata({
        pluginId: bb.pluginId,
        threadIds: fresh.map((child) => child.id),
      });
      const metadataById = new Map<string, BranchMetadata>();
      for (const row of metadataRows.threads ?? []) {
        const parsed = branchMetadataSchema.safeParse(row.metadata);
        if (parsed.success) metadataById.set(row.threadId, parsed.data);
      }
      for (const child of fresh.sort((a, b) => a.createdAt - b.createdAt)) {
        seen.add(child.id);
        queue.push(child.id);
        const metadata = metadataById.get(child.id);
        nodes.push({
          id: child.id,
          parentId,
          title: child.title ?? child.titleFallback ?? "Branch",
          status: child.status,
          anchorText: metadata?.anchorText ?? "",
          createdAt: child.createdAt,
          updatedAt: child.updatedAt,
          merges: metadata?.merges ?? [],
          isBranch: true,
        });
      }
    }
    return { rootThreadId, nodes };
  }

  async function summarize(threadId: string): Promise<string> {
    const thread = await bb.sdk.threads.get({ threadId });
    if (thread.status !== "idle") throw new Error("Branch is busy; wait for it to finish before merging a summary.");
    const idle = new Promise<string | null>((resolve, reject) => {
      const timer = setTimeout(() => {
        pendingIdle.delete(threadId);
        reject(new Error("Timed out waiting for the branch summary."));
      }, SUMMARY_TIMEOUT_MS);
      pendingIdle.set(threadId, (text) => {
        clearTimeout(timer);
        resolve(text);
      });
    });
    try {
      await bb.sdk.threads.send({
        threadId,
        mode: "start",
        input: [{ type: "text", text: SUMMARY_PROMPT, mentions: [] }],
      });
    } catch (error) {
      pendingIdle.delete(threadId);
      throw error;
    }
    const text = await idle;
    if (text === null || text.trim().length === 0) throw new Error("The branch produced an empty summary.");
    return text.trim();
  }

  async function runMerge(input: {
    fromThreadId: string;
    toThreadId: string;
    mode: MergeMode;
    text?: string;
  }): Promise<void> {
    const from = await bb.sdk.threads.get({ threadId: input.fromThreadId });
    const metadata = await readBranchMetadata(input.fromThreadId);
    let body: string;
    if (input.mode === "summary") {
      body = await summarize(input.fromThreadId);
    } else if (input.mode === "message") {
      body = (input.text ?? "").trim();
    } else {
      body = ((await bb.sdk.threads.output({ threadId: input.fromThreadId })).output ?? "").trim();
    }
    if (body.length === 0) throw new Error("Nothing to merge.");
    const label = from.title ?? from.titleFallback ?? "side branch";
    const anchor = metadata?.anchorText ? `\nIt branched off from: "${snippet(metadata.anchorText, 200)}"` : "";
    const heading =
      input.mode === "summary"
        ? "Merging back a side branch. Summary of what it concluded:"
        : "Merging back a reply from a side branch:";
    await bb.sdk.threads.queuedMessages.create({
      threadId: input.toThreadId,
      senderThreadId: input.fromThreadId,
      input: [
        {
          type: "text",
          text: `[Branch: ${label}]${anchor}\n\n${heading}\n\n${body}`,
          mentions: [],
        },
      ],
    });
    if (metadata !== null) {
      const merges = [...metadata.merges, { intoThreadId: input.toThreadId, mode: input.mode, at: Date.now() }];
      await bb.sdk.threads.updatePluginMetadata({
        threadId: input.fromThreadId,
        pluginId: bb.pluginId,
        set: { merges },
      });
      publishTree(metadata.rootThreadId);
    }
  }

  bb.rpc.register(rpcContract, {
    createBranch: (input) => createBranch(input),
    tree: ({ threadId }) => buildTree(threadId),
    merge: async (input) => {
      if (input.fromThreadId === input.toThreadId) throw new Error("Pick a different thread to merge into.");
      bb.realtime.publish(MERGE_STATUS, { fromThreadId: input.fromThreadId, state: "running" });
      void runMerge(input).then(
        () => bb.realtime.publish(MERGE_STATUS, { fromThreadId: input.fromThreadId, state: "done" }),
        (error: unknown) => {
          const message = error instanceof Error ? error.message : String(error);
          bb.log.warn(`merge ${input.fromThreadId} -> ${input.toThreadId} failed: ${message}`);
          bb.realtime.publish(MERGE_STATUS, { fromThreadId: input.fromThreadId, state: "error", error: message });
        },
      );
      return { started: true };
    },
    archiveBranch: async ({ threadId }) => {
      const metadata = await readBranchMetadata(threadId);
      if (metadata === null) throw new Error("Only branches can be archived from here.");
      await bb.sdk.threads.archive({ threadId });
      await bb.sdk.threads.stop({ threadId }).catch(() => undefined);
      publishTree(metadata.rootThreadId);
      return { archived: true };
    },
  });

  bb.onDispose(() => {
    pendingIdle.clear();
  });
}
