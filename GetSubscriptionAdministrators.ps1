<#
DISCLAIMER
This solution is not supported under any Microsoft standard support program or service. 
It is provided AS IS without warranty of any kind. Microsoft or the author disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. 
The entire risk arising out of the use or performance of the sample script remains with you. 
In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample script, even if Microsoft has been advised of the possibility of such damages.
#>

#Note: Script will generate a spreadsheet with admin (Account Admin, Service Admin, Co-Admin, Owners) users for the subscriptions linked to the provided tenant. Please use & store file appropriately, according to your org security policies.

function Main
{
    #Get Subscriptions for a given TenantID
    $TenantID = Read-Host "Provide an Azure TenantID"
    $Subscriptions = $(Get-AzSubscription | Where TenantId -EQ $TenantID)

    #Check for file
    if(Test-Path ".\SubscriptionOwnerReport.csv")
    {
        $Answer = Read-Host "Adminsfile exists at $($PWD)\SubscriptionOwnerReport.csv. Are you sure you want to override? (Y/N)"
        if($Answer -ne "Y")
        {
            Write-Host "Exiting"
            Exit
        }
        else
        {
            Set-Content ".\SubscriptionOwnerReport.csv" -Value "SubscriptionName, SubscriptionId, Display Name, SignIn Name, Role"
        }
    }

    #Actual workload - get administrator (Account Admin, Service Admin, Co-Admin, Owners) display name, signin, role and write them to file
    $Counter = 0
    foreach($Subscription in $Subscriptions)
    {
        $Counter++
        Write-Host "Fetching results for subscription $($Subscription.Name) ($Counter/$($Subscriptions.Count))"
        WriteAdminsToFile($Subscription)
    }
}

#Get administrator (Account Admin, Service Admin, Co-Admin, Owners) display name, signin, role
Function WriteAdminsToFile($Subscription)
{
    #Get all role assignments
    $AzRoleAssignments = Get-AzRoleAssignment -Scope "/subscriptions/$($Subscription.ID)" -IncludeClassicAdministrators -WarningAction 0 | select DisplayName, SignInName, RoleDefinitionName

    foreach($AzRoleAssignment in $AzRoleAssignments)
    {
        #Check to see if there are multiple role assignments to a single user. Will be delimited by ';'
        if($AzRoleAssignment.RoleDefinitionName -like '*;*')
        {
            $SplitAzRoleAssignments = $AzRoleAssignment.RoleDefinitionName.Split(';')
            foreach($SplitAzRoleAssignment in $SplitAzRoleAssignments)
            {
                if($SplitAzRoleAssignment -eq "Owner" -or $SplitAzRoleAssignment -eq "CoAdministrator" -or $SplitAzRoleAssignment -eq "ServiceAdministrator" -or $SplitAzRoleAssignment -eq "AccountAdministrator")
                {
                    Add-Content ".\SubscriptionOwnerReport.csv" -Value "$($Subscription.Name), $($Subscription.Id), $($AzRoleAssignment.DisplayName), $($AzRoleAssignment.SignInName), $SplitAzRoleAssignment"
                }
            }
        }
        else
        {
            if($AzRoleAssignment.RoleDefinitionName -eq "Owner" -or $AzRoleAssignment.RoleDefinitionName -eq "CoAdministrator" -or $AzRoleAssignment.RoleDefinitionName -eq "ServiceAdministrator" -or $AzRoleAssignment.RoleDefinitionName -eq "AccountAdministrator")
            {
                Add-Content ".\SubscriptionOwnerReport.csv" -Value "$($Subscription.Name), $($Subscription.Id), $($AzRoleAssignment.DisplayName), $($AzRoleAssignment.SignInName), $($AzRoleAssignment.RoleDefinitionName)"
            }
        }
    }
}

#Call Main
Main