#!/system/bin/sh
# (c) 2025 mrdoge0, Free Software Licensed under Apache-2.0

# 99,999999999% of "vendor" filesystems come from stock ROMs or conventional custom ROMs, so they have the correct device info.
VENDORPROP="/vendor/build.prop"

if [ -f "$VENDORPROP" ]; then
    # Get source props.
    VENDORBRAND=$(grep -E 'ro.product.vendor.brand=' "$VENDORPROP" | cut -d'=' -f2)
    VENDORDEVICE=$(grep -E 'ro.product.vendor.device=' "$VENDORPROP" | cut -d'=' -f2)
    VENDORMANUFACTURER=$(grep -E 'ro.product.vendor.manufacturer=' "$VENDORPROP" | cut -d'=' -f2)
    VENDORMODEL=$(grep -E 'ro.product.vendor.model=' "$VENDORPROP" | cut -d'=' -f2)

    # Do the props.
    if [ ! -z "$VENDORDEVICE" ]; then
        resetprop -n ro.product.brand "$VENDORBRAND"
        resetprop -n ro.product.device "$VENDORDEVICE"
        resetprop -n ro.product.manufacturer "$VENDORMANUFACTURER"
        resetprop -n ro.product.model "$VENDORMODEL"
        resetprop -n ro.product.product.brand "$VENDORBRAND"
        resetprop -n ro.product.product.device "$VENDORDEVICE"
        resetprop -n ro.product.product.manufacturer "$VENDORMANUFACTURER"
        resetprop -n ro.product.product.model "$VENDORMODEL"
        resetprop -n ro.product.system.brand "$VENDORBRAND"
        resetprop -n ro.product.system.device "$VENDORDEVICE"
        resetprop -n ro.product.system.manufacturer "$VENDORMANUFACTURER"
        resetprop -n ro.product.system.model "$VENDORMODEL"
        resetprop -n ro.product.system_ext.brand "$VENDORBRAND"
        resetprop -n ro.product.system_ext.device "$VENDORDEVICE"
        resetprop -n ro.product.system_ext.manufacturer "$VENDORMANUFACTURER"
        resetprop -n ro.product.system_ext.model "$VENDORMODEL"
        resetprop -n ro.com.google.clientidbase "android-$(echo $VENDORBRAND | awk '{print tolower($0)}')" # probably will be enough but might not work on some rare cases.
    fi

    # Report your success.
    echo "Fix_GSI_Identity_Crisis: Operation finished"
    setprop ro.fix_gsi_identity_crisis.job_successful "1"
else
    echo "Fix_GSI_Identity_Crisis: Operation FAILED"
    setprop ro.fix_gsi_identity_crisis.job_successful "0"
fi
