#!/bin/bash

virsh shutdown linux-srv-vm
virsh snapshot-revert --domain linux-srv-vm clean-srv-with-root
