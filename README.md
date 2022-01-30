# Certificate Administration

An architecture for intuitive cross-database permissions and automatic certificate generation.

## Why?

Granting permissions across databases for stored procedures can be [tricky](https://www.sommarskog.se/grantperm.html). Ownership chaining may be relatively easy but can quickly lead to unintended security gaps. Certificate signing is more explicit but also more difficult to set up. Certificate signing also requires engagement with more structures and when multiple permissions across multiple databases are needed what has permission to perform what action can quickly be lost.

This database design of tables, views, and stored procedures mitigates the majority of issues with certificate signing by simplifying the process of permissions management and certificate generation into quickly usable stored procedures. Requests can be grouped into a single file for easy administration like with the [Clean Slate Approach](#clean-slate-approach) or managed dynamically like with the [On The Fly Approach](#on-the-fly-approach).

## Requirements

* [sqlcmd utility](https://docs.microsoft.com/en-us/sql/tools/sqlcmd-utility?view=sql-server-ver15)
* [SQL Server](https://www.microsoft.com/en-us/sql-server/sql-server-downloads) (Tested on SQLServer 2019 15.0.2080.9)
* [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.2) (Tested on 7.2.1)
* sysadmin role on the desired server.

## Getting Started

1. Run [Setup.ps1](./Setup/Setup.ps1)
2. Follow the prompts
3. ???
4. Profit

## Example Uses

### Clean Slate Approach

Create a new sql file. This will store all the permission requests and be easily run after requests change. At the beginning of the file, delete all groups and revoke all permissions to functionally reset the server to a clean slate (as if no permissions had ever been granted via Certificate Administration). In the following lines create groups and requests on target objects. At the end of the file create all the certificates and users and then grant all requests to both groups and objects.

[Example_CleanSlate.sql](./Setup/Example_CleanSlate.sql) follows this approach and is provided as a reference. Everything before the `Begin Example` and after the `End Example` comment blocks is present only so the script executes successfully and then removes all traces of itself.

### On The Fly Approach

All requests can be created on the fly as well. Simply create a request and then grant it as needed. Current requests and their status (granted or not) can be easily viewed via the [PermissionRequests](./SQL/Views/Permission/PermissionRequests.sql) view. Objects added to a group that has already been granted requests will be immediately granted the same permissions as the group.

[Example_OnTheFly.sql](./Setup/Example_OnTheFly.sql) follows this approach and is provided as a reference. Everything before the `Begin Example` and after the `End Example` comment blocks is present only so the script executes successfully and then removes all traces of itself.

## To Do

- [ ] Create a procedure to remove tracked objects that no longer exist (were deleted). Currently, if a tracked object is deleted and any [Revoke Procedure](./SQL/Programmability/Stored%20Procedures/Permission/_Revoke/) is executed, the proc will fail since it cannot validate the non-existing object.
  - [ ] Source/target databases that no longer exist (cascade)
  - [ ] Source/target objects that no longer exist (cascade)
  - [ ] Source/target roles that no longer exist (cascade)
  - [ ] Source/target certificates that no longer exist (cascade)
- [ ] Provide a GUI to further simplify interfacing with the architecture.
