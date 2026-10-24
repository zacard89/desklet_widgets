refreshFrequency: 1000

options:
  name:
    label: 'Imię'
    type: 'text'
    default: 'zacard'
    placeholder: 'Jak masz na imię?'
    help: 'Pokazywane w powitaniu.'

render: -> ''

update: (_, el) ->
  now = new Date()
  hour = now.getHours()
  greet = if hour < 12 then 'Dzień dobry' else if hour < 18 then 'Cześć' else 'Dobry wieczór'
  el.innerHTML = """
    <div class="greet">#{greet}, #{esc @name}</div>
    <div class="time">#{now.toLocaleTimeString('pl-PL')}</div>
  """

style: """
  top: 40px
  left: 640px
  color: #fff
  font-family: "Anonymous Pro", Menlo, monospace
  filter: drop-shadow(0 1px 4px rgba(0,0,0,.6))
  .greet { font-size: 14px; opacity: .85 }
  .time { font-size: 34px; font-weight: 700; margin-top: 4px }
"""
