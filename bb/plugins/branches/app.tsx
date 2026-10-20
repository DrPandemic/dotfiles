import { useCallback, useEffect, useMemo, useState } from "react";
import type { ReactNode } from "react";
import { toast } from "sonner";
import {
  definePluginApp,
  Markdown,
  ThreadChat,
  useBbNavigate,
  useRealtime,
  useRpc,
  type JsonValue,
} from "@get-bb/plugin-sdk/app";
import type { MergeMode, rpcContract, TreeNode } from "./server";
import { Button } from "@/components/ui/button";
import { Icon } from "@/components/ui/icon";
import { cn } from "@/lib/utils";
import { BranchGraph } from "@/components/branch-graph";

const TREE_PANEL = "branches";
const BRANCH_PANEL = "branch";
const BRANCH_ICON = "GitBranch";

type Rpc = ReturnType<typeof useRpc<typeof rpcContract>>;
type OpenPanel = (options: { actionId: string; title?: string; params?: JsonValue }) => boolean;

interface BranchParams {
  threadId: string;
}

function parseBranchParams(params: JsonValue | null): BranchParams | null {
  if (typeof params !== "object" || params === null || Array.isArray(params)) return null;
  const threadId = (params as Record<string, JsonValue>).threadId;
  return typeof threadId === "string" && threadId.length > 0 ? { threadId } : null;
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

function snippet(text: string, max: number): string {
  const flat = text.replace(/\s+/g, " ").trim();
  return flat.length > max ? `${flat.slice(0, max - 1)}…` : flat;
}

function openBranch(openPanel: OpenPanel, node: { id: string; title: string }): boolean {
  return openPanel({ actionId: BRANCH_PANEL, title: snippet(node.title, 32), params: { threadId: node.id } });
}

async function startBranch(
  rpc: Rpc,
  openPanel: OpenPanel,
  input: { sourceThreadId: string; sourceSeqEnd?: number; anchorText: string },
): Promise<void> {
  try {
    const { threadId } = await rpc.call("createBranch", input);
    const title = input.anchorText.trim().length > 0 ? `⑂ ${snippet(input.anchorText, 28)}` : "⑂ Branch";
    openBranch(openPanel, { id: threadId, title });
  } catch (error) {
    toast.error(`Could not create branch: ${errorMessage(error)}`);
  }
}

function useTree(threadId: string) {
  const rpc = useRpc<typeof rpcContract>();
  const [nodes, setNodes] = useState<TreeNode[] | null>(null);
  const [rootThreadId, setRootThreadId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const refetch = useCallback(() => {
    rpc.call("tree", { threadId }).then(
      (result) => {
        setNodes(result.nodes);
        setRootThreadId(result.rootThreadId);
        setError(null);
      },
      (cause: unknown) => setError(errorMessage(cause)),
    );
  }, [rpc, threadId]);
  useEffect(() => {
    refetch();
  }, [refetch]);
  useRealtime("tree-changed", refetch);
  return { rpc, nodes, rootThreadId, error, refetch };
}

function useMergeStatus(threadId: string): "idle" | "running" {
  const [state, setState] = useState<"idle" | "running">("idle");
  useRealtime("merge-status", (payload) => {
    if (typeof payload !== "object" || payload === null) return;
    const event = payload as { fromThreadId?: unknown; state?: unknown; error?: unknown };
    if (event.fromThreadId !== threadId) return;
    if (event.state === "running") setState("running");
    if (event.state === "done") {
      setState("idle");
      toast.success("Merged");
    }
    if (event.state === "error") {
      setState("idle");
      toast.error(`Merge failed: ${typeof event.error === "string" ? event.error : "unknown error"}`);
    }
  });
  return state;
}

function TreeView({
  threadId,
  activeId,
  onOpen,
}: {
  threadId: string;
  activeId: string | null;
  onOpen: (node: TreeNode) => void;
}) {
  const { rpc, nodes, error } = useTree(threadId);
  if (error !== null) return <p className="text-sm text-destructive">{error}</p>;
  if (nodes === null) return <p className="text-sm text-muted-foreground">Loading…</p>;
  return (
    <div className="flex flex-col gap-2">
      <BranchGraph
        nodes={nodes}
        activeId={activeId}
        onOpen={onOpen}
        onArchive={(node) => {
          rpc.call("archiveBranch", { threadId: node.id }).catch((cause: unknown) => toast.error(errorMessage(cause)));
        }}
      />
      {nodes.length === 1 && (
        <p className="px-1.5 text-xs text-muted-foreground">
          No branches yet. Hover a message (or select text in it) and choose “Branch from here”.
        </p>
      )}
    </div>
  );
}

function TreePanel({ threadId }: { threadId: string; params: JsonValue | null }) {
  const navigate = useBbNavigate();
  return (
    <TreeView
      threadId={threadId}
      activeId={threadId}
      onOpen={(node) => {
        if (!node.isBranch) {
          if (node.id !== threadId) navigate.toThread(node.id);
          return;
        }
        openBranch(navigate.openThreadPanel, node);
      }}
    />
  );
}

function AnchorQuote({ text }: { text: string }) {
  const [expanded, setExpanded] = useState(false);
  if (text.trim().length === 0) return null;
  return (
    <div className="mx-1 mb-2 flex flex-col items-start gap-1">
      <span className="text-xs text-muted-foreground">
        <Icon name="CornerDownRight" className="mr-1 inline-block size-3 align-middle" />
        Branched from
      </span>
      <button
        type="button"
        className="max-w-full cursor-pointer rounded-md bg-surface-recessed p-1.5 text-left text-xs"
        onClick={() => setExpanded((value) => !value)}
      >
        <div className={cn("break-words", !expanded && "max-h-20 overflow-hidden")}>
          <Markdown content={text} className="text-xs leading-5" />
        </div>
      </button>
    </div>
  );
}

function MergeBar({
  branch,
  nodes,
  rpc,
}: {
  branch: TreeNode;
  nodes: TreeNode[];
  rpc: Rpc;
}) {
  const targets = nodes.filter((node) => node.id !== branch.id);
  const [target, setTarget] = useState<string>(branch.parentId ?? targets[0]?.id ?? "");
  const [mode, setMode] = useState<MergeMode>("summary");
  const status = useMergeStatus(branch.id);
  useEffect(() => {
    if (!targets.some((node) => node.id === target)) setTarget(branch.parentId ?? targets[0]?.id ?? "");
  }, [targets, target, branch.parentId]);
  const merge = () => {
    if (target === "") return;
    rpc.call("merge", { fromThreadId: branch.id, toThreadId: target, mode }).catch((cause: unknown) =>
      toast.error(`Merge failed: ${errorMessage(cause)}`),
    );
  };
  const selectClass = "h-7 min-w-0 rounded-md border border-input bg-transparent px-1.5 text-xs";
  return (
    <div className="flex flex-wrap items-center gap-1.5 border-b border-border px-2 py-1.5 text-xs">
      <span className="text-muted-foreground">Merge</span>
      <select className={selectClass} value={mode} onChange={(event) => setMode(event.target.value as MergeMode)}>
        <option value="summary">summary</option>
        <option value="last">last reply</option>
      </select>
      <span className="text-muted-foreground">into</span>
      <select className={cn(selectClass, "max-w-44 flex-1")} value={target} onChange={(event) => setTarget(event.target.value)}>
        {targets.map((node) => (
          <option key={node.id} value={node.id}>
            {node.id === branch.parentId ? "↑ " : ""}
            {node.isBranch ? snippet(node.title, 40) : `Main · ${snippet(node.title, 34)}`}
          </option>
        ))}
      </select>
      <Button size="sm" className="h-7 px-2.5" disabled={status === "running" || target === ""} onClick={merge}>
        <Icon name="GitMerge" fallback="ArrowTurnBackward" className="size-3.5" />
        {status === "running" ? "Merging…" : "Merge"}
      </Button>
    </div>
  );
}

function BranchPanel({ threadId, params }: { threadId: string; params: JsonValue | null }) {
  const navigate = useBbNavigate();
  const parsed = parseBranchParams(params);
  const branchId = parsed?.threadId ?? threadId;
  const { rpc, nodes } = useTree(branchId);
  const [showTree, setShowTree] = useState(false);
  const branch = nodes?.find((node) => node.id === branchId) ?? null;
  const parent = branch?.parentId ? nodes?.find((node) => node.id === branch.parentId) ?? null : null;

  const messageActions = useMemo(
    () => [
      {
        id: "branch-again",
        title: "Branch from here",
        icon: BRANCH_ICON,
        run: (message: { text: string; sourceSeqEnd: number }) =>
          startBranch(rpc, navigate.openThreadPanel, {
            sourceThreadId: branchId,
            sourceSeqEnd: message.sourceSeqEnd,
            anchorText: message.text,
          }),
      },
      {
        id: "merge-reply",
        title: branch?.parentId ? "Merge this reply into parent" : "Merge this reply",
        icon: "GitMerge",
        roles: ["assistant" as const],
        run: (message: { text: string }) => {
          if (!branch?.parentId) return;
          rpc
            .call("merge", { fromThreadId: branchId, toThreadId: branch.parentId, mode: "message", text: message.text })
            .catch((cause: unknown) => toast.error(`Merge failed: ${errorMessage(cause)}`));
        },
      },
    ],
    [rpc, navigate, branchId, branch?.parentId],
  );

  if (parsed === null) {
    return <div className="p-3 text-sm text-muted-foreground">This branch tab is missing its thread reference.</div>;
  }

  return (
    <div className="flex h-full min-h-0 flex-col">
      <div className="flex items-center gap-1.5 border-b border-border px-2 py-1.5 text-xs">
        <Icon name="Fork" fallback="SideChat" className="size-3.5 text-muted-foreground" />
        <span className="min-w-0 flex-1 truncate text-muted-foreground">
          {parent ? (
            <>
              branch of{" "}
              <button
                type="button"
                className="cursor-pointer font-medium text-foreground hover:underline"
                onClick={() => {
                  if (parent.isBranch) openBranch(navigate.openThreadPanel, parent);
                  else if (parent.id !== threadId) navigate.toThread(parent.id);
                }}
              >
                {parent.isBranch ? snippet(parent.title, 40) : "Main"}
              </button>
            </>
          ) : (
            "branch"
          )}
        </span>
        <Button
          variant="ghost"
          size="sm"
          className="h-7 px-2"
          aria-pressed={showTree}
          onClick={() => setShowTree((value) => !value)}
        >
          <Icon name="GitBranch" className="size-3.5" />
          Tree
        </Button>
      </div>
      {showTree && (
        <div className="max-h-[40%] overflow-auto border-b border-border p-1.5">
          <TreeView
            threadId={branchId}
            activeId={branchId}
            onOpen={(node) => {
              if (node.isBranch) openBranch(navigate.openThreadPanel, node);
              else if (node.id !== threadId) navigate.toThread(node.id);
              setShowTree(false);
            }}
          />
        </div>
      )}
      {branch !== null && nodes !== null && <MergeBar branch={branch} nodes={nodes} rpc={rpc} />}
      <ThreadChat
        threadId={branchId}
        variant="compact"
        layout="contained"
        permissionPolicy="editable"
        className="min-h-0 flex-1"
        leadingContent={<AnchorQuote text={branch?.anchorText ?? ""} />}
        messageActions={messageActions}
      />
    </div>
  );
}

function HeaderButton({ threadId }: { threadId: string; projectId: string; isCompactViewport: boolean }): ReactNode {
  const navigate = useBbNavigate();
  const { nodes } = useTree(threadId);
  const count = Math.max(0, (nodes?.length ?? 1) - 1);
  return (
    <Button
      variant="ghost"
      size="sm"
      className="h-7 gap-1 px-2 text-muted-foreground"
      aria-label={`Branches (${count})`}
      onClick={() => navigate.openThreadPanel({ actionId: TREE_PANEL, title: "Branches" })}
    >
      <Icon name={BRANCH_ICON} fallback="SideChat" className="size-4" />
      {count > 0 && <span className="text-xs tabular-nums">{count}</span>}
    </Button>
  );
}

const directRpc = {
  async call(method: string, input: unknown): Promise<unknown> {
    const response = await fetch(`/api/v1/plugins/branches/rpc/${encodeURIComponent(method)}`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(input ?? null),
    });
    const body = (await response.json().catch(() => null)) as
      | { ok?: boolean; result?: unknown; error?: { message?: unknown } }
      | null;
    if (!response.ok || body?.ok !== true) {
      const message = typeof body?.error?.message === "string" ? body.error.message : null;
      throw new Error(message ?? `rpc "${method}" failed (HTTP ${response.status})`);
    }
    return body.result;
  },
} as unknown as Rpc;

export default definePluginApp((app) => {

  app.slots.messageAction({
    id: "branch-from-here",
    title: "Branch from here",
    icon: BRANCH_ICON,
    async run(context) {
      await startBranch(directRpc, (options) => context.openPanel(options), {
        sourceThreadId: context.threadId,
        sourceSeqEnd: context.message.sourceSeqEnd,
        anchorText: context.selectedText ?? context.message.text,
      });
    },
  });

  app.slots.threadPanelAction({
    id: TREE_PANEL,
    title: "Branches",
    icon: BRANCH_ICON,
    component: TreePanel,
    run: ({ openPanel }) => {
      openPanel({ title: "Branches" });
    },
  });

  app.slots.threadPanelAction({
    id: BRANCH_PANEL,
    title: "New branch",
    icon: BRANCH_ICON,
    component: BranchPanel,
    layout: "flush",
    async run({ threadId, openPanel }) {
      await startBranch(directRpc, (options) => openPanel({ title: options.title, params: options.params }), {
        sourceThreadId: threadId,
        anchorText: "",
      });
    },
  });

  app.slots.experimental_threadHeaderAction({
    id: "branches",
    title: "Branches",
    component: HeaderButton,
  });
});
