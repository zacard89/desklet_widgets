refreshFrequency: 60 * 1000

handleError: true

publicEvery: 5 * 60 * 1000

options:
  refreshFrequency:
    label: 'Odświeżanie'
    choices: { '30 s': 30000, '1 min': 60000, '5 min': 300000 }
    default: 60000

command: ->
  out = await run("/sbin/ifconfig; echo '@@PORTS'; /usr/sbin/networksetup -listallhardwareports 2>/dev/null; " +
    "echo '@@ROUTE'; /sbin/route -n get default 2>/dev/null | awk '/interface:/{print $2}'; " +
    "echo '@@VPN'; /usr/sbin/scutil --nc list 2>/dev/null")
  [ifconfig, rest = ''] = out.split('@@PORTS')
  [ports, rest = ''] = rest.split('@@ROUTE')
  [route, vpn = ''] = rest.split('@@VPN')
  @vpnName = @connectedVpn(vpn)
  if not @publicIp? or Date.now() - @publicAt > @publicEvery
    @publicAt = Date.now()
    @publicIp = await @fetchPublicIp()
  { interfaces: @parse(ifconfig, ports), defaultIf: route.trim(), publicIp: @publicIp }

# Name of the VPN service macOS reports as connected, only when exactly one is (utunN cannot be mapped to a service).
connectedVpn: (list) ->
  names = (m[1] for m in Array.from(list.matchAll(/\(Connected\).*?"([^"]+)"/g)))
  if names.length is 1 then names[0] else null

fetchPublicIp: ->
  get = (url) ->
    res = await fetch(url)
    throw new Error("HTTP #{res.status}") unless res.ok
    (await res.json()).ip
  [v4, any] = await Promise.allSettled([get('https://api.ipify.org?format=json'), get('https://api64.ipify.org?format=json')])
  v6 = if any.status is 'fulfilled' and any.value.includes(':') then any.value else null
  return { v4: v4.value, v6 } if v4.status is 'fulfilled'
  return { v4: null, v6 } if v6
  { error: String(v4.reason?.message ? v4.reason) }

# ifconfig prints one block per interface (header line, then indented details); only interfaces that are up, not
# marked inactive and have a non link-local address are shown.
parse: (ifconfig, ports) ->
  names = {}
  for block in ports.split(/\n\s*\n/)
    port = block.match(/Hardware Port: (.+)/)?[1]
    device = block.match(/Device: (\S+)/)?[1]
    names[device] = port if port and device
  prefixBits = (hex) -> parseInt(hex, 16).toString(2).replace(/0/g, '').length
  vpnName = @vpnName
  label = (name) ->
    return names[name] if names[name]
    return (if vpnName then "VPN · #{vpnName}" else 'VPN') if name.startsWith('utun') or name.startsWith('ipsec') or name.startsWith('ppp')
    return 'Mostek (maszyny wirtualne)' if name.startsWith('bridge')
    name
  list = []
  for block in ifconfig.split(/\n(?=\S)/)
    name = block.match(/^([\w.]+):/)?[1]
    flags = (block.match(/flags=\w+<([^>]*)>/)?[1] ? '').split(',')
    continue unless name and name isnt 'lo0' and 'UP' in flags and 'RUNNING' in flags
    continue if /status: inactive/.test(block)
    v4 = ("#{m[1]}/#{prefixBits(m[2])}" for m in Array.from(block.matchAll(/\binet (\d+\.\d+\.\d+\.\d+)(?: --> \S+)? netmask (0x[0-9a-f]+)/g)))
    v6 = (m[1] for m in Array.from(block.matchAll(/\binet6 ([0-9a-f:]+)(?:%\S+)? prefixlen \d+/g)) when not m[1].startsWith('fe80') and m[1] isnt '::1')
    continue unless v4.length or v6.length
    list.push { name, label: label(name), v4, v6 }
  list

render: (data, error) ->
  return "<div class='title'>Sieć</div><div class='err'>#{esc error}</div>" if error
  rows = data.interfaces.map((i) ->
    main = i.v4[0] ? i.v6[0]
    extra = i.v4.slice(1).concat(if i.v4.length then i.v6 else i.v6.slice(1))
    """
    <div class="row #{if i.name is data.defaultIf then 'default' else ''}">
      <div class="head"><span class="dot"></span><span class="label">#{esc i.label}</span><span class="dev">#{esc i.name}</span></div>
      <div class="addr">#{esc main}</div>
      #{extra.map((a) -> "<div class='addr extra'>#{esc a}</div>").join('')}
    </div>
    """
  ).join('') or "<div class='empty'>brak aktywnych interfejsów</div>"
  pub = data.publicIp ? {}
  publicHtml = if pub.error
    "<div class='err'>#{esc pub.error}</div>"
  else
    [pub.v4, pub.v6].filter((x) -> x).map((a) -> "<div class='addr'>#{esc a}</div>").join('')
  """
  <div class="title">Sieć</div>
  #{rows}
  <div class="row public">
    <div class="head"><span class="label">Publiczny IP</span></div>
    #{publicHtml}
  </div>
  """

style: """
  top: 40px
  left: 900px
  width: 260px
  color: #fff
  font-family: "Anonymous Pro", Menlo, monospace
  font-size: 12px
  filter: drop-shadow(0 1px 4px rgba(0,0,0,.6))
  .title { font-size: 11px; letter-spacing: .2em; text-transform: uppercase; opacity: .85; margin-bottom: 10px }
  .row { margin-bottom: 9px }
  .head { display: flex; align-items: center; gap: 7px }
  .dot { width: 7px; height: 7px; border-radius: 50%; flex: none; background: rgba(255,255,255,.3) }
  .default .dot { background: #7ee08a; box-shadow: 0 0 6px #7ee08a }
  .label { font-weight: 700; white-space: nowrap; overflow: hidden; text-overflow: ellipsis }
  .dev { font-size: 10px; opacity: .45 }
  .addr { margin: 2px 0 0 14px; font-size: 12px; word-break: break-all }
  .addr.extra { font-size: 10px; opacity: .6 }
  .public { margin-top: 12px; padding-top: 8px; border-top: 1px dotted rgba(255,255,255,.35) }
  .public .addr { margin-left: 0 }
  .empty { opacity: .5 }
  .err { color: #ffb4b4; font-size: 11px }
"""
