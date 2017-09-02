#!/bin/sh
sudo unzip -o -d /opt/tectonic/ $HOME/tectonic.zip && \
rm $HOME/tectonic.zip && \
sudo systemctl enable bootkube && \
sudo systemctl start bootkube

if [[ $* == *--enable-tectonic* ]]; then
  sudo systemctl enable tectonic && \
  sudo systemctl start tectonic
fi
