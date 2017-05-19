[Unit]
Description=Turn on swap

[Service]
Type=oneshot
ExecStartPre=-/usr/bin/rm -rf /var/vm
ExecStartPre=/usr/bin/mkdir -p /var/vm
ExecStartPre=/usr/bin/touch /var/vm/swapfile1
ExecStartPre=/bin/bash -c "fallocate -l ${swap_size} /var/vm/swapfile1"
ExecStartPre=/usr/bin/chmod 600 /var/vm/swapfile1
ExecStartPre=/usr/sbin/mkswap /var/vm/swapfile1
ExecStartPre=/usr/sbin/sysctl vm.swappiness=10
ExecStart=/sbin/swapon /var/vm/swapfile1
ExecStop=/sbin/swapoff /var/vm/swapfile1
ExecStopPost=-/usr/bin/rm -rf /var/vm
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
