command: -> nowPlaying()

refreshFrequency: 1000

render: -> """
  <div class="np">
    <div class="disc"><div class="hole"></div></div>
    <div class="title"></div>
    <div class="artist"></div>
    <div class="bar"><i></i></div>
  </div>
"""

update: (np, el) ->
  root = el.querySelector('.np')
  playing = np.state == 'playing'
  hasTrack = np.state != 'stopped' and np.name?
  root.classList.toggle('playing', playing)
  root.classList.toggle('hidden', not playing)

  disc = el.querySelector('.disc')
  art = if hasTrack and np.artwork then np.artwork else ''
  if disc.dataset.art != art
    disc.dataset.art = art
    disc.style.backgroundImage = if art then "url(\"#{art}\")" else ''

  position = (np.position ? 0) + (if playing and np.positionAt then Date.now() / 1000 - np.positionAt else 0)
  duration = np.duration ? 0
  el.querySelector('.title').textContent = if hasTrack then np.name else ''
  el.querySelector('.artist').textContent = if hasTrack then (np.artist ? '') else ''
  el.querySelector('.bar i').style.width = if hasTrack and duration then "#{Math.min(100, 100 * position / duration)}%" else '0%'

style: """
  top: 380px
  left: 40px
  color: #fff
  font-family: "Anonymous Pro", Menlo, monospace
  @keyframes np-spin { from { transform: rotate(0deg) } to { transform: rotate(360deg) } }
  .np { width: 240px; height: 240px; display: flex; flex-direction: column; align-items: center; transition: opacity .8s ease }
  .np.hidden { opacity: 0 }
  body.editing & .np.hidden { opacity: .3 }
  .disc { position: relative; width: 170px; height: 170px; border-radius: 50%; flex: none;
    background-color: #161616; background-size: cover; background-position: center;
    box-shadow: 0 8px 24px rgba(0,0,0,.45);
    animation: np-spin 12s linear infinite; animation-play-state: paused }
  .disc::before { content: ''; position: absolute; inset: 0; border-radius: 50%;
    background: repeating-radial-gradient(circle, rgba(0,0,0,.10) 0 1px, transparent 1px 3px) }
  .playing .disc { animation-play-state: running }
  .hole { position: absolute; left: 50%; top: 50%; width: 12px; height: 12px; margin: -6px 0 0 -6px; border-radius: 50%;
    background: rgba(0,0,0,.55); box-shadow: 0 0 0 1px rgba(255,255,255,.15) }
  .title { margin-top: 16px; max-width: 240px; font-size: 13px; font-weight: 700; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
    filter: drop-shadow(0 1px 3px rgba(0,0,0,.6)) }
  .artist { margin-top: 3px; max-width: 240px; font-size: 11px; opacity: .65; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; min-height: 13px;
    filter: drop-shadow(0 1px 3px rgba(0,0,0,.6)) }
  .bar { width: 120px; height: 1px; margin-top: 10px; background: rgba(255,255,255,.2) }
  .bar i { display: block; height: 100%; width: 0; background: rgba(255,255,255,.85) }
"""
