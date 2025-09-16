param(
  [Parameter(Mandatory=$true)][string]$InputFilePath,
  [Parameter(Mandatory=$true)][string]$OutputFilePath
)

Import-Module powershell-yaml

function Get-Field {
  param([object]$o,[string]$n)
  if($null -eq $o){return $null}
  if($o -is [hashtable]){
    $k=$o.Keys|Where-Object{$_ -ieq $n}|Select-Object -First 1
    if($k){return $o[$k]} else{return $null}
  } else {
    ($o.PSObject.Properties|Where-Object{$_.Name -ieq $n}|Select-Object -First 1).Value
  }
}

function Remove-Fields {
  param([object]$o,[string[]]$n)
  if($null -eq $o){return $null}
  if($o -is [hashtable]){
    foreach($x in $n){$k=$o.Keys|Where-Object{$_ -ieq $x}|Select-Object -First 1; if($k){[void]$o.Remove($k)}}
    return $o
  } else {
    $h=[ordered]@{}; foreach($p in $o.PSObject.Properties){if(-not($n|Where-Object{$_ -ieq $p.Name})){$h[$p.Name]=$p.Value}}; [pscustomobject]$h
  }
}

function Is-List { param([object]$o) if($null -eq $o){return $false} ($o -is [System.Collections.IList]) -or ($o -is [object[]]) -or $o.GetType().IsArray }
function Get-Type { param([object]$b) if($b.ModuleName){"$($b.ModuleName)/$($b.Name)"} else {$b.Name} }
function Is-Registry { param([string]$n) ($n -ieq 'Microsoft.Windows/Registry') }
function Build-RegProps { param([object]$s) $vd=[ordered]@{}; if($s.ValueType){$vd[$s.ValueType]=$s.ValueData}; [ordered]@{keyPath=$s.Key; valueName=$s.ValueName; valueData=$vd} }
function InstallName { param([string]$t) if(-not $t){return $null}; $t=$t.Trim(); if($t -match '^\s*Install\b'){$t}else{"Install $t"} }
function PickToken { param([object]$o) foreach($k in 'PackageName','Id','Name','Path','Value','Version','productId','valueName'){ $v=Get-Field $o $k; if($v){return [string]$v} } $null }

function New-DscResource {
  param([object]$PropertyData,[string]$ResourceType,[string]$ResourceBlockName)
  $label=Get-Field $PropertyData 'Description'; if(-not $label){$label=Get-Field $PropertyData 'Name'}

  if(Is-Registry $ResourceBlockName){
    $props=Build-RegProps $PropertyData
    $rname= if($label){$label}else{ InstallName (Get-Field $PropertyData 'ValueName') }
  }else{
    $props=Remove-Fields $PropertyData @('Name','Description')
    if($label){$rname=$label}else{ $tok=PickToken $props; $rname= if($tok){InstallName $tok}else{"Resource$(Get-Random)"} }
  }

  [pscustomobject]@{ name=$rname; type=$ResourceType; properties=$props }
}

$doc = Get-Content -LiteralPath $InputFilePath -Raw | ConvertFrom-Yaml
$res = [System.Collections.Generic.List[object]]::new()

foreach($b in @($doc)){
  $type = Get-Type $b
  $p = $b.Property
  if(Is-List $p){ foreach($it in $p){ $res.Add( (New-DscResource -PropertyData $it -ResourceType $type -ResourceBlockName $b.Name) ) } }
  elseif($null -ne $p){ $res.Add( (New-DscResource -PropertyData $p -ResourceType $type -ResourceBlockName $b.Name) ) }
  else { $res.Add([pscustomobject]@{name="Install $($b.Name)"; type=$type; properties=@{}}) }
}

[pscustomobject]@{
  '$schema'='https://raw.githubusercontent.com/PowerShell/DSC/main/schemas/v3/bundled/config/document.json'
  resources=$res
} | ConvertTo-Yaml | Set-Content -LiteralPath $OutputFilePath -Encoding UTF8

Write-Host 'OK'
