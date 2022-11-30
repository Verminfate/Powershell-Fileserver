$hostname = "http://192.168.111.100:8000/"
$share_dir = "C:\Users\example.user\Downloads"

cls
Set-Location $share_dir
$httpsrvlsnr = New-Object System.Net.HttpListener;
$httpsrvlsnr.Prefixes.Add($hostname);
$httpsrvlsnr.Start();
$webroot = New-PSDrive -Name webroot -PSProvider FileSystem -Root $PWD.Path
[byte[]]$buffer = $null
$hostname
while ($httpsrvlsnr.IsListening) {
    try {
        $ctx = $httpsrvlsnr.GetContext();
        
        if ($ctx.Request.RawUrl -eq "/") {
            $html = "<html>`n" + "<a>Listing for " + $share_dir + "</a><br><br>`n" 
            foreach ($name in Get-ChildItem -Path $PWD.Path -Force | Select-Object -ExpandProperty Name){
                $html += "<a href=`"$name`">$name</a><br>`n"
            }
            $html += "</html>`n"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html);
            $ctx.Response.ContentLength64 = $buffer.Length;
            $ctx.Response.OutputStream.WriteAsync($buffer, 0, $buffer.Length)
        }
        elseif ($ctx.Request.RawUrl -eq "/stop"){
            $httpsrvlsnr.Stop();
            Remove-PSDrive -Name webroot -PSProvider FileSystem;
        }
        elseif ($ctx.Request.RawUrl -match "\/[A-Za-z0-9-\s.)(\[\]]") {
            if ([System.IO.File]::Exists((Join-Path -Path $PWD.Path -ChildPath $ctx.Request.RawUrl.Trim("/\")))) {
                $buffer = [System.Text.Encoding]::UTF8.GetBytes((Get-Content -Path (Join-Path -Path $PWD.Path -ChildPath $ctx.Request.RawUrl.Trim("/\"))));
                $ctx.Response.ContentLength64 = $buffer.Length;
                $ctx.Response.OutputStream.WriteAsync($buffer, 0, $buffer.Length)
            } 
        }

    }
    catch [System.Net.HttpListenerException] {
        Write-Host $_
    }
}
