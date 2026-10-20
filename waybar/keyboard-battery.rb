#!/usr/bin/env ruby

require 'json'
require 'fileutils'

# State and analysis data, all plain JSON next to each other:
#   keyboard-battery.json            rolling summary (the waybar tooltip state)
#   keyboard-battery.jsonl           raw samples, one row per change, pruned to 90 days
#   keyboard-battery-rollups.jsonl   hourly aggregates, kept forever

DEVICE = '/sys/class/power_supply/hid-2FFECADD364616C2-battery'
SIDES = { 'L' => '5', 'R' => '6' }
STATE_DIR = ENV['XDG_STATE_HOME'] || File.join(Dir.home, '.local', 'state')
STATE = File.join(STATE_DIR, 'keyboard-battery.json')
HISTORY = File.join(STATE_DIR, 'keyboard-battery.jsonl')
ROLLUPS = File.join(STATE_DIR, 'keyboard-battery-rollups.jsonl')
LOCK = File.join(STATE_DIR, 'keyboard-battery.lock')

GAP_SECS = 300 # waybar polls every 30s, so a longer silence means off or suspended
CHARGE_JUMP = 3
MIN_DROP_FOR_RATE = 3
# After a half wakes or the host resumes, the dongle can report a stale level for several minutes.
SETTLE_SECS = 900
# A half reports 100 for an instant when it boots, so any jump to 100 is retaken until it moves.
BOOT_WAIT_SECS = 3

# History logging: one row per battery change (plus a rare heartbeat), so the 30s
# poll usually writes nothing at all and the raw log stays tiny. A half flapping
# asleep/awake can write a row per poll at worst, which the size cap below bounds.
HEARTBEAT_SECS = 1800 # a "still flat" row at least every 30 min, so spans stay bounded
RAW_DAYS = 90         # raw rows older than this become rollup rows, then get dropped
PRUNE_EVERY_SECS = 86_400
HARD_MAX_BYTES = 8 * 1024 * 1024 # safety valve: if the raw log bloats, drop its oldest half

def now
  Time.now.to_f
end

def read_level(suffix)
  Integer(File.read("#{DEVICE}-#{suffix}/capacity").strip)
rescue SystemCallError, ArgumentError
  nil
end

def read_levels(state)
  prev = state['raw'] || {}
  levels = SIDES.to_h { |name, suffix| [name, read_level(suffix)] }
  booting = levels.keys.select { |name| levels[name] == 100 && prev[name] != 100 }
  deadline = now + BOOT_WAIT_SECS
  until booting.empty? || now >= deadline
    sleep 0.25
    booting.reject! { |name| (levels[name] = read_level(SIDES[name])) != 100 }
  end
  state['raw'] = levels
  levels
end

def load_state
  JSON.parse(File.read(STATE))
rescue StandardError
  { 'last_run' => nil, 'sides' => {} }
end

def save_state(state)
  FileUtils.mkdir_p(File.dirname(STATE))
  tmp = STATE.sub(/\.json\z/, '.tmp')
  File.write(tmp, JSON.generate(state))
  File.rename(tmp, STATE)
end

def new_side
  {
    'prev' => nil,
    'prev_ts' => nil,
    'awake_since' => nil,
    'last_awake' => nil,
    'pending_closed' => nil,
    'closed' => nil,
    'drop' => 0,
    'secs' => 0,
    'low' => nil
  }
end

def reset_rate(s, level)
  s['drop'] = 0
  s['secs'] = 0
  s['low'] = level
end

# The dongle reports 0 while a half is disconnected (deep sleep), so 0 never counts
# as a reading. Returns the events worth logging for this side this run.
def update_side(s, level, time, gap, gap_hours)
  ev = {}
  if gap
    if s['pending_closed']
      s['pending_closed']['hours'] += gap_hours
    elsif s['last_awake']
      s['pending_closed'] = { 'before' => s['last_awake'], 'hours' => gap_hours }
    end
    s['prev'] = nil
    s['awake_since'] = nil
  end
  if level.nil? || level.zero?
    s['prev'] = nil
    s['awake_since'] = nil
    return ev
  end
  s['awake_since'] ||= time
  return ev if time - s['awake_since'] < SETTLE_SECS

  pending = s['pending_closed']
  if pending
    loss = pending['before'] - level
    s['closed'] = { 'loss' => loss, 'hours' => pending['hours'] }
    s['pending_closed'] = nil
    ev['closed'] = loss
    ev['closed_h'] = pending['hours'].round(2)
    if -loss >= CHARGE_JUMP
      reset_rate(s, level)
      ev['charge'] = true
    end
  end
  if s['low'].nil?
    reset_rate(s, level)
  elsif level - s['low'] >= CHARGE_JUMP
    reset_rate(s, level)
    ev['charge'] = true
  elsif s['prev']
    s['drop'] += s['prev'] - level
    s['secs'] += time - s['prev_ts']
  end
  s['low'] = [s['low'], level].compact.min
  s['prev'] = level
  s['prev_ts'] = time
  s['last_awake'] = level
  ev
end

def closed_text(s)
  return '…' if s['pending_closed']
  c = s['closed']
  return 'n/a' if c.nil?
  return 'charged' if -c['loss'] >= CHARGE_JUMP

  format('%+d%%', -c['loss'])
end

def rate_text(s)
  if s['drop'] < MIN_DROP_FOR_RATE
    format('… (%.1fh, %d%%)', s['secs'] / 3600.0, s['drop'])
  else
    format('%.2f%%/h (%.0fh)', s['drop'] / (s['secs'] / 3600.0), s['secs'] / 3600.0)
  end
end

# Raw row schema (flat, one JSON object per line):
#   t            unix seconds of the reading
#   L, R         battery level, 0/null when that half is asleep or missing
#   gap_h        hours the machine was off/suspended before this row (omitted when 0)
#   L_closed     % lost while closed/off since the level before the gap (negative: gained)
#   L_closed_h   how long that closed period lasted
#   L_charge     true when this row caught a charge (omitted otherwise)
# Same for R_*. Absent keys simply mean no event; pandas/duckdb give NaN there.
def log_history(state, levels, time, gap_hours, events)
  return if levels.values.none? { |lvl| lvl&.positive? }

  h = state['hist'] ||= {}
  last_t = h['t'] || 0
  # A 0/null edge on one half counts as a change: it marks that half falling asleep or waking up.
  changed = SIDES.keys.any? { |name| h[name] != levels[name] }
  forced = gap_hours > 0 || events.values.any? { |ev| !ev.empty? }
  return unless changed || forced || time - last_t >= HEARTBEAT_SECS

  line = { 't' => time.to_i, 'L' => levels['L'], 'R' => levels['R'] }
  line['gap_h'] = gap_hours.round(2) if gap_hours > 0
  SIDES.each_key do |name|
    ev = events[name] || {}
    if ev.key?('closed')
      line["#{name}_closed"] = ev['closed']
      line["#{name}_closed_h"] = ev['closed_h']
    end
    line["#{name}_charge"] = true if ev['charge']
  end
  FileUtils.mkdir_p(File.dirname(HISTORY))
  File.open(HISTORY, 'a') { |f| f.puts JSON.generate(line) }
  h['t'] = time.to_i
  h['L'] = levels['L']
  h['R'] = levels['R']
end

# Rollup schema, one row per hour per side (kept forever):
#   t, side, first, last, min, max, loss (first - last), n (rows in the hour),
#   gap_h (off/suspended hours seen in the hour), cl_loss/cl_h (closed-lid loss/hours),
#   charge (a charge happened this hour, so first/last are not a plain drain)
def rollup_lines(rows)
  buckets = {}
  rows.each do |ln|
    hour = ln['t'] - (ln['t'] % 3600)
    gap_h = ln['gap_h'] || 0.0
    SIDES.each_key do |name|
      lvl = ln[name]
      next if lvl.nil? || lvl.zero? # the half is asleep: it carries no level information

      b = (buckets[[hour, name]] ||= {
        'first' => lvl, 'last' => lvl, 'min' => lvl, 'max' => lvl,
        'n' => 0, 'gap_h' => 0.0, 'cl_loss' => 0, 'cl_h' => 0.0, 'charge' => false
      })
      b['last'] = lvl
      b['min'] = [b['min'], lvl].min
      b['max'] = [b['max'], lvl].max
      b['n'] += 1
      b['gap_h'] += gap_h
      if ln.key?("#{name}_closed")
        b['cl_loss'] += ln["#{name}_closed"]
        b['cl_h'] += ln["#{name}_closed_h"] || 0.0
      end
      b['charge'] = true if ln["#{name}_charge"]
    end
  end
  buckets.sort_by { |(hour, name), _b| [hour, name] }.map do |(hour, name), b|
    {
      't' => hour, 'side' => name, 'first' => b['first'], 'last' => b['last'],
      'min' => b['min'], 'max' => b['max'], 'loss' => b['first'] - b['last'],
      'n' => b['n'], 'gap_h' => b['gap_h'].round(2),
      'cl_loss' => b['cl_loss'], 'cl_h' => b['cl_h'].round(2), 'charge' => b['charge']
    }
  end
end

# Runs at most once a day: raw rows older than RAW_DAYS become rollup rows and are
# dropped from HISTORY. Only ever reads and rewrites the small raw log.
def maintain_history(state, time)
  return if time - (state['last_prune'] || 0) < PRUNE_EVERY_SECS

  state['last_prune'] = time
  parsed = []
  begin
    File.foreach(HISTORY) do |line|
      begin
        parsed << JSON.parse(line)
      rescue JSON::ParserError
        next
      end
    end
  rescue SystemCallError
    return
  end
  cutoff = time - (RAW_DAYS * 86_400)
  keep = parsed.select { |d| (d['t'] || time) >= cutoff }
  already = state['compacted_upto'] || 0
  todo = parsed.select { |d| (d['t'] || time) < cutoff && (d['t'] || 0) > already }
  unless todo.empty?
    FileUtils.mkdir_p(File.dirname(ROLLUPS))
    File.open(ROLLUPS, 'a') do |f|
      rollup_lines(todo).each { |row| f.puts JSON.generate(row) }
    end
    state['compacted_upto'] = cutoff
    # Persist before rewriting HISTORY: a crash in between may duplicate a few
    # rollup rows but can never lose them (analysis can group by hour).
    save_state(state)
  end
  body = keep.map { |d| JSON.generate(d) }.join("\n")
  body += "\n" unless body.empty?
  if body.bytesize > HARD_MAX_BYTES
    keep = keep[(keep.length / 2)..] || []
    body = keep.map { |d| JSON.generate(d) }.join("\n")
    body += "\n" unless body.empty?
  end
  return if keep.length == parsed.length

  tmp = "#{HISTORY}.tmp"
  File.write(tmp, body)
  File.rename(tmp, HISTORY)
end

def run
  state = load_state
  levels = read_levels(state)
  time = now
  last_run = state['last_run']
  gap = !last_run.nil? && time - last_run > GAP_SECS
  gap_hours = gap ? (time - last_run) / 3600.0 : 0
  state['last_run'] = time

  if levels.values.any?(&:nil?)
    state['sides'].each_value do |s|
      s['prev'] = nil
      s['awake_since'] = nil
    end
    log_history(state, levels, time, gap_hours, {})
    maintain_history(state, time)
    save_state(state)
    return
  end

  sides = state['sides']
  events = {}
  levels.each do |name, level|
    sides[name] ||= new_side
    events[name] = update_side(sides[name], level, time, gap, gap_hours)
  end
  log_history(state, levels, time, gap_hours, events)
  maintain_history(state, time)
  save_state(state)

  l = levels['L']
  r = levels['R']
  hours = SIDES.keys.map { |name| (sides[name]['closed'] || sides[name]['pending_closed'] || {})['hours'] || 0 }.max
  closed = format('Closed (%.1fh): L %s, R %s', hours, closed_text(sides['L']), closed_text(sides['R']))
  drain = "Awake drain: L #{rate_text(sides['L'])}, R #{rate_text(sides['R'])}"
  tooltip = ["Left: #{l}%", "Right: #{r}%", closed, drain].join("\n")
  # The quickshell bar renders left/right as bars and uses closed/drain as detail text.
  puts JSON.generate({
    'text' => "#{[l, r].min}%",
    'tooltip' => tooltip,
    'left' => l,
    'right' => r,
    'closed' => closed,
    'drain' => drain
  })
end

def locked
  FileUtils.mkdir_p(STATE_DIR)
  File.open(LOCK, File::RDWR | File::CREAT) do |f|
    f.flock(File::LOCK_EX)
    yield
  end
end

locked { run } if $PROGRAM_NAME == __FILE__
