# Arcana/persona minimap icons (Dota 2 wiki, "Custom hero minimap icons"), saved as assets/<hero_id>.png; Invoker = Kid (persona).
variantHeroes: [1, 5, 7, 8, 11, 14, 21, 22, 25, 39, 42, 44, 49, 67, 74, 84, 86, 91, 104, 105, 109, 114]

refreshFrequency: 10 * 60 * 1000

handleError: true

options:
  accountId:
    label: 'Konto Dota'
    type: 'text'
    default: ''
    placeholder: 'np. 102487692'
    help: 'ID konta OpenDota, SteamID64 albo link do profilu Steam / OpenDota.'
  refreshFrequency:
    label: 'Odświeżanie'
    choices: { '5 min': 300000, '10 min': 600000, '30 min': 1800000 }
    default: 600000

# Accepts an OpenDota/Steam32 id, a SteamID64 (BigInt: it does not fit a JS number) or a Steam/OpenDota profile URL.
accountFrom: (raw) ->
  digits = String(raw ? '').match(/\d{3,20}/g)
  throw new Error("Ustaw konto: ✨ → Widgety… → dota → Konfiguruj") unless digits
  id = BigInt(digits[digits.length - 1])
  steam64Base = BigInt('76561197960265728')
  id -= steam64Base if id >= steam64Base
  id.toString()

command: ->
  account = @accountFrom(@accountId)
  api = (path) ->
    res = await fetch("https://api.opendota.com/api/#{path}")
    throw new Error("OpenDota HTTP #{res.status}") unless res.ok
    res.json()
  @heroes ?= await api('constants/heroes')
  [player, total, week, matches] = await Promise.all([
    api("players/#{account}")
    api("players/#{account}/wl")
    api("players/#{account}/wl?date=7")
    api("players/#{account}/recentMatches")
  ])
  @last = { player, total, week, matches }

render: (data, error) ->
  data = if error then @last else data
  return "<div class='title'>Dota 2</div><div class='err'>#{esc error}</div>" unless data
  { player, total, week, matches } = data
  heroes = @heroes

  won = (m) -> (m.player_slot < 128) == m.radiant_win
  pct = (w, n) -> if n then "#{Math.round(100 * w / n)}%" else '—'
  games = (n) -> "#{n} #{if n == 1 then 'gra' else if 2 <= n % 10 <= 4 and not (12 <= n % 100 <= 14) then 'gry' else 'gier'}"
  hero = (id) -> heroes[id] ? {}
  variantHeroes = @variantHeroes
  portrait = (id, cls = '') ->
    path = esc(hero(id).icon ? '')
    src = if Number(id) in variantHeroes then asset("assets/#{id}.png") else "https://cdn.steamstatic.com#{path}"
    "<img class='portrait #{cls}' src='#{src}' data-path='#{path}' alt=''>"
  ago = (ts) ->
    m = Math.round((Date.now() / 1000 - ts) / 60)
    return "#{m} min temu" if m < 60
    h = Math.round(m / 60)
    return "#{h} h temu" if h < 24
    "#{Math.round(h / 24)} d temu"

  strip = matches.slice(0, 8).map((m) ->
    "<div class='slot'>#{portrait(m.hero_id)}<b class='#{if won(m) then 'w' else 'l'}'></b></div>"
  ).join('')

  last = matches[0]
  lastLine = if last
    "#{esc hero(last.hero_id).localized_name ? '?'} · #{last.kills}/#{last.deaths}/#{last.assists} · #{Math.floor(last.duration / 60)} min · #{ago(last.start_time + last.duration)}"
  else 'brak meczów'

  midnight = new Date().setHours(0, 0, 0, 0) / 1000
  today = matches.filter((m) -> m.start_time >= midnight)
  todayWins = today.filter(won).length

  recentWins = matches.filter(won).length
  streak = 0
  streak += 1 while streak < matches.length and won(matches[streak]) == won(matches[0])
  streakHtml = if matches.length
    kind = if won(matches[0]) then 'W' else 'L'
    "seria <b class='#{kind.toLowerCase()}'>#{kind}#{streak}</b>"
  else ''

  counts = {}
  for m in matches
    counts[m.hero_id] ?= { n: 0, w: 0 }
    counts[m.hero_id].n += 1
    counts[m.hero_id].w += 1 if won(m)
  [favId, fav] = Object.entries(counts).sort((a, b) -> b[1].n - a[1].n)[0] ? [null, null]
  favHtml = if fav
    "#{portrait(favId, 'small')} #{esc hero(favId).localized_name ? '?'} · #{games(fav.n)} · #{pct(fav.w, fav.n)}"
  else '—'

  rows = [
    ['Dziś', "#{games(today.length)} · #{pct(todayWins, today.length)}"]
    ['7 dni', "#{games(week.win + week.lose)} · #{pct(week.win, week.win + week.lose)}"]
    ["Ostatnie #{matches.length}", "#{pct(recentWins, matches.length)} · #{streakHtml}"]
    ['Najczęściej', favHtml]
    ['Łącznie', "#{total.win} W · #{total.lose} L"]
  ].map(([label, value]) -> "<div class='row'><span>#{label}</span><div>#{value}</div></div>").join('')

  stale = if error then "<div class='stale'>#{esc error}</div>" else ''
  """
  <div class="title">Dota 2 <span>#{esc player.profile?.personaname ? ''}</span></div>
  <div class="strip">#{strip}</div>
  <div class="last">#{lastLine}</div>
  #{rows}
  #{stale}
  """

afterRender: (el) ->
  fallbackHosts = ['cdn.cloudflare.steamstatic.com', 'cdn.akamai.steamstatic.com']
  for img in el.querySelectorAll('img.portrait')
    img.addEventListener 'error', ->
      attempt = Number(@dataset.attempt ? 0)
      if attempt < fallbackHosts.length
        @dataset.attempt = attempt + 1
        @src = "https://#{fallbackHosts[attempt]}#{@dataset.path}"
      else
        @classList.add('missing')

style: """
  top: 640px
  left: 40px
  width: 330px
  color: #fff
  font-family: "Anonymous Pro", Menlo, monospace
  font-size: 13px
  filter: drop-shadow(0 1px 4px rgba(0,0,0,.6))
  .title { font-size: 16px; font-weight: 700; margin-bottom: 10px }
  .title span { font-size: 12px; font-weight: 400; opacity: .6; margin-left: 6px }
  .strip { display: flex; gap: 5px; margin-bottom: 8px }
  .slot { flex: 1; display: flex; flex-direction: column; gap: 4px }
  .portrait { display: block; width: 32px; height: 32px; margin: 0 auto }
  .portrait.missing { visibility: hidden }
  .portrait.small { display: inline-block; width: 16px; height: 16px; margin: 0 2px 0 0; vertical-align: -3px }
  .slot b { height: 3px; border-radius: 1px }
  .slot b.w { background: #8fd18f }
  .slot b.l { background: #e8837a }
  .last { padding: 4px 0 6px; border-bottom: 1px dotted rgba(255,255,255,.35); white-space: nowrap; overflow: hidden; text-overflow: ellipsis }
  .row { display: grid; grid-template-columns: 110px 1fr; padding: 5px 0; border-bottom: 1px dotted rgba(255,255,255,.35) }
  .row span { opacity: .85 }
  b.w { color: #8fd18f }
  b.l { color: #e8837a }
  .stale { font-size: 10px; color: #ffc35a; margin-top: 6px }
  .err { color: #ffb4b4; white-space: pre-wrap }
"""
