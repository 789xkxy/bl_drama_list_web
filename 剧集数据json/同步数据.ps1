# 绝对BL 数据同步脚本
# 从 drama_list02.json 生成规范化的 dramas.json（权威数据）和页面直接引用的 dramas.js
$ErrorActionPreference = 'Stop'
$base = Split-Path -Parent $MyInvocation.MyCommand.Path
$srcFile = Join-Path $base 'drama_list02.json'
$jsonOut = Join-Path $base 'dramas.json'
$jsOut   = Join-Path $base 'dramas.js'

function Escape-JsonString([string]$s) {
  if ($null -eq $s) { return '""' }
  $sb = New-Object System.Text.StringBuilder
  foreach ($ch in $s.ToCharArray()) {
    switch ($ch) {
      '"'  { [void]$sb.Append('\"') }
      '\'  { [void]$sb.Append('\\') }
      "`b" { [void]$sb.Append('\b') }
      "`f" { [void]$sb.Append('\f') }
      "`n" { [void]$sb.Append('\n') }
      "`r" { [void]$sb.Append('\r') }
      "`t" { [void]$sb.Append('\t') }
      default {
        $code = [int]$ch
        if ($code -lt 0x20) { [void]$sb.Append(('\u{0:x4}' -f $code)) } else { [void]$sb.Append($ch) }
      }
    }
  }
  return '"' + $sb.ToString() + '"'
}

$data = Get-Content -LiteralPath $srcFile -Raw -Encoding UTF8 | ConvertFrom-Json
$items = @()
foreach ($d in $data) {
  $image = [regex]::Replace($d.image, '^https://github\.com/([^/]+)/([^/]+)/blob/([^/]+)/(.+)$', 'https://raw.githubusercontent.com/$1/$2/$3/$4')
  $summary = $d.summary
  $tags = @($d.tags)
  $title = $d.title
  if ($d.id -eq '0002') { $summary = '性格开朗的插画家奥泽律分手后遭遇事故，唯独丢失了与池上郁哉恋爱的全部记忆。郁哉以室友身份陪伴在律身边，努力想要重启二人的恋情。' }
  if ($d.id -eq '0003') { $tags = @('酸涩') }
  if ($d.id -eq '0005') { $title = '相逢骤雨中' }

  $actors    = (@($d.actors)    | ForEach-Object { Escape-JsonString ($_ -as [string]) }) -join ','
  $directors = (@($d.directors) | ForEach-Object { Escape-JsonString ($_ -as [string]) }) -join ','
  $tagsArr   = ($tags            | ForEach-Object { Escape-JsonString ($_ -as [string]) }) -join ','

  $items += @"
  {
    "id": $(Escape-JsonString $d.id),
    "title": $(Escape-JsonString $title),
    "year": $($d.year),
    "country": $(Escape-JsonString $d.country),
    "image": $(Escape-JsonString $image),
    "summary": $(Escape-JsonString $summary),
    "actors": [$actors],
    "cp": $(Escape-JsonString $d.cp),
    "directors": [$directors],
    "tags": [$tagsArr]
  }
"@
}

$json = "[" + ($items -join ",`r`n") + "]`r`n"
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($jsonOut, $json, $utf8)

$js = "// 由 同步数据.ps1 从 dramas.json 自动生成，请勿手改`r`n// 页面通过 <script src=""../../剧集数据/dramas.js""></script> 引入（file:// 打开也能用）`r`nwindow.DRAMAS = " + $json + ";`r`n"
$js = $js.Replace('</', '<\/')
[System.IO.File]::WriteAllText($jsOut, $js, $utf8)

Write-Output ("dramas.json 已生成: " + (Get-Item -LiteralPath $jsonOut).Length + " bytes, " + $items.Count + " 条")
Write-Output ("dramas.js 已生成: " + (Get-Item -LiteralPath $jsOut).Length + " bytes")
