import { useMemo, useState } from "react";
import type { ReactElement } from "react";
import type { TreeNode } from "../server";
import { Button } from "@/components/ui/button";
import { Icon } from "@/components/ui/icon";
import { cn } from "@/lib/utils";

const ROW_HEIGHT = 34;
const LANE_WIDTH = 22;
const GRAPH_PADDING = 10;
const LANE_COLORS = ["#8b949e", "#2f81f7", "#a371f7", "#3fb950", "#d29922", "#f778ba", "#39c5cf", "#f85149"];

type GraphRow =
  | { kind: "tip"; time: number; node: TreeNode }
  | { kind: "merge"; time: number; from: TreeNode; into: TreeNode; mode: string }
  | { kind: "fork"; time: number; node: TreeNode; parent: TreeNode }
  | { kind: "start"; time: number; node: TreeNode };

const KIND_ORDER: Record<GraphRow["kind"], number> = { tip: 0, merge: 1, fork: 2, start: 3 };

interface Layout {
  rows: GraphRow[];
  lanes: Map<string, number>;
  colors: Map<string, string>;
  laneCount: number;
  spans: Map<string, { top: number; bottom: number }>;
}

function snippet(text: string, max: number): string {
  const flat = text.replace(/\s+/g, " ").trim();
  return flat.length > max ? `${flat.slice(0, max - 1)}…` : flat;
}

function relativeTime(time: number, now: number): string {
  const seconds = Math.max(0, Math.round((now - time) / 1000));
  if (seconds < 60) return "now";
  const minutes = Math.round(seconds / 60);
  if (minutes < 60) return `${minutes}m`;
  const hours = Math.round(minutes / 60);
  if (hours < 24) return `${hours}h`;
  return `${Math.round(hours / 24)}d`;
}

function branchLabel(node: TreeNode): string {
  return node.isBranch ? node.title.replace(/^⑂\s*/, "") : "main";
}

function buildLayout(nodes: TreeNode[]): Layout {
  const byId = new Map(nodes.map((node) => [node.id, node]));
  const tipTime = new Map<string, number>();
  for (const node of nodes) tipTime.set(node.id, Math.max(node.updatedAt, node.createdAt));
  for (const node of nodes) {
    for (const merge of node.merges) {
      tipTime.set(node.id, Math.max(tipTime.get(node.id) ?? 0, merge.at));
      if (byId.has(merge.intoThreadId)) {
        tipTime.set(merge.intoThreadId, Math.max(tipTime.get(merge.intoThreadId) ?? 0, merge.at));
      }
    }
  }

  for (const node of nodes) {
    if (node.parentId !== null && byId.has(node.parentId)) {
      tipTime.set(node.parentId, Math.max(tipTime.get(node.parentId) ?? 0, node.createdAt + 1));
    }
  }

  const rows: GraphRow[] = [];
  for (const node of nodes) {
    rows.push({ kind: "tip", time: tipTime.get(node.id) ?? node.updatedAt, node });
    const parent = node.parentId === null ? undefined : byId.get(node.parentId);
    if (parent === undefined) rows.push({ kind: "start", time: node.createdAt, node });
    else rows.push({ kind: "fork", time: node.createdAt, node, parent });
    for (const merge of node.merges) {
      const into = byId.get(merge.intoThreadId);
      if (into !== undefined) rows.push({ kind: "merge", time: merge.at, from: node, into, mode: merge.mode });
    }
  }
  rows.sort((a, b) => b.time - a.time || KIND_ORDER[a.kind] - KIND_ORDER[b.kind]);

  const lanes = new Map<string, number>();
  const colors = new Map<string, string>();
  const laneFreeAt: number[] = [];
  const ordered = [...nodes].sort((a, b) => {
    if (a.parentId === null) return -1;
    if (b.parentId === null) return 1;
    return a.createdAt - b.createdAt;
  });
  for (const node of ordered) {
    let lane = laneFreeAt.findIndex((freeAt, index) => index > 0 && freeAt < node.createdAt);
    if (node.parentId === null) lane = 0;
    if (lane === -1) lane = laneFreeAt.length;
    lanes.set(node.id, lane);
    colors.set(node.id, LANE_COLORS[colors.size % LANE_COLORS.length]!);
    laneFreeAt[lane] = tipTime.get(node.id) ?? node.updatedAt;
  }

  const spans = new Map<string, { top: number; bottom: number }>();
  rows.forEach((row, index) => {
    const id = row.kind === "merge" ? null : row.node.id;
    if (id === null) return;
    const span = spans.get(id) ?? { top: index, bottom: index };
    span.top = Math.min(span.top, index);
    span.bottom = Math.max(span.bottom, index);
    spans.set(id, span);
  });

  return { rows, lanes, colors, laneCount: Math.max(1, laneFreeAt.length), spans };
}

function laneX(lane: number): number {
  return GRAPH_PADDING + lane * LANE_WIDTH;
}

function rowY(index: number): number {
  return index * ROW_HEIGHT + ROW_HEIGHT / 2;
}


function curve(x1: number, y1: number, x2: number, y2: number): string {
  const mid = (y1 + y2) / 2;
  return `M ${x1} ${y1} C ${x1} ${mid}, ${x2} ${mid}, ${x2} ${y2}`;
}

function Graph({ layout, activeId, hovered }: { layout: Layout; activeId: string | null; hovered: number | null }) {
  const { rows, lanes, laneCount, spans } = layout;
  const colorOf = (id: string) => layout.colors.get(id) ?? LANE_COLORS[0]!;
  const width = laneX(laneCount - 1) + GRAPH_PADDING;
  const height = rows.length * ROW_HEIGHT;
  const paths: ReactElement[] = [];
  const dots: ReactElement[] = [];

  for (const [id, span] of spans) {
    const lane = lanes.get(id) ?? 0;
    const forkRow = rows[span.bottom];
    const bottomY = forkRow?.kind === "fork" ? rowY(span.bottom) - ROW_HEIGHT / 2 : rowY(span.bottom);
    paths.push(
      <line
        key={`lane-${id}`}
        x1={laneX(lane)}
        x2={laneX(lane)}
        y1={rowY(span.top)}
        y2={bottomY}
        stroke={colorOf(id)}
        strokeWidth={2}
        strokeLinecap="round"
      />,
    );
  }

  rows.forEach((row, index) => {
    const y = rowY(index);
    if (row.kind === "fork") {
      const parentLane = lanes.get(row.parent.id) ?? 0;
      const childLane = lanes.get(row.node.id) ?? 0;
      paths.push(
        <path
          key={`fork-${row.node.id}`}
          d={curve(laneX(parentLane), y, laneX(childLane), y - ROW_HEIGHT / 2)}
          stroke={colorOf(row.node.id)}
          strokeWidth={2}
          fill="none"
        />,
      );
      dots.push(
        <circle
          key={`forkdot-${row.node.id}`}
          cx={laneX(parentLane)}
          cy={y}
          r={3.5}
          fill="var(--background, #fff)"
          stroke={colorOf(row.parent.id)}
          strokeWidth={2}
        />,
      );
    } else if (row.kind === "merge") {
      const fromLane = lanes.get(row.from.id) ?? 0;
      const intoLane = lanes.get(row.into.id) ?? 0;
      const fromX = laneX(fromLane);
      const intoX = laneX(intoLane);
      const direction = fromX >= intoX ? 1 : -1;
      const endX = intoX + direction * 9;
      const startY = y + ROW_HEIGHT / 2;
      paths.push(
        <g key={`merge-${row.from.id}-${index}`}>
          <circle cx={fromX} cy={startY} r={2.5} fill={colorOf(row.from.id)} />
          <path
            d={`M ${fromX} ${startY} C ${fromX} ${y}, ${fromX} ${y}, ${endX} ${y}`}
            stroke={colorOf(row.from.id)}
            strokeWidth={2}
            strokeDasharray={row.mode === "summary" ? undefined : "3 3"}
            fill="none"
          />
          <path
            d={`M ${endX} ${y} l ${direction * 5} -4 l 0 8 z`}
            transform={`translate(${-direction * 2} 0)`}
            fill={colorOf(row.from.id)}
          />
        </g>,
      );
      dots.push(
        <g key={`mergedot-${row.from.id}-${index}`}>
          <circle cx={laneX(intoLane)} cy={y} r={6} fill={colorOf(row.into.id)} />
          <circle cx={laneX(intoLane)} cy={y} r={2.5} fill="var(--background, #fff)" />
        </g>,
      );
    } else {
      const lane = lanes.get(row.node.id) ?? 0;
      const isTip = row.kind === "tip";
      const isActive = isTip && row.node.id === activeId;
      dots.push(
        <g key={`${row.kind}-${row.node.id}`}>
          {isActive && <circle cx={laneX(lane)} cy={y} r={8} fill="none" stroke={colorOf(row.node.id)} strokeWidth={1.5} opacity={0.6} />}
          <circle
            cx={laneX(lane)}
            cy={y}
            r={isTip ? 5 : 3.5}
            fill={isTip ? colorOf(row.node.id) : "var(--background, #fff)"}
            stroke={colorOf(row.node.id)}
            strokeWidth={2}
          />
        </g>,
      );
    }
  });

  return (
    <svg width={width} height={height} className="pointer-events-none absolute left-0 top-0" aria-hidden>
      {hovered !== null && (
        <rect x={0} y={hovered * ROW_HEIGHT} width={width} height={ROW_HEIGHT} fill="currentColor" opacity={0.04} />
      )}
      {paths}
      {dots}
    </svg>
  );
}

function StatusBadge({ status }: { status: string }) {
  if (status === "active" || status === "starting") {
    return <span className="rounded bg-blue-500/15 px-1 text-[10px] font-medium text-blue-600 dark:text-blue-400">running</span>;
  }
  if (status === "error") {
    return <span className="rounded bg-red-500/15 px-1 text-[10px] font-medium text-red-600 dark:text-red-400">error</span>;
  }
  return null;
}

function RefChip({ node, color }: { node: TreeNode; color: string }) {
  return (
    <span
      className="inline-flex max-w-[14rem] shrink-0 items-center gap-1 truncate rounded-full border px-1.5 text-[11px] font-medium leading-4"
      style={{ borderColor: color, color }}
    >
      {node.isBranch && <span aria-hidden>⑂</span>}
      <span className="truncate">{snippet(branchLabel(node), 36)}</span>
    </span>
  );
}

export function BranchGraph({
  nodes,
  activeId,
  onOpen,
  onArchive,
}: {
  nodes: TreeNode[];
  activeId: string | null;
  onOpen: (node: TreeNode) => void;
  onArchive: (node: TreeNode) => void;
}) {
  const layout = useMemo(() => buildLayout(nodes), [nodes]);
  const [hovered, setHovered] = useState<number | null>(null);
  const now = Date.now();
  const graphWidth = laneX(layout.laneCount - 1) + GRAPH_PADDING;

  return (
    <div className="flex flex-col gap-2">
      <div className="relative" style={{ minHeight: layout.rows.length * ROW_HEIGHT }} onMouseLeave={() => setHovered(null)}>
        <Graph layout={layout} activeId={activeId} hovered={hovered} />
        {layout.rows.map((row, index) => {
          const color = (id: string) => layout.colors.get(id) ?? LANE_COLORS[0]!;
          return (
            <div
              key={`${row.kind}-${index}`}
              className="group flex items-center gap-1.5 pr-1 text-xs"
              style={{ height: ROW_HEIGHT, paddingLeft: graphWidth + 4 }}
              onMouseEnter={() => setHovered(index)}
            >
              <button
                type="button"
                className="flex min-w-0 flex-1 cursor-pointer items-center gap-1.5 border-0 bg-transparent p-0 text-left"
                title={row.kind === "fork" && row.node.anchorText ? row.node.anchorText : undefined}
                onClick={() => onOpen(row.kind === "merge" ? row.into : row.node)}
              >
                {row.kind === "tip" && (
                  <>
                    <RefChip node={row.node} color={color(row.node.id)} />
                    {row.node.id === activeId && (
                      <span className="shrink-0 rounded bg-foreground px-1 text-[10px] font-semibold text-background">HEAD</span>
                    )}
                    <StatusBadge status={row.node.status} />
                    {!row.node.isBranch && <span className="min-w-0 truncate text-muted-foreground">{row.node.title}</span>}
                  </>
                )}
                {row.kind === "fork" && (
                  <span className="min-w-0 truncate text-muted-foreground">
                    <span style={{ color: color(row.node.id) }}>⑂ {snippet(branchLabel(row.node), 28)}</span>
                    {" branched from "}
                    <span style={{ color: color(row.parent.id) }}>{snippet(branchLabel(row.parent), 20)}</span>
                    {row.node.anchorText ? ` at “${snippet(row.node.anchorText, 80)}”` : ""}
                  </span>
                )}
                {row.kind === "merge" && (
                  <span className="min-w-0 truncate text-muted-foreground">
                    <span className="font-medium text-foreground">Merge</span>{" "}
                    <span style={{ color: color(row.from.id) }}>⑂ {snippet(branchLabel(row.from), 28)}</span>
                    {" into "}
                    <span style={{ color: color(row.into.id) }}>{snippet(branchLabel(row.into), 28)}</span>
                    <span className="ml-1 opacity-70">({row.mode === "last" ? "last reply" : row.mode})</span>
                  </span>
                )}
                {row.kind === "start" && <span className="min-w-0 truncate text-muted-foreground">conversation started</span>}
              </button>
              <span className="shrink-0 tabular-nums text-[10px] text-muted-foreground">{relativeTime(row.time, now)}</span>
              {row.kind === "tip" && row.node.isBranch && (
                <Button
                  variant="ghost"
                  size="icon"
                  className="size-6 shrink-0 text-muted-foreground opacity-0 group-hover:opacity-100"
                  aria-label={`Archive ${row.node.title}`}
                  onClick={() => onArchive(row.node)}
                >
                  <Icon name="Archive" className="size-3.5" />
                </Button>
              )}
            </div>
          );
        })}
      </div>
      <div className="flex flex-wrap items-center gap-3 px-1 text-[10px] text-muted-foreground">
        <span className="inline-flex items-center gap-1">
          <svg width="10" height="10" aria-hidden><circle cx="5" cy="5" r="4" fill="currentColor" /></svg>tip
        </span>
        <span className="inline-flex items-center gap-1">
          <svg width="10" height="10" aria-hidden><circle cx="5" cy="5" r="3.5" fill="none" stroke="currentColor" strokeWidth="1.5" /></svg>fork point
        </span>
        <span className="inline-flex items-center gap-1">
          <svg width="12" height="12" aria-hidden><circle cx="6" cy="6" r="5.5" fill="currentColor" /><circle cx="6" cy="6" r="2" fill="var(--background, #fff)" /></svg>merge
        </span>
        <span className="inline-flex items-center gap-1">
          <svg width="18" height="6" aria-hidden><line x1="0" y1="3" x2="18" y2="3" stroke="currentColor" strokeWidth="1.5" strokeDasharray="3 3" /></svg>reply merge
        </span>
      </div>
    </div>
  );
}
