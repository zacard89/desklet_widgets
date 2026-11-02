refreshFrequency: false

command: false

options:
  bars:
    label: 'Słupki'
    choices: { '16': 16, '24': 24, '32': 32 }
    default: 32
  color:
    label: 'Kolory'
    choices: { 'Fiolet': 'violet', 'Zieleń': 'green', 'Ogień': 'fire', 'Biały': 'white' }
    default: 'violet'

palettes:
  violet: ['#8b74ff', '#ff6fb1']
  green: ['#2fbf71', '#d4ff6b']
  fire: ['#ff5f2e', '#ffd36b']
  white: ['#d9d9e3', '#ffffff']

render: -> """
  <div class="eq silent">
    <canvas width="640" height="240"></canvas>
    <div class="msg"></div>
  </div>
"""

afterRender: (el) ->
  canvas = el.querySelector('canvas')
  ctx = canvas.getContext('2d')
  root = el.querySelector('.eq')
  msg = el.querySelector('.msg')
  count = Number(@bars) or 32
  [bottom, top] = @palettes[@color] ? @palettes.violet
  levels = new Array(count).fill(0)
  peaks = new Array(count).fill(0)
  W = canvas.width
  H = canvas.height
  gap = 4
  busy = false
  lastPoll = 0
  silentSince = 0

  # Native bands (32) are merged into the chosen number of bars by taking the loudest band of each group.
  resample = (bands) ->
    for i in [0...count]
      from = Math.floor(i * bands.length / count)
      to = Math.max(from + 1, Math.floor((i + 1) * bands.length / count))
      Math.max(bands[from...to]...)

  poll = ->
    busy = true
    try
      s = await spectrum()
      if s.status is 'denied'
        msg.textContent = 'Zezwól Desklet na nagrywanie dźwięku: Ustawienia systemowe → Prywatność i ochrona → Nagrywanie ekranu i dźwięku systemowego'
        root.classList.add('denied')
      else
        root.classList.remove('denied')
        levels = resample(s.bands)
    catch e
      dlog("spectrum: #{e.message ? e}")
    busy = false

  draw = ->
    ctx.clearRect(0, 0, W, H)
    barWidth = (W - gap * (count - 1)) / count
    gradient = ctx.createLinearGradient(0, H, 0, 0)
    gradient.addColorStop(0, bottom)
    gradient.addColorStop(1, top)
    for i in [0...count]
      x = i * (barWidth + gap)
      h = Math.max(3, levels[i] * (H - 8))
      ctx.fillStyle = gradient
      ctx.beginPath()
      ctx.roundRect(x, H - h, barWidth, h, 3)
      ctx.fill()
      ctx.fillStyle = 'rgba(255,255,255,.85)'
      ctx.fillRect(x, H - peaks[i] * (H - 8) - 6, barWidth, 3)
    return

  frame = (now) ->
    if not busy and now - lastPoll > 33
      lastPoll = now
      poll()
    for i in [0...count]
      peaks[i] = if levels[i] >= peaks[i] then levels[i] else Math.max(0, peaks[i] - 0.01)
    silentSince = now if levels.some((l) -> l > 0.05)
    root.classList.toggle('silent', now - silentSince > 2000)
    draw()
    requestAnimationFrame(frame)
  requestAnimationFrame(frame)

style: """
  top: 520px
  left: 40px
  .eq { width: 320px; transition: opacity .8s ease }
  .eq.silent:not(.denied) { opacity: 0 }
  body.editing & .eq.silent { opacity: .3 }
  canvas { display: block; width: 320px; height: 120px; filter: drop-shadow(0 2px 6px rgba(0,0,0,.45)) }
  .msg { display: none; color: #ffb4b4; font-family: "Anonymous Pro", Menlo, monospace; font-size: 11px; margin-top: 6px }
  .denied .msg { display: block }
"""
