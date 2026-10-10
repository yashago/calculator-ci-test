# Opens the in-cluster dashboards on localhost through kubectl port-forward tunnels.
# Argo CD and Argo Rollouts run in EKS; nothing here is exposed publicly.
#
#   .\infra\dashboards.ps1          # then Ctrl+C to close the tunnels
#
# Needs: aws login, kubectl, and your current IP in admin_cidrs (terraform.tfvars).

$ErrorActionPreference = 'Stop'
$Cluster = 'calculator'
$Region  = 'il-central-1'

$Tunnels = @(
    @{ Name = 'Argo Rollouts'; Namespace = 'argo-rollouts'; Service = 'argo-rollouts-dashboard'; Ports = '3100:3100'; Url = 'http://localhost:3100/rollouts' }
    @{ Name = 'Argo CD';       Namespace = 'argocd';        Service = 'argocd-server';           Ports = '8080:443';  Url = 'https://localhost:8080' }
)

aws eks update-kubeconfig --name $Cluster --region $Region | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Can't reach the cluster. Run 'aws login', and check the stack is up." }

$secret = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>$null
$password = if ($secret) { [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($secret)) } else { '(initial secret not found; was the password changed?)' }

$jobs = foreach ($t in $Tunnels) {
    Start-Job -Name $t.Name -ScriptBlock {
        param($ns, $svc, $ports)
        kubectl -n $ns port-forward "svc/$svc" $ports
    } -ArgumentList $t.Namespace, $t.Service, $t.Ports
}

try {
    # Wait until each tunnel accepts connections, then open it in the browser
    foreach ($t in $Tunnels) {
        $port = [int]($t.Ports -split ':')[0]
        $ready = $false
        for ($i = 0; $i -lt 30 -and -not $ready; $i++) {
            Start-Sleep -Milliseconds 500
            $ready = Test-NetConnection -ComputerName localhost -Port $port -InformationLevel Quiet -WarningAction SilentlyContinue
        }
        if (-not $ready) {
            Receive-Job -Name $t.Name
            throw "$($t.Name) tunnel did not start on port $port (is the port already in use?)"
        }
        Start-Process $t.Url
        Write-Host ("{0,-14} {1}" -f $t.Name, $t.Url)
    }
    Write-Host ""
    Write-Host "Argo CD login: admin / $password"
    Write-Host "Argo CD uses a self-signed certificate: accept the browser warning once."
    Write-Host ""
    Write-Host "Tunnels are open. Press Ctrl+C to close them."

    while ($true) {
        foreach ($j in $jobs) {
            if ($j.State -ne 'Running') {
                Receive-Job $j
                throw "$($j.Name) tunnel stopped (cluster down, or your IP changed?)"
            }
        }
        Start-Sleep -Seconds 2
    }
}
finally {
    $jobs | Stop-Job -PassThru | Remove-Job -Force
    Write-Host "Tunnels closed."
}
