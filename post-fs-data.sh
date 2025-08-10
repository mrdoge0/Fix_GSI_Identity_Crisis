#!/system/bin/sh
# (c) 2025 mrdoge0, Free Software Licensed under Apache-2.0

# Set up dotfile directory
DFDIR="/data/adb/fix_gsi_identity_crisis.d"
[ ! -d "${DFDIR}" ] && mkdir "${DFDIR}"

# 99,999999999% of "vendor" filesystems come from stock ROMs or conventional custom ROMs, so they have the correct device info.
VENDORPROP="/vendor/build.prop"
SYSTEMPROP="/system/build.prop"

if [ -f "${VENDORPROP}" ]; then
    ## Main function
    
    # Get source props.
    VENDORBRAND=$(grep -E 'ro.product.vendor.brand=' "${VENDORPROP}" | cut -d'=' -f2)
    VENDORDEVICE=$(grep -E 'ro.product.vendor.device=' "${VENDORPROP}" | cut -d'=' -f2)
    VENDORMANUFACTURER=$(grep -E 'ro.product.vendor.manufacturer=' "${VENDORPROP}" | cut -d'=' -f2)
    VENDORMODEL=$(grep -E 'ro.product.vendor.model=' "${VENDORPROP}" | cut -d'=' -f2)

    # Do the props.
    if [ ! -z "${VENDORDEVICE}" ]; then
        for PART in "" ".product" ".system" ".system_ext" ".bootimage"; do
            resetprop -n ro.product${PART}.brand "${VENDORBRAND}"
            resetprop -n ro.product${PART}.device "${VENDORDEVICE}"
            resetprop -n ro.product${PART}.manufacturer "${VENDORMANUFACTURER}"
            resetprop -n ro.product${PART}.model "${VENDORMODEL}"
        done
    else
        log -p e -t Fix_GSI_Identity_Crisis "Operation FAILED"
        setprop ro.fix_gsi_identity_crisis.job_successful "0"
        exit 1
    fi

    # Market name support - Separate from standard resetprops because some devices don't have marketname props.
    ODMMN=$(grep -E 'ro.product.odm.marketname=' "/odm/etc/build.prop" | cut -d'=' -f2)
    if [ ! -z ${ODMMN} ]; then
        for PART in "" ".product" ".system" ".system_ext" ".bootimage"; do
            resetprop -n ro.product${PART}.marketname "${ODMMN}"
        done
        for PART in "system_dlkm" "bootimage"; do
            resetprop -n ro.product.${PART}.marketname "${VENDORDEVICE}"
        done
    fi

    ## A new experimental feature - fixing fingerprints (usable for Play Integrity)

    # Gather shit
    SYSTEMNAME=$(grep -E 'ro.system.build.fingerprint=' "${SYSTEMPROP}" | cut -d'=' -f2 | cut -d'/' -f2 | cut -d'/' -f1)
    SYSTEMVER=$(grep -E 'ro.build.version.release_or_codename=' "${SYSTEMPROP}" | cut -d'=' -f2)
    SYSTEMID=$(grep -E 'ro.build.id=' "${SYSTEMPROP}" | cut -d'=' -f2)

    # Get og incremental if not spoofed, get spoof setting if spoofed
    if [ -f "${DFDIR}/inc_spoof" ] && [ ! -z "${DFDIR}/inc_spoof" ]; then
        SYSTEMINC=$(cat "${DFDIR}/inc_spoof")
    else
        SYSTEMINC=$(grep -E 'ro.build.version.incremental=' "${SYSTEMPROP}" | cut -d'=' -f2)
    fi

    # Get real build type and tags if not spoofed, get "user/release-keys" if spoofed
    SYSTEMTYPE=$(grep -E 'ro.build.type=' "${SYSTEMPROP}" | cut -d'=' -f2)
    SYSTEMTAGS=$(grep -E 'ro.build.tags=' "${SYSTEMPROP}" | cut -d'=' -f2)

    # Vendor props
    VENDORNAME=$(grep -E 'ro.product.vendor.name=' "${VENDORPROP}" | cut -d'=' -f2)
    VENDORVER=$(grep -E 'ro.vendor.build.version.release_or_codename=' "${VENDORPROP}" | cut -d'=' -f2)
    VENDORID=$(grep -E 'ro.vendor.build.id=' "${VENDORPROP}" | cut -d'=' -f2)
    VENDORINC=$(grep -E 'ro.vendor.build.version.incremental=' "${VENDORPROP}" | cut -d'=' -f2)
    VENDORTYPE=$(grep -E 'ro.vendor.build.type=' "${VENDORPROP}" | cut -d'=' -f2)
    VENDORTAGS=$(grep -E 'ro.vendor.build.tags=' "${VENDORPROP}" | cut -d'=' -f2)

    # Example results: "Xiaomi/treble_arm64_bvS/lavender:16/BP2A.250605.031.A3/OS2.0.215.0.WFGMIXM:userdebug/test-keys" (my device in my personal settings at this module :D)
    #                  "treble_arm64_bvS-userdebug 16 BP2A.250605.031.A3 OS2.0.215.0.WFGMIXM test-keys" (also my device in my personal settings at this module :D)
    TRUEFINGERPRINT="${VENDORBRAND}/${SYSTEMNAME}/${VENDORDEVICE}:${SYSTEMVER}/${SYSTEMID}/${SYSTEMINC}:${SYSTEMTYPE}/${SYSTEMTAGS}"
    TRUEDESC="${SYSTEMNAME}-${SYSTEMTYPE} ${SYSTEMVER} ${SYSTEMID} ${SYSTEMINC} ${SYSTEMTAGS}"
    for PART in "" ".system" ".system_ext" ".product"; do
        resetprop -n ro${PART}.build.fingerprint "${TRUEFINGERPRINT}"
        resetprop -n ro${PART}.build.description "${TRUEDESC}"
    done

    ## True vendor fingerprint (sometimes they are spoofed)
    
    # Example result: "Xiaomi/lineage_lavender/lavender:15/BP1A.250505.005/OS2.0.2.0.VFGMIXM:user/release-keys"
    #                 (my device, really a lineageos vendor with real user/release-keys, and i manually spoofed incremental to hyperos 2.0)
    TRUEVENFP="${VENDORBRAND}/${VENDORNAME}/${VENDORDEVICE}:${VENDORVER}/${VENDORID}/${VENDORINC}:${VENDORTYPE}/${VENDORTAGS}"
    TRUEVENDESC="${VENDORNAME}-${VENDORTYPE} ${VENDORVER} ${VENDORID} ${VENDORINC} ${VENDORTAGS}"
    for PART in "vendor" "vendor_dlkm" "odm" "bootimage"; do
        resetprop -n ro.${PART}.build.fingerprint "${TRUEVENFP}"
        resetprop -n ro.${PART}.build.description "${TRUEVENDESC}"
    done

    # bonuses
    resetprop -n ro.build.flavor "${SYSTEMNAME}-${SYSTEMTYPE}"
    if [ "${SYSTEMTYPE}" != "user" ]; then
        resetprop -n ro.build.display.id "${TRUEDESC}"
    fi

    # Spoof to user/release-keys if enabled
    if [ -f "${DFDIR}/spoof_user" ]; then
        for PART in "" ".system" ".product" ".system_ext"; do
            resetprop -n ro${PART}.build.type "user"
            resetprop -n ro${PART}.build.tags "release-keys"
        done
    fi

    # Report your success.
    log -p i -t Fix_GSI_Identity_Crisis "Operation SUCCESSFUL"
    setprop ro.fix_gsi_identity_crisis.job_successful "1"
    exit 0
else
    log -p e -t Fix_GSI_Identity_Crisis "Operation FAILED"
    setprop ro.fix_gsi_identity_crisis.job_successful "0"
    exit 1
fi
