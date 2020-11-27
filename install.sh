#!/bin/bash

echo "This script will install a library that will intercept pen events and smooth them."
echo
echo "If you haven't set up public key authentication on your remarkable yet, now would"
echo "be a good time to do so (otherwise you'll have to type your password multiple"
echo "times)."
echo
echo "Either way, make sure you have your remarkable password written down somewhere, you"
echo "might otherwise risk to lock yourself out if the GUI does not start up anymore."

echo
read -p "Enter the hostname or IP address of your remarkable device [remarkable]:" remarkable
remarkable=${remarkable:-remarkable}

read -p "Enter 1 to install the library, 0 to uninstall the library :" op_type

if [ "${op_type}" -eq "0" ]
then
  echo "Uninstalling ReCept..."
  ssh root@$remarkable "grep -qxF 'Environment=LD_PRELOAD=/usr/lib/librecept.so' /lib/systemd/system/xochitl.service && sed -i '/Environment=LD_PRELOAD=\/usr\/lib\/librecept.so/d' /lib/systemd/system/xochitl.service"
else
  read -p "Enter the type of filter to use : 0 : IIR Filter, 1 : Ring based FIR Filter :" filt_type

  if [ "${filt_type}" -eq "1" ]
  then
    echo
    echo "Chose the amount of smoothing you want to apply to pen events. Larger values will"
    echo "smooth more, but will also lead to larger perceived latencies."
    echo
    echo "Entering 0 will uninstall the library."
    echo
    read -p "Amount of smoothing (value between 2 and 32, or 0) [8]:" ring_size
    ring_size=${ring_size:-8}

    if [ "${ring_size}" -eq "0" ]
    then \
      echo "Uninstalling ReCept..."
      ssh root@$remarkable "grep -qxF 'Environment=LD_PRELOAD=/usr/lib/librecept.so' /lib/systemd/system/xochitl.service && sed -i '/Environment=LD_PRELOAD=\/usr\/lib\/librecept.so/d' /lib/systemd/system/xochitl.service"
    else \
      echo "Installing ReCept with ring size ${ring_size}..."
      scp ./precompiled/librecept_rs${ring_size}.so root@$remarkable:/usr/lib/librecept.so
      ssh root@$remarkable "grep -qxF 'Environment=LD_PRELOAD=/usr/lib/librecept.so' /lib/systemd/system/xochitl.service || sed -i 's#\[Service\]#[Service]\nEnvironment=LD_PRELOAD=/usr/lib/librecept.so#' /lib/systemd/system/xochitl.service"
    fi
  else
    echo "The amount of smoothing is determined by the filter coefficient, a lower coefficient will have more smoothing. The options below are scaled up by 100. So 25 means coefficient of 0.25 etc."
    read -p "Enter the IIR Filter coefficient from the list: 25, 50, 75 :" filt_coeff
    if [ "${filt_coeff}" -eq "75" ]
    then
      echo "Installing ReCept with IIR Filter coefficient 0.75 ..."
      scp ./precompiled/librecept_iir_75_16.so root@$remarkable:/usr/lib/librecept.so
      ssh root@$remarkable "grep -qxF 'Environment=LD_PRELOAD=/usr/lib/librecept.so' /lib/systemd/system/xochitl.service || sed -i 's#\[Service\]#[Service]\nEnvironment=LD_PRELOAD=/usr/lib/librecept.so#' /lib/systemd/system/xochitl.service"
    elif [ "${filt_coeff}" -eq "50" ]
    then
      echo "Installing ReCept with IIR Filter coefficient 0.50 ..."
      scp ./precompiled/librecept_iir_50_16.so root@$remarkable:/usr/lib/librecept.so
      ssh root@$remarkable "grep -qxF 'Environment=LD_PRELOAD=/usr/lib/librecept.so' /lib/systemd/system/xochitl.service || sed -i 's#\[Service\]#[Service]\nEnvironment=LD_PRELOAD=/usr/lib/librecept.so#' /lib/systemd/system/xochitl.service"
    elif [ "${filt_coeff}" -eq "25" ]
    then
      echo "Installing ReCept with IIR Filter coefficient 0.25 ..."
      scp ./precompiled/librecept_iir_25_16.so root@$remarkable:/usr/lib/librecept.so
      ssh root@$remarkable "grep -qxF 'Environment=LD_PRELOAD=/usr/lib/librecept.so' /lib/systemd/system/xochitl.service || sed -i 's#\[Service\]#[Service]\nEnvironment=LD_PRELOAD=/usr/lib/librecept.so#' /lib/systemd/system/xochitl.service"
    else
      echo "Only supported coefficients are : 25, 50, 75 please enter one of these exactly."
      exit
    fi
  fi
fi

echo "...done."
echo "Restarting xochitl..."
ssh root@$remarkable "systemctl daemon-reload; systemctl restart xochitl"
echo "...done."
