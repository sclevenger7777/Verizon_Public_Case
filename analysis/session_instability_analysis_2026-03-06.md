# Verizon Telephony / APN / Session Analysis
Date of analysis: 2026-03-06

## Purpose

This document analyzes device-side telephony records related to Verizon network attachment, APN state, bearer establishment, and session loss behavior.

The objective is to determine whether the observed problem is more consistent with:
- customer APN misconfiguration,
- subscriber provisioning failure,
- device-side failure,
- or network-side bearer/session instability.

## Scope

This analysis is based on the telephony and service-state records captured from the device and provided in the evidence set for 2026-03-06.

It focuses on:
- service state
- APN state
- bearer establishment
- IP assignment
- routing
- disconnect causes
- recurring reconnection behavior

## Executive summary

The records show that the device successfully registers on Verizon, successfully establishes the default internet bearer, IMS bearer, and CBS/MMS bearer, and receives valid carrier routing and DNS information.

The most significant failure pattern is not APN rejection or provisioning denial. Instead, the evidence shows successful bearer establishment followed by repeated session drops and re-establishment. Multiple disconnections explicitly show `LOST_CONNECTION(0x10004)`.

The active default APN remains Verizon Internet (`VZWINTERNET`) and is repeatedly shown as `CARRIER_EDITED`, while IMS and CBS/MMS APNs remain `UNEDITED`. This supports the conclusion that the active APN set is carrier-controlled rather than user-customized.

Overall, the records are more consistent with post-establishment session instability than with customer APN misconfiguration.

## Baseline network state

Across the records, the device repeatedly shows:
- `mVoiceRegState=0(IN_SERVICE)`
- `mDataRegState=0(IN_SERVICE)`
- operator identity `311480`
- Verizon service identity
- repeated 5G NR service states

This indicates the handset is recognized by the Verizon network and is attaching successfully.

## Provisioning assessment

The records do not show clear evidence of:
- attach rejection
- PDP context rejection
- authentication rejection
- service denial
- SIM not provisioned

Instead, the device repeatedly reaches a registered state and successfully establishes bearers. That means subscriber provisioning is at least sufficient for attachment and data-bearer creation.

## APN assessment

The logs repeatedly show these APN contexts:

### Default internet APN
- Name: `Verizon Internet`
- APN: `VZWINTERNET`
- Types: `supl | dun | hipri | default`
- Edit state: `CARRIER_EDITED`

### IMS APN
- Name: `Verizon IMS`
- APN: `IMS`
- Types: `ims | ia`
- Edit state: `UNEDITED`

### CBS / MMS APN
- Name: `Verizon CBS`
- APN: `VZWAPP`
- Types: `mms | cbs`
- Edit state: `UNEDITED`

This is important. The default data APN remains Verizon’s own carrier-defined APN and is shown as carrier-managed. The logs do not support a conclusion that the active failure state was caused by a harmful user APN change.

## Locked APN context

The device behavior and active APN records are consistent with a locked or carrier-controlled APN configuration. The data path remains on Verizon-defined APNs and not on a user-created custom APN.

If Verizon attributes the condition to customer APN modification, that claim is not supported by the telephony state shown here.

## IP addressing and routing

The default bearer repeatedly receives IPv4 addresses in the `100.64.0.0/10` carrier-grade NAT range, including values such as:
- `100.93.x.x`
- `100.75.x.x`
- `100.64.x.x`
- `100.66.x.x`

This indicates the device is receiving private carrier-core IPv4 addressing behind carrier NAT, which is normal for a mobile carrier.

Routes and next-hop behavior show standard internal packet-core gateway assignment. The device is clearly receiving:
- interface assignment
- local IP address
- default route
- carrier DNS

That means the data session is not failing at the earliest provisioning stage.

## Bearer lifecycle behavior

The recurring pattern in the records is:

1. `CONNECTING`
2. `CONNECTED`
3. `DISCONNECTING` or `DISCONNECTED`
4. `CONNECTING`
5. `CONNECTED`

This occurs on already-established bearers.

That pattern matters because it is inconsistent with a simple “wrong APN” explanation. A fundamentally invalid APN generally fails bearer establishment up front. Here, the bearer comes up successfully and only later drops.

## Disconnect cause assessment

Multiple bearer disconnects explicitly show:

- `fail cause: LOST_CONNECTION(0x10004)`

This is a key finding.

It indicates post-establishment session loss rather than initial APN selection failure or provisioning denial.

That weakens explanations based on:
- customer APN typo
- unsupported APN
- invalid subscriber profile
- inability to attach

The session is being built successfully, then lost.

## IMS assessment

IMS establishes successfully and remains active. There are handover-related IMS records between WWAN and IWLAN contexts, but these do not undermine the main analysis.

Nothing in the IMS records demonstrates a defective device or failed subscriber provisioning.

## CBS / MMS bearer assessment

The CBS/MMS bearer (`VZWAPP`) also repeatedly establishes and later disconnects, with recurring reconnect behavior.

That is important because it shows the instability is not isolated to one single malformed APN entry. Multiple carrier-defined bearers are being created successfully and later lost.

This strengthens the conclusion that the problem is network-session instability rather than user APN misconfiguration.

## Registration and radio behavior

The service-state records show normal mobility behavior across time, including:
- repeated NR service on Verizon
- changing serving PCI and NCI values
- temporary LTE presence in part of the record
- brief appearance of LTE carrier aggregation in one interval
- return to NR service

These behaviors are compatible with ordinary live-network mobility and reselection.

They do not, by themselves, show device malfunction.

## What the records support

The records support the following conclusions:

1. The device successfully registers on Verizon.
2. The subscriber profile is sufficiently valid for bearer establishment.
3. The active default internet APN is Verizon-defined and carrier-managed.
4. IMS and CBS/MMS APNs also establish successfully.
5. The device receives valid internal carrier routing, addressing, and DNS.
6. The recurring issue occurs after successful bearer establishment.
7. Multiple disconnects explicitly show `LOST_CONNECTION(0x10004)`.
8. The evidence is more consistent with session instability than with customer APN misconfiguration.

## What the records do not support

The records do not support the following conclusions:

1. That the device is failing to provision at the subscriber level.
2. That the active data APN is a harmful user-created APN.
3. That the default bearer cannot establish.
4. That the issue is explained solely by APN editing on the customer side.
5. That the evidence clearly proves handset hardware failure.

## Conclusion

The most supportable technical conclusion is:

The device is successfully attaching to Verizon, successfully establishing carrier-defined bearers, and then intermittently losing those already-established sessions. The logs show carrier-controlled APN state and do not substantiate a claim that the issue was caused by customer APN misconfiguration. The dominant failure mode is post-establishment bearer/session loss, including repeated `LOST_CONNECTION(0x10004)` events.
