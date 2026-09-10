# Builds the published pages from src/.
# Each src/vN.html is a plain standalone page with no switcher.
# This injects the version + device switcher and writes the output files.
#
# Run:  powershell -ExecutionPolicy Bypass -File build.ps1

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

# --- version registry: add one line per new version -------------------------
$VERSIONS = @(
  @{ n = '1'; label = 'Original';  src = 'v1.html'; out = 'index.html';    path = ''    },
  @{ n = '2'; label = 'Catalogue'; src = 'v2.html'; out = 'v2\index.html'; path = 'v2/' },
  @{ n = '3'; label = 'Clean hero'; src = 'v3.html'; out = 'v3\index.html'; path = 'v3/' }
)
$BASE = '/Share-Page-GroMo/'
# ---------------------------------------------------------------------------

$MON = '<svg viewBox="0 0 24 24" fill="none"><rect x="2.5" y="4" width="19" height="13" rx="2" stroke="currentColor" stroke-width="2"/><path d="M9 21h6M12 17v4" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>'
$PHN = '<svg viewBox="0 0 24 24" fill="none"><rect x="6.5" y="2.5" width="11" height="19" rx="2.5" stroke="currentColor" stroke-width="2"/><path d="M10.5 18.5h3" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>'

$CSS = @'
<style>
:root{--vsw:47px}
.vswitch{position:sticky;top:0;z-index:200;display:flex;gap:8px;align-items:center;justify-content:center;flex-wrap:nowrap;overflow-x:auto;height:var(--vsw);padding:0 10px;background:#0d100e;font-family:system-ui,-apple-system,sans-serif;border-bottom:1px solid #232a26;scrollbar-width:none}
.vswitch::-webkit-scrollbar{display:none}
.vswitch a{display:flex;align-items:center;gap:8px;padding:4px 11px 4px 4px;border-radius:8px;background:#171c19;border:1px solid #2b322e;text-decoration:none;color:#93a197;transition:.14s ease;flex:none}
.vswitch a:hover{color:#fff;border-color:#46C083}
.vswitch a.on{background:#12301f;border-color:#0A7D46;color:#d6f2e2}
.vswitch .sq{width:24px;height:24px;border-radius:5px;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700;background:#252c28;color:#b9c6bd;flex:none}
.vswitch a.on .sq{background:#0A7D46;color:#fff}
.vswitch .sq svg{width:14px;height:14px}
.vswitch .lb{font-size:12px;font-weight:500;white-space:nowrap}
.vswitch .div{width:1px;height:26px;background:#2b322e;flex:none;margin:0 3px}
.vswitch a:focus-visible{outline:2px solid #46C083;outline-offset:2px}
@media(max-width:520px){.vswitch .lb{display:none}.vswitch a{padding:4px}}
</style>
'@

$HIDE = @'
<script>
if(new URLSearchParams(location.search).get('embed')==='1'){
  var _n=document.querySelector('.vswitch');
  if(_n)_n.style.display='none';
  document.documentElement.style.setProperty('--vsw','0px');
  var _s=document.createElement('style');
  _s.textContent='html,body{scrollbar-width:none;-ms-overflow-style:none}html::-webkit-scrollbar,body::-webkit-scrollbar{width:0;height:0;display:none}';
  document.head.appendChild(_s);
}
</script>
'@

function New-Switcher([string]$active) {
  $cur = $VERSIONS | Where-Object { $_.n -eq $active }
  $tiles = foreach ($v in $VERSIONS) {
    $on = if ($v.n -eq $active) { 'on' } else { '' }
    "<a class=`"$on`" href=`"$BASE$($v.path)`" title=`"Version $($v.n) - $($v.label)`"><span class=`"sq`">$($v.n)</span><span class=`"lb`">$($v.label)</span></a>"
  }
  $device = "<span class=`"div`"></span>" +
            "<a class=`"on`" href=`"$BASE$($cur.path)`" title=`"Desktop view`"><span class=`"sq`">$MON</span><span class=`"lb`">Desktop</span></a>" +
            "<a href=`"${BASE}frame.html?v=$active`" title=`"Mobile view`"><span class=`"sq`">$PHN</span><span class=`"lb`">Mobile</span></a>"
  return "<nav class=`"vswitch`" aria-label=`"Design version and device`">`n" + ($tiles -join "`n") + "`n$device`n</nav>`n$HIDE"
}

foreach ($v in $VERSIONS) {
  $srcPath = Join-Path $root "src\$($v.src)"
  $outPath = Join-Path $root $v.out
  if (-not (Test-Path $srcPath)) { Write-Warning "missing source: $srcPath"; continue }

  $c = Get-Content $srcPath -Raw -Encoding UTF8
  if ($c -match '<nav class="vswitch"') { Write-Warning "$($v.src) already contains a switcher - sources must stay clean"; continue }

  $c = $c -replace '</head>', ($CSS + "`n</head>")
  $c = [regex]::Replace($c, '<body>\s*', ("<body>`n" + (New-Switcher $v.n) + "`n"), 1)

  $dir = Split-Path -Parent $outPath
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $c | Out-File $outPath -Encoding utf8
  Write-Output ("built {0,-14} -> {1}" -f $v.src, $v.out)
}

Write-Output "done. frame.html serves mobile mode and reads ?v= from the query."

