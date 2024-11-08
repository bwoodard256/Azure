<#
DISCLAIMER
This solution is not supported under any Microsoft standard support program or service. 
It is provided AS IS without warranty of any kind. Microsoft or the author disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. 
The entire risk arising out of the use or performance of the sample script remains with you. 
In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample script, even if Microsoft has been advised of the possibility of such damages.
#>

$Global:ResourceGroupName = 'DO-NOT-DELETE-ServiceHealthRG'
$Global:ActivityLogAlertName = 'IngestServiceHealthAlerts'
$Global:ActionGroupName = 'IngestServiceHealthAlerts'
$Global:ActionGroupShortName = 'IngestSH'
$Global:LogicAppName = ''
$Global:LogicAppResourceId = '' 
$Global:LogicAppCallbackUrl = ''

$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

function Main
{
    $subscriptionList = GetSubscriptions
    Write-Host "Processing $($subscriptionList.Count) subscriptions."

    foreach($subscription in $subscriptionList)
    {
        $resourceGroup = CreateResourceGroup $subscription
        $actionGroup = CreateActionGroup $resourceGroup
        CreateAlertRule -subscription $subscription -resourceGroup $resourceGroup -actionGroup $actionGroup
    }
}
function GetSubscriptions
{
    $subscriptionList = Get-Content .\sublist.txt
    
    return $subscriptionList
}
function CreateResourceGroup ($subscription)
{
    Set-AzContext $subscription
    $resourceGroup = New-AzResourceGroup -Name $Global:ResourceGroupName -Location 'westus' -Force
    Write-Host "$subscription > Created resource group $($resourceGroup.ResourceGroupName)."

    return $resourceGroup
}
function CreateActionGroup ($resourceGroup)
{
    $receiver = New-AzActionGroupReceiver -LogicAppReceiver -Name $LogicAppName -ResourceId $LogicAppResourceId -CallbackUrl $LogicAppCallbackUrl -UseCommonAlertSchema
    $actionGroup = Set-AzActionGroup -Name $ActionGroupName -ShortName $ActionGroupShortName -ResourceGroupName $resourceGroup.ResourceGroupName -Receiver $receiver
    $actionGroupNameValue = $actionGroup.Name
    $actionGroup = New-AzActivityLogAlertActionGroupObject -Id $actionGroup.Id
    Write-Host "$subscription > Created Action Group $actiongroupNameValue."

    return $actionGroup
}
function CreateAlertRule ($subscription, $resourceGroup, $actionGroup)
{
    $activityLogCondition = New-AzActivityLogAlertAlertRuleAnyOfOrLeafConditionObject -Field 'category' -Equal 'ServiceHealth'
    $activityLogScope = "/subscriptions/$subscription"
    $activityLogLocation = 'Global'

    $ActivityLogAlert = New-AzActivityLogAlert -Name $ActivityLogAlertName -ResourceGroupName $resourceGroup.ResourceGroupName -Action $actionGroup -Scope $activityLogScope -Condition $activityLogCondition -Location $activityLogLocation -Enabled $true
    Write-Host "$subscription > Created Alert Rule $($ActivityLogAlert.Name)."
}

Main




